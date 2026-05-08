import 'package:flutter/material.dart';
import '../screens/home.dart';
import '../screens/analysis_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/tray.dart';
import '../screens/profile.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  static const String routeName = '/main';

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    AnalysisScreen(),
    ScanScreen(),
     TrayPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF111315),
        indicatorColor: colorScheme.primary.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.search_rounded, color: Colors.white),
            label: 'Analisis',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.archive_rounded, color: Colors.white),
            label: 'Tray',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
