import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';           // ← TAMBAH
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ← TAMBAH
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'navigation_bar/main_navigation.dart';
import 'screens/home.dart';
import 'screens/analysis_screen.dart';
import 'screens/tray.dart';
import 'screens/profile.dart';
import 'auth/auth_service.dart';
import 'screens/forgot_token.dart';
import 'screens/forgot_new.dart';
import 'screens/for_newuser.dart';
import 'services/notification_service.dart';

// ← TAMBAH: harus top-level di main.dart, BUKAN di dalam class/service
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.showLocalNotification(
    title: message.notification?.title ?? 'Gas Alert',
    body:  message.notification?.body  ?? '',
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ← TAMBAH: daftarkan background handler SEBELUM runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // ← TAMBAH: buat notification channel SEBELUM runApp
  await FlutterLocalNotificationsPlugin()
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
    const AndroidNotificationChannel(
      'gas_alert_channel',
      'Gas Alerts',
      description: 'Notifikasi peringatan gas berbahaya',
      importance: Importance.max,
      playSound: true,
    ),
  );

  final url     = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || anonKey == null) {
    throw Exception('Missing Supabase configuration in environment variables.');
  }

  await Supabase.initialize(url: url, anonKey: anonKey);
  await NotificationService.initialize();
  await AuthService.initializeSession();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Material 3 — Blue seed, ikuti sistem
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.light,
    );
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1565C0),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'WITFood',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // ikuti sistem HP
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: colorSchemeDark,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1565C0),
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        MainNavigation.routeName:           (c) => const MainNavigation(),
        '/home':                            (c) => const HomeScreen(),
        '/analysis':                        (c) => const AnalysisScreen(),
        '/tray':                            (c) => const TrayPage(),
        '/profile':                         (c) => const ProfilePage(),
        LoginScreen.routeName:              (c) => const LoginScreen(),
        RegisterScreen.routeName:           (c) => const RegisterScreen(),
        ForgotPasswordScreen.routeName:     (c) => const ForgotPasswordScreen(),
        ForgotTokenScreen.routeName:        (c) => const ForgotTokenScreen(),
        ForgotNewPasswordScreen.routeName:  (c) => const ForgotNewPasswordScreen(),
        ForNewUserScreen.routeName:         (c) => const ForNewUserScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isLoggedIn = AuthService.isLoggedIn();
      _isLoading  = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    return _isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}