import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class CheckInService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  // daysAgo: 0 = today, 1 = yesterday, 2 = two days ago
  String _dateKey([int daysAgo = 0]) {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final d   = jst.subtract(Duration(days: daysAgo));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> checkIn() async {
    final today = _dateKey();
    await _db
        .collection('users').doc(_uid)
        .collection('checkins').doc(today)
        .set(CheckIn(
          date:      today,
          checkedAt: DateTime.now(),
        ).toFirestore());
  }

  Future<CheckInStatus> getStatus() async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    if (userDoc.exists) {
      final paused = (userDoc.data()?['paused'] ?? false) as bool;
      if (paused) return CheckInStatus.paused;
    }

    final ref = _db.collection('users').doc(_uid).collection('checkins');

    if ((await ref.doc(_dateKey(0)).get()).exists) return CheckInStatus.safe;
    if ((await ref.doc(_dateKey(1)).get()).exists) return CheckInStatus.pending;
    if ((await ref.doc(_dateKey(2)).get()).exists) return CheckInStatus.warn;
    return CheckInStatus.alert;
  }

  // N 回個別 read �?コレクションクエ�?1 回に最適化
  Future<Map<String, bool>> getHistory(int days) async {
    final jst       = DateTime.now().toUtc().add(const Duration(hours: 9));
    final oldestKey = _dateKey(days - 1);
    final todayKey  = _dateKey(0);

    final snap = await _db
        .collection('users').doc(_uid)
        .collection('checkins')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: oldestKey)
        .where(FieldPath.documentId, isLessThanOrEqualTo: todayKey)
        .get();

    final checkedDates = snap.docs.map((d) => d.id).toSet();

    final result = <String, bool>{};
    for (int i = 0; i < days; i++) {
      final d   = jst.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      result[key] = checkedDates.contains(key);
    }
    return result;
  }

  Future<void> togglePause(bool paused) async {
    await _db.collection('users').doc(_uid).update({'paused': paused});
  }

  // リセット: 連絡先・チェックイン履歴・ユーザーフィールドを削�?  Future<void> resetAllData() async {
    final db  = _db;
    final uid = _uid;

    await db.collection('users').doc(uid)
        .collection('contact').doc('main').delete();

    await db.collection('users').doc(uid).update({
      'lastNotifiedAt': null,
      'emailSentCount': 0,
      'paused':         false,
    });

    final jst   = DateTime.now().toUtc().add(const Duration(hours: 9));
    final batch = db.batch();
    for (int i = 0; i < 30; i++) {
      final d   = jst.subtract(Duration(days: i));
      final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
      batch.delete(
        db.collection('users').doc(uid).collection('checkins').doc(key),
      );
    }
    await batch.commit();
  }
}
