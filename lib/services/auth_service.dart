import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> _initUserDocument(String uid, {bool googleLinked = false}) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid':            uid,
        'createdAt':      FieldValue.serverTimestamp(),
        'fcmToken':       null,
        'paused':         false,
        'googleLinked':   googleLinked,
        'lastNotifiedAt': null,
        'emailSentCount': 0,
      });
    } else if (googleLinked) {
      await ref.update({'googleLinked': true});
    }
  }
}
