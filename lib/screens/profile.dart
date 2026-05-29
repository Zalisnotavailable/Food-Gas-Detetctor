import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notifEnabled = true;
  int _totalScan = 0;
  int _hariAktif = 0;
  String _statusAman = '...';
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadNotif();
    _loadStats();
  }

  Future<void> _loadNotif() async {
    final v = await NotificationService.isEnabled();
    setState(() => _notifEnabled = v);
  }

  Future<void> _onNotifToggle(bool v) async {
    await NotificationService.setEnabled(v);
    setState(() => _notifEnabled = v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(v ? '🔔 Notifikasi diaktifkan' : '🔕 Notifikasi dimatikan'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final sb = Supabase.instance.client;
      final totalRes = await sb.from('sensor_readings').select('id').count(CountOption.exact);
      final total = totalRes.count ?? 0;

      final hariRes = await sb.from('sensor_readings').select('timestamp').order('timestamp', ascending: false).limit(1000);
      final hariSet = <String>{};
      for (final row in hariRes as List) {
        final dt = DateTime.tryParse(row['timestamp'].toString());
        if (dt != null) hariSet.add('${dt.year}-${dt.month}-${dt.day}');
      }

      final gasRes = await sb.from('sensor_readings').select('nh3,h2s,ch4,co2,voc,c2h5oh,co,h2').order('timestamp', ascending: false).limit(100);
      int aman = 0;
      for (final row in gasRes as List) { if (!_cekDanger(row)) aman++; }
      final persen = gasRes.isEmpty ? 0 : ((aman / gasRes.length) * 100).round();

      if (mounted) setState(() { _totalScan = total; _hariAktif = hariSet.length; _statusAman = '$persen%'; _loadingStats = false; });
    } catch (_) { if (mounted) setState(() => _loadingStats = false); }
  }

  bool _cekDanger(Map<String, dynamic> row) {
    const t = {'nh3': 10.0, 'h2s': 5.0, 'ch4': 50.0, 'co2': 1000.0, 'voc': 0.5, 'c2h5oh': 20.0, 'co': 9.0, 'h2': 20.0};
    for (final e in t.entries) {
      final v = (row[e.key] as num?)?.toDouble();
      if (v != null && v >= e.value) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user   = AuthService.getCurrentUser();
    final photo  = AuthService.getCurrentUserPhoto();
    final name   = user?['nama'] ?? 'User';
    final email  = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: cs.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: cs.primaryContainer,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pengaturan', style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800, fontSize: 20)),
                  Text('Akun & Konfigurasi', style: TextStyle(color: cs.onPrimaryContainer.withOpacity(0.7), fontSize: 11)),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [

                  // ─── Profile Card ──────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        // Avatar
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: cs.primaryContainer,
                          backgroundImage: photo != null ? NetworkImage(photo) : null,
                          child: photo == null
                              ? Text(name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: cs.onPrimaryContainer))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 16),

                        // Stats
                        _loadingStats
                            ? const CircularProgressIndicator()
                            : Row(children: [
                          _StatCard(value: _totalScan.toString(), label: 'Total Scan', cs: cs),
                          const SizedBox(width: 10),
                          _StatCard(value: _statusAman, label: 'Status Aman', cs: cs),
                          const SizedBox(width: 10),
                          _StatCard(value: _hariAktif.toString(), label: 'Hari Aktif', cs: cs),
                        ]),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Notifikasi ────────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text('Notifikasi Real-time', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                      subtitle: Text('Peringatan gas Warning & Bahaya', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      secondary: Icon(Icons.notifications_outlined, color: cs.primary),
                      value: _notifEnabled,
                      onChanged: _onNotifToggle,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Device Info ───────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      ListTile(
                        leading: Icon(Icons.memory_rounded, color: cs.primary),
                        title: Text('Firmware ESP32', style: TextStyle(color: cs.onSurface)),
                        trailing: Text('v3.2.1', style: TextStyle(color: cs.onSurfaceVariant)),
                      ),
                      Divider(height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading: Icon(Icons.devices_rounded, color: cs.primary),
                        title: Text('Device ID', style: TextStyle(color: cs.onSurface)),
                        trailing: Text('FG-ESP32-009', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ),
                      Divider(height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading: Icon(Icons.logout_rounded, color: cs.error),
                        title: Text('Logout', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600)),
                        onTap: () => AwesomeDialog(
                          context: context,
                          dialogType: DialogType.question,
                          animType: AnimType.scale,
                          title: 'Konfirmasi',
                          desc: 'Anda yakin ingin keluar?',
                          btnCancelText: 'Batal',
                          btnOkText: 'Keluar',
                          btnCancelOnPress: () {},
                          btnOkOnPress: () async {
                            await AuthService.logout();
                            if (!context.mounted) return;
                            Navigator.pushNamedAndRemoveUntil(context, LoginScreen.routeName, (_) => false);
                          },
                        ).show(),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, required this.cs});
  final String value, label;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.primary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}