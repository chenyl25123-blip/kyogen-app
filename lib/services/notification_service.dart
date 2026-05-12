import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final _fcm   = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // 権限リクエスト・ローカル通知・バックグラウンドハンドラのみ初期化
  // トークン保存は認証後�?saveToken() を別途呼�?  Future<void> initialize() async {
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
    final token = await _fcm.getToken();
    if (token == null) return;
    await _updateToken(token);
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
Future<void> _backgroundHandler(RemoteMessage message) async {}
