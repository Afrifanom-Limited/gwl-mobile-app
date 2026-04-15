// ignore_for_file: prefer_const_constructors, avoid_print
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotification {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  static void initialize() async {
    final InitializationSettings initialSettings = InitializationSettings(
      android: AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ),
      iOS: DarwinInitializationSettings(requestSoundPermission: true, requestBadgePermission: true, requestAlertPermission: true, defaultPresentBadge: true, defaultPresentSound: true),
    );
    flutterLocalNotificationsPlugin.initialize(initialSettings, onDidReceiveNotificationResponse: (NotificationResponse details) {});

    if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
          );
    }
  }

  static void clearAll() {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  static void showBadger() async {
    // try {
    //   bool res = await FlutterAppBadger.isAppBadgeSupported();
    //   if (res) {
    //     FlutterAppBadger.updateBadgeCount(1);
    //   }
    // } catch (e) {}
  }

  static void removeBadger() async {
    // try {
    //   bool res = await FlutterAppBadger.isAppBadgeSupported();
    //   if (res) {
    //     FlutterAppBadger.removeBadge();
    //   }
    // } catch (e) {}
  }

  static void showNotification(RemoteMessage message) {
    final NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'app_notification',
        'app_notification',
        playSound: true,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentBadge: true,
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      ),
    );
    flutterLocalNotificationsPlugin.show(
      DateTime.now().microsecond,
      message.notification!.title,
      message.notification!.body,
      notificationDetails,
      payload: message.data.toString(),
    );
  }
}
