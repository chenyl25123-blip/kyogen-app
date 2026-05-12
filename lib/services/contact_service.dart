import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kyogen/demo_mode.dart';
import 'package:kyogen/models.dart';

class ContactService {
  late final _db   = FirebaseFirestore.instance;
  late final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  static Contact? _demoContact;

  DocumentReference get _contactRef =>
      _db.collection('users').doc(_uid).collection('contact').doc('main');

  // ── 連絡先の取得 ──────────────────────────────────────
  Future<Contact?> getContact() async {
    if (kDemoMode) return _demoContact;
    final doc = await _contactRef.get();
    if (!doc.exists) return null;
    return Contact.fromFirestore(doc);
  }

  // ── 連絡先の保存（確認メールは Cloud Function が自動送信）
  Future<void> saveContact(Contact contact) async {
    if (kDemoMode) { _demoContact = contact; return; }
    await _contactRef.set(contact.toFirestore());
    // Firestore の onContactSaved トリガーが自動で
    // 確認メールを Resend 経由で送信する
  }

  // ── 連絡先の削除 ──────────────────────────────────────
  Future<void> deleteContact() async {
    if (kDemoMode) { _demoContact = null; return; }
    await _contactRef.delete();
  }

  // ── リアルタイム Stream ───────────────────────────────
  Stream<Contact?> contactStream() {
    if (kDemoMode) return Stream.value(_demoContact);
    return _contactRef.snapshots().map((doc) {
      if (!doc.exists) return null;
      return Contact.fromFirestore(doc);
    });
  }
}
