import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class ContactService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  DocumentReference get _contactRef =>
      _db.collection('users').doc(_uid).collection('contact').doc('main');

  // ── 連絡先の取得 ──────────────────────────────────────
  Future<Contact?> getContact() async {
    final doc = await _contactRef.get();
    if (!doc.exists) return null;
    return Contact.fromFirestore(doc);
  }

  // ── 連絡先の保存（確認メール�?Cloud Function が自動送信�?  Future<void> saveContact(Contact contact) async {
    await _contactRef.set(contact.toFirestore());
    // Firestore �?onContactSaved トリガーが自動で
    // 確認メールを Resend 経由で送信する
  }

  // ── 連絡先の削除 ──────────────────────────────────────
  Future<void> deleteContact() async {
    await _contactRef.delete();
  }

  // ── リアルタイム Stream ───────────────────────────────
  Stream<Contact?> contactStream() {
    return _contactRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return Contact.fromFirestore(doc);
    });
  }
}
