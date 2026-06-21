import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background message handler — must be top-level.
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage msg) async {}

class FcmService {
  FcmService._();
  static final _fcm   = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'sarian_high',
    'Sarian Alerts',
    description: 'Order & product notifications',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    // Request permission
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Android notification channel
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Init local notifications
    const init = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(init);

    // Foreground display
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // Listen foreground messages
    FirebaseMessaging.onMessage.listen(_showLocal);

    // Save token
    await saveToken();

    // Token refresh
    _fcm.onTokenRefresh.listen((_) => saveToken());
  }

  static Future<void> saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _fcm.getToken();
    if (token == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': token});
  }

  static void _showLocal(RemoteMessage msg) {
    final n = msg.notification;
    if (n == null) return;
    _local.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(msg.data),
    );
  }

  /// Send a push notification to a specific FCM token using Firestore queue.
  /// A Cloud Function watches `notifications` collection and dispatches via FCM.
  /// Here we write a notification document so Cloud Functions can pick it up.
  static Future<void> queueNotification({
    required String toToken,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (toToken.isEmpty) return;
    await FirebaseFirestore.instance.collection('notifications').add({
      'to':        toToken,
      'title':     title,
      'body':      body,
      'data':      data,
      'sentAt':    FieldValue.serverTimestamp(),
      'processed': false,
    });
  }

  /// Notify all admins (reads admin FCM tokens from Firestore).
  static Future<void> notifyAdmins({
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (kIsWeb) return;
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    for (final doc in snap.docs) {
      final token = doc.data()['fcmToken'] as String? ?? '';
      if (token.isNotEmpty) {
        await queueNotification(toToken: token, title: title, body: body, data: data);
      }
    }
  }

  /// Notify a single user by UID.
  static Future<void> notifyUser({
    required String uid,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    if (kIsWeb) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final token = doc.data()?['fcmToken'] as String? ?? '';
    if (token.isNotEmpty) {
      await queueNotification(toToken: token, title: title, body: body, data: data);
    }
  }
}
