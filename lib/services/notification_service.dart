import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kyogen/demo_mode.dart';
import 'package:kyogen/firebase_options.dart';

class NotificationService {
  late final _fcm   = FirebaseMessaging.instance;
  late final _local = FlutterLocalNotificationsPlugin();

  // 権限リクエスト・ローカル通知・バックグラウンドハンドラのみ初期化
  // トークン保存は認証後に saveToken() を別途呼ぶ
  Future<void> initialize() async {
    if (kDemoMode) return;
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _local.initialize(
      const InitializationSettings(iOS: iosInit),
    );

    _fcm.onTokenRefresh.listen(_updateToken);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
  }

  // 認証完了後に main.dart から呼ぶ
  Future<void> saveToken() async {
    if (kDemoMode) return;
    try {
      // iOS: APNs token may not be ready immediately after launch; retry a few times
      String? token;
      for (int i = 0; i < 5 && token == null; i++) {
        if (i > 0) await Future.delayed(const Duration(seconds: 2));
        try { token = await _fcm.getToken(); } catch (_) {}
      }
      if (token == null) return;
      await _updateToken(token);
    } catch (e) {
      debugPrint('saveToken error: $e');
    }
  }

  Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .update({'fcmToken': token});
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<void> _backgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
