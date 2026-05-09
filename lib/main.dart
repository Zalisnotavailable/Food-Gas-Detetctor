import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'navigation_bar/main_navigation.dart';
import 'screens/home.dart';
import 'screens/analysis_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/tray.dart';
import 'screens/profile.dart';
import 'auth/auth_service.dart';
import 'screens/forgot_token.dart';
import 'screens/forgot_new.dart';
import 'screens/for_newuser.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || anonKey == null) {
    throw Exception('Missing Supabase configuration in environment variables.');
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  // Initialize custom authentication session
  await AuthService.initializeSession();

  print('Berhasil terhubung dengan database');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodGuardPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF24c6dc), brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF24c6dc), brightness: Brightness.dark),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
      routes: {
        MainNavigation.routeName: (context) => const MainNavigation(),
        '/home': (context) => const HomeScreen(),
        '/analysis': (context) => const AnalysisScreen(),
        '/scan': (context) => const ScanScreen(),
        '/tray': (context) => const TrayPage(),
        '/profile': (context) => const ProfilePage(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
        ForgotTokenScreen.routeName: (context) => const ForgotTokenScreen(),
        ForgotNewPasswordScreen.routeName: (context) => const ForgotNewPasswordScreen(),
        ForNewUserScreen.routeName: (context) => const ForNewUserScreen(),
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
    // Wait a bit to ensure AuthService.initializeSession() is complete
    await Future.delayed(const Duration(milliseconds: 100));
    
    setState(() {
      _isLoggedIn = AuthService.isLoggedIn();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return _isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}