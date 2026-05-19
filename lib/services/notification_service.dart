import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _notifications.initialize(settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showSensorNotification({
    required String status,
    required List<String> dangerSensors,
    required List<String> warningSensors,
  }) async {
    String title;
    String body;
    Color notifColor;

    if (dangerSensors.isNotEmpty) {
      title = '⚠️ BAHAYA! Gas Melewati Batas';
      body = '${dangerSensors.join(', ')} dalam level berbahaya!';
      notifColor = const Color(0xFFDC2626);
    } else if (warningSensors.isNotEmpty) {
      title = '⚡ Peringatan Sensor';
      body = '${warningSensors.join(', ')} mendekati batas aman';
      notifColor = const Color(0xFFF59E0B);
    } else {
      title = '✅ Semua Gas Aman';
      body = 'Data sensor terbaru: semua dalam batas normal';
      notifColor = const Color(0xFF00A39B);
    }

    final androidDetails = AndroidNotificationDetails(
      'sensor_channel',
      'Sensor Updates',
      channelDescription: 'Notifikasi update data sensor gas',
      importance: Importance.high,
      priority: Priority.high,
      color: notifColor,
    );

    await _notifications.show(
      0,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}