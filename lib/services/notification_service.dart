import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Background message handler (harus top-level function) ───────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Gas Alert',
    body:  message.notification?.body  ?? '',
  );
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotif =
  FlutterLocalNotificationsPlugin();

  static const String _prefKey = 'notif_realtime_enabled';

  // ─── Init (panggil di main.dart sebelum runApp) ───────────────────────────
  static Future<void> initialize() async {
    // Setup local notifications
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request permission
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Subscribe ke topic FCM
    await messaging.subscribeToTopic('gas_alerts');

    // Handler saat app di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final enabled = await isEnabled();
      if (!enabled) return; // toggle OFF → tidak tampilkan

      await showLocalNotification(
        title: message.notification?.title ?? 'Gas Alert',
        body:  message.notification?.body  ?? '',
      );
    });

    // ← TAMBAH: debug token
    final token = await messaging.getToken();
    print('📱 FCM Token: $token');

    print('✅ NotificationService initialized');
  }

  // ─── Tampilkan notifikasi lokal ───────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    final enabled = await isEnabled();
    if (!enabled) return;

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gas_alert_channel',
          'Gas Alerts',
          channelDescription: 'Notifikasi peringatan gas berbahaya',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── Toggle ON/OFF ────────────────────────────────────────────────────────
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);

    final messaging = FirebaseMessaging.instance;
    if (enabled) {
      await messaging.subscribeToTopic('gas_alerts');
      print('🔔 Notifikasi diaktifkan');
    } else {
      await messaging.unsubscribeFromTopic('gas_alerts');
      print('🔕 Notifikasi dimatikan');
    }
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? true; // default ON
  }
}