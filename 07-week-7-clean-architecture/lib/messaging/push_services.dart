import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/format.dart';
import '../routes.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Received background message: ${message.messageId}');
}

const _notificationChannel = AndroidNotificationChannel(
  'campus_notify_notifications',
  'Notifikasi Campus Notify',
  description: 'Notifikasi pengumuman kampus',
  importance: Importance.high,
);

class PushService {
  PushService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  void Function(String route)? _onRoute;

  Future<void> initialize({
    required void Function(String route) onRoute,
    required Future<void> Function(String token) registerToken,
  }) async {
    _onRoute = onRoute;

    // Android 13+ asks for notification permission at runtime; older Android
    // versions do not show this prompt. iOS displays its notification prompt.
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        _navigateToRoute(
          routeFromMessage(
            {'route': response.payload},
            homeRoute: AppRoutes.home,
            announcementSegment: AppRoutes.announcementSegment,
          ),
        );
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_notificationChannel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _navigateToRoute(
        routeFromMessage(
          message.data,
          homeRoute: AppRoutes.home,
          announcementSegment: AppRoutes.announcementSegment,
        ),
      ),
    );

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _navigateToRoute(
        routeFromMessage(
          initialMessage.data,
          homeRoute: AppRoutes.home,
          announcementSegment: AppRoutes.announcementSegment,
        ),
      );
    }

    final token = await _messaging.getToken();
    if (token != null) await registerToken(token);
    _messaging.onTokenRefresh.listen(registerToken);
    await subscribeToAnnouncements();
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannel.id,
          _notificationChannel.name,
          channelDescription: _notificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: routeFromMessage(
        message.data,
        homeRoute: AppRoutes.home,
        announcementSegment: AppRoutes.announcementSegment,
      ),
    );
  }

  void _navigateToRoute(String? route) {
    if (route != null) _onRoute?.call(route);
  }

  Future<void> subscribeToAnnouncements() =>
      _messaging.subscribeToTopic('pengumuman-kampus');

  Future<void> unsubscribeFromAnnouncements() =>
      _messaging.unsubscribeFromTopic('pengumuman-kampus');
}
