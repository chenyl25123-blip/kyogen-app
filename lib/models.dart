import 'package:cloud_firestore/cloud_firestore.dart';

// ── CheckIn Model ──────────────────────────────────────────────────────────
class CheckIn {
  final String date;       // "2025-11-15"  (= document ID)
  final DateTime checkedAt;
  final String timezone;

  const CheckIn({
    required this.date,
    required this.checkedAt,
    this.timezone = 'Asia/Tokyo',
  });

  factory CheckIn.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CheckIn(
      date:      doc.id,
      checkedAt: (d['checkedAt'] as Timestamp).toDate(),
      timezone:  d['timezone'] ?? 'Asia/Tokyo',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'date':      date,
    'checkedAt': Timestamp.fromDate(checkedAt),
    'timezone':  timezone,
  };
}

// ── Contact Model ──────────────────────────────────────────────────────────
class Contact {
  final String name;
  final String email;
  final String? relationship;
  final DateTime? confirmedAt;
  final DateTime updatedAt;

  const Contact({
    required this.name,
    required this.email,
    this.relationship,
    this.confirmedAt,
    required this.updatedAt,
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Contact(
      name:         d['name'] ?? '',
      email:        d['email'] ?? '',
      relationship: d['relationship'],
      confirmedAt:  d['confirmedAt'] != null
                    ? (d['confirmedAt'] as Timestamp).toDate() : null,
      updatedAt:    (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':         name,
    'email':        email,
    'relationship': relationship,
    'confirmedAt':  confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    'updatedAt':    Timestamp.fromDate(updatedAt),
  };

  bool get isSet => name.isNotEmpty && email.isNotEmpty;
}

// ── AppUser Model ───────────────────────────────────────────────────────────
class AppUser {
  final String uid;
  final DateTime createdAt;
  final String? fcmToken;
  final bool paused;
  final bool googleLinked;
  final DateTime? lastNotifiedAt;
  final int emailSentCount;

  const AppUser({
    required this.uid,
    required this.createdAt,
    this.fcmToken,
    this.paused = false,
    this.googleLinked = false,
    this.lastNotifiedAt,
    this.emailSentCount = 0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid:            doc.id,
      createdAt:      (d['createdAt'] as Timestamp).toDate(),
      fcmToken:       d['fcmToken'],
      paused:         d['paused'] ?? false,
      googleLinked:   d['googleLinked'] ?? false,
      lastNotifiedAt: d['lastNotifiedAt'] != null
                      ? (d['lastNotifiedAt'] as Timestamp).toDate() : null,
      emailSentCount: d['emailSentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid':            uid,
    'createdAt':      Timestamp.fromDate(createdAt),
    'fcmToken':       fcmToken,
    'paused':         paused,
    'googleLinked':   googleLinked,
    'lastNotifiedAt': lastNotifiedAt != null
                      ? Timestamp.fromDate(lastNotifiedAt!) : null,
    'emailSentCount': emailSentCount,
  };

  AppUser copyWith({
    String? fcmToken,
    bool? paused,
    bool? googleLinked,
  }) {
    return AppUser(
      uid:            uid,
      createdAt:      createdAt,
      fcmToken:       fcmToken ?? this.fcmToken,
      paused:         paused ?? this.paused,
      googleLinked:   googleLinked ?? this.googleLinked,
      lastNotifiedAt: lastNotifiedAt,
      emailSentCount: emailSentCount,
    );
  }
}

// ── CheckIn Status ─────────────────────────────────────────────────────────
enum CheckInStatus {
  safe,     // 今日 確認済み
  pending,  // 今日未確認・昨日OK
  warn,     // 昨日未確認・一昨日OK → プッシュ通知タイミング
  alert,    // 3日以上未確認       → メール送信タイミング
  paused,   // 機能停止中
}

extension CheckInStatusX on CheckInStatus {
  String get label {
    switch (this) {
      case CheckInStatus.safe:    return '今日も元気 ✓';
      case CheckInStatus.pending: return '本日 未確認';
      case CheckInStatus.warn:    return '昨日 未確認 ⚠';
      case CheckInStatus.alert:   return '連絡先へメール送信';
      case CheckInStatus.paused:  return '機能停止中';
    }
  }

  String get subtitle {
    switch (this) {
      case CheckInStatus.safe:    return 'また明日も確認してください';
      case CheckInStatus.pending: return '今日中にタップしてください';
      case CheckInStatus.warn:    return '今日中に確認しないと連絡先へメールが届きます';
      case CheckInStatus.alert:   return '3日間確認がありませんでした';
      case CheckInStatus.paused:  return '通知・メール送信が停止されています';
    }
  }
}
