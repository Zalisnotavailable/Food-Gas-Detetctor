import 'package:flutter/material.dart';

/// Global notifier untuk trigger refresh di semua page sekaligus.
///
/// Cara pakai:
/// 1. Import file ini di page yang butuh refresh
/// 2. Di initState: refreshNotifier.addListener(_onGlobalRefresh);
/// 3. Di dispose:   refreshNotifier.removeListener(_onGlobalRefresh);
/// 4. Buat method:  void _onGlobalRefresh() => _loadData();

class RefreshNotifier extends ChangeNotifier {
  /// Panggil ini untuk trigger refresh di semua page yang subscribe
  void refreshAll() {
    notifyListeners();
  }
}

/// Instance global — bisa langsung dipakai di mana saja
final refreshNotifier = RefreshNotifier();