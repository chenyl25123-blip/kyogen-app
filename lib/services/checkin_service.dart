import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kyogen/demo_mode.dart';
import 'package:kyogen/models.dart';

class CheckInService {
  late final _db   = FirebaseFirestore.instance;
  late final _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser!.uid;

  static final _demoCheckins = <String, bool>{};
  static bool _demoPaused = false;

  // daysAgo: 0 = today, 1 = yesterday, 2 = two days ago
  String _dateKey([int daysAgo = 0]) {
    final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
    final d   = jst.subtract(Duration(days: daysAgo));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> checkIn() async {
    if (kDemoMode) { _demoCheckins[_dateKey(0)] = true; return; }
    final today = _dateKey();
    await Future.wait([
      _db.collection('users').doc(_uid)
          .collection('checkins').doc(today)
          .set(CheckIn(date: today, checkedAt: DateTime.now()).toFirestore()),
      _db.collection('users').doc(_uid)
          .update({'lastNotifiedAt': null}),
    ]);
  }

  Future<CheckInStatus> getStatus() async {
    if (kDemoMode) {
      if (_demoPaused) return CheckInStatus.paused;
      if (_demoCheckins[_dateKey(0)] == true) return CheckInStatus.safe;
      if (_demoCheckins[_dateKey(1)] == true) return CheckInStatus.pending;
      if (_demoCheckins[_dateKey(2)] == true) return CheckInStatus.warn;
      return CheckInStatus.alert;
    }
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

  Future<Map<String, bool>> getHistory(int days) async {
    if (kDemoMode) {
      final jst = DateTime.now().toUtc().add(const Duration(hours: 9));
      final result = <String, bool>{};
      for (int i = 0; i < days; i++) {
        final d   = jst.subtract(Duration(days: i));
        final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        result[key] = _demoCheckins[key] ?? (i == 1 || i == 3);
      }
      return result;
    }
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
    if (kDemoMode) { _demoPaused = paused; return; }
    await _db.collection('users').doc(_uid).update({'paused': paused});
  }

  // リセット: 連絡先・チェックイン履歴・ユーザーフィールドを削除
  Future<void> resetAllData() async {
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
