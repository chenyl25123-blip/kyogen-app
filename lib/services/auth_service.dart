import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kyogen/utils/phone_number.dart';

class AuthFlowException implements Exception {
  final String code;
  final String message;
  final Object? cause;

  const AuthFlowException(this.code, this.message, {this.cause});

  @override
  String toString() => 'AuthFlowException($code): $message';
}

class PhoneVerificationSession {
  final String verificationId;
  final int? resendToken;

  const PhoneVerificationSession({
    required this.verificationId,
    this.resendToken,
  });
}

class AuthService {
  final _auth        = FirebaseAuth.instance;
  late final _googleSignIn = GoogleSignIn();
  final _db          = FirebaseFirestore.instance;

  // ── 現在のユーザー Stream ─────────────────────────────
  Stream<User?> get userStream => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── 匿名ログイン（初回起動時） ────────────────────────
  Future<UserCredential> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    await _initUserDocument(cred.user!.uid);
    return cred;
  }

  // ── Google ログイン ───────────────────────────────────
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // ユーザーがキャンセル

      final auth    = await account.authentication;
      final cred    = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken:     auth.idToken,
      );
      final result  = await _auth.signInWithCredential(cred);
      await _initUserDocument(result.user!.uid, googleLinked: true);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  // ── 匿名 → Google アカウント昇格 ──────────────────────
  // 匿名ユーザーがあとから Google と連携する場合
  Future<UserCredential?> linkGoogleAccount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || !currentUser.isAnonymous) return null;

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth   = await account.authentication;
      final cred   = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken:     auth.idToken,
      );

      try {
        final result = await currentUser.linkWithCredential(cred);
        await _db.collection('users').doc(currentUser.uid).update({
          'googleLinked': true,
          'displayName':  result.user?.displayName ?? '',
        });
        return result;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // このGoogle账号は既に別のFirebaseユーザーに紐付け済み → 直接ログイン
          final result = await _auth.signInWithCredential(cred);
          await _initUserDocument(result.user!.uid, googleLinked: true);
          return result;
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  // ── 電話番号ログイン: SMS 送信 ────────────────────────
  Future<PhoneVerificationSession> sendPhoneVerificationCode(
    String phoneNumber, {
    int? forceResendingToken,
  }) async {
    final e164PhoneNumber = _toE164OrThrow(phoneNumber);
    final completer = Completer<PhoneVerificationSession>();

    await _auth.verifyPhoneNumber(
      phoneNumber: e164PhoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {
        // iOS では通常 codeSent を使う。自動検証はここでは連携しない。
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(
            AuthFlowException(
              'firebase/${e.code}',
              'Failed to send phone verification code.',
              cause: e,
            ),
          );
        }
      },
      codeSent: (verificationId, resendToken) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          );
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(
            PhoneVerificationSession(verificationId: verificationId),
          );
        }
      },
    );

    return completer.future;
  }

  // ── 匿名 → 電話番号アカウント昇格 ────────────────────
  Future<UserCredential> linkPhoneAccount({
    required String verificationId,
    required String smsCode,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw const AuthFlowException(
        'auth/no-current-user',
        'Cannot link phone account because no Firebase user is signed in.',
      );
    }

    final normalizedCode = smsCode.trim();
    if (normalizedCode.isEmpty) {
      throw const AuthFlowException(
        'phone/empty-sms-code',
        'SMS verification code is empty.',
      );
    }

    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: normalizedCode,
    );

    try {
      final result = await currentUser.linkWithCredential(cred);
      await _db.collection('users').doc(currentUser.uid).update({
        'phoneLinked': true,
      });
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        final result = await _auth.signInWithCredential(cred);
        await _initUserDocument(result.user!.uid, phoneLinked: true);
        return result;
      }
      throw AuthFlowException(
        'firebase/${e.code}',
        'Failed to link phone credential.',
        cause: e,
      );
    }
  }

  // ── サインアウト ──────────────────────────────────────
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── アカウント完全削除 ────────────────────────────────
  // Firestore データをすべて消してから Auth ユーザーを削除する。
  // Google ユーザーで requires-recent-login が出た場合は再認証して再試行。
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    // 1. Firestore: checkins サブコレクションを一括削除
    final checkinsSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('checkins')
        .get();
    final batch = _db.batch();
    for (final doc in checkinsSnap.docs) {
      batch.delete(doc.reference);
    }
    // 2. contact/main と users/{uid} を削除
    batch.delete(
        _db.collection('users').doc(uid).collection('contact').doc('main'));
    batch.delete(_db.collection('users').doc(uid));
    await batch.commit();

    // 3. Firebase Auth アカウントを削除（要: 最近の認証）
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // Google ユーザーのみ: サイレント再認証してリトライ
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          final auth = await account.authentication;
          final cred = GoogleAuthProvider.credential(
            accessToken: auth.accessToken,
            idToken: auth.idToken,
          );
          await user.reauthenticateWithCredential(cred);
          await user.delete();
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    await _googleSignIn.signOut();
  }

  // ── ユーザードキュメント初期化 ────────────────────────
  Future<void> _initUserDocument(
    String uid, {
    bool googleLinked = false,
    bool phoneLinked = false,
  }) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid':            uid,
        'createdAt':      FieldValue.serverTimestamp(),
        'fcmToken':       null,
        'paused':         false,
        'googleLinked':   googleLinked,
        'phoneLinked':    phoneLinked,
        'lastNotifiedAt': null,
        'emailSentCount': 0,
      });
    } else if (googleLinked || phoneLinked) {
      await ref.update({
        if (googleLinked) 'googleLinked': true,
        if (phoneLinked) 'phoneLinked': true,
      });
    }
  }

  String _toE164OrThrow(String phoneNumber) {
    try {
      return toE164JapanPhoneNumber(phoneNumber);
    } on PhoneNumberFormatException catch (e) {
      throw AuthFlowException(
        e.code,
        'Invalid Japan mobile phone number.',
        cause: e,
      );
    }
  }
}
