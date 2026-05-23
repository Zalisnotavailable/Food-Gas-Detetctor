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
  // State Notifikasi
  bool _isRealtimeNotifEnabled = true;

  // State Statistik Database
  int _totalScan = 0;
  int _hariAktif = 0;
  String _statusAman = '...';
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadNotifState();
    _loadStats(); // Panggil saat pertama kali dibuka
  }

  Future<void> _loadNotifState() async {
    final enabled = await NotificationService.isEnabled();
    setState(() => _isRealtimeNotifEnabled = enabled);
  }

  Future<void> _onNotifToggle(bool value) async {
    await NotificationService.setEnabled(value);
    setState(() => _isRealtimeNotifEnabled = value);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? '🔔 Notifikasi diaktifkan' : '🔕 Notifikasi dimatikan'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Pindahkan fungsi ambil data ke sini agar bisa di-refresh
  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true); // Set loading saat mulai refresh

    try {
      final supabase = Supabase.instance.client;

      // 1. Total Scan
      final totalRes = await supabase
          .from('sensor_readings')
          .select('id')
          .count(CountOption.exact);
      final total = totalRes.count ?? 0;

      // 2. Hari Aktif
      final hariRes = await supabase
          .from('sensor_readings')
          .select('timestamp')
          .order('timestamp', ascending: false)
          .limit(1000);

      final hariSet = <String>{};
      for (final row in hariRes as List) {
        final dt = DateTime.tryParse(row['timestamp'].toString());
        if (dt != null) {
          hariSet.add('${dt.year}-${dt.month}-${dt.day}');
        }
      }

      // 3. Status Aman %
      final gasRes = await supabase
          .from('sensor_readings')
          .select('nh3, h2s, ch4, co2, voc, c2h5oh, co, h2')
          .order('timestamp', ascending: false)
          .limit(100);

      int amanCount = 0;
      for (final row in gasRes as List) {
        final isDanger = _cekDanger(row);
        if (!isDanger) amanCount++;
      }

      final persen = gasRes.isEmpty ? 0 : ((amanCount / gasRes.length) * 100).round();

      if (mounted) {
        setState(() {
          _totalScan = total;
          _hariAktif = hariSet.length;
          _statusAman = '$persen%';
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  bool _cekDanger(Map<String, dynamic> row) {
    final thresholds = {
      'nh3': 10.0, 'h2s': 5.0, 'ch4': 50.0, 'co2': 1000.0,
      'voc': 0.5, 'c2h5oh': 20.0, 'co': 9.0, 'h2': 20.0,
    };
    for (final entry in thresholds.entries) {
      final val = (row[entry.key] as num?)?.toDouble();
      if (val != null && val >= entry.value) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        // Tambahkan RefreshIndicator agar bisa ditarik ke bawah untuk memuat ulang
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(0xFF06B6D4),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(), // Wajib agar selalu bisa di-pull
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _FixedHeaderDelegate(
                  height: 115,
                  child: const _SettingsHeader(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ProfileCard(
                    // Lempar data yang sudah diambil ke komponen kartu
                    totalScan: _totalScan,
                    hariAktif: _hariAktif,
                    statusAman: _statusAman,
                    isLoading: _isLoadingStats,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SettingsList(
                    isRealtimeNotifEnabled: _isRealtimeNotifEnabled,
                    onRealtimeChanged: _onNotifToggle,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: const _DeviceInfoList(),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 92)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fixed Header Delegate ────────────────────────────────────────────────────
class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;
  @override double get minExtent => height;
  @override double get maxExtent => height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox.expand(child: child);
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00B4DB), Color(0xFF00A39B)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(25, 30, 25, 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Pengaturan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white, fontSize: 28,
                  height: 1.1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('Akun & Konfigurasi',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final int totalScan;
  final int hariAktif;
  final String statusAman;
  final bool isLoading;

  const _ProfileCard({
    required this.totalScan,
    required this.hariAktif,
    required this.statusAman,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.getCurrentUser();
    final userPhoto   = AuthService.getCurrentUserPhoto();
    final userName    = currentUser?['nama'] ?? 'User';
    final userEmail   = currentUser?['email'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
          // ─── Avatar ───────────────────────────────────────────────────────
          Container(
            width: 92, height: 92,
            decoration: BoxDecoration(
              color: userPhoto != null ? Colors.transparent : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: userPhoto != null
                ? ClipOval(
              child: Image.network(
                userPhoto, width: 92, height: 92, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(userName),
              ),
            )
                : _avatarFallback(userName),
          ),
          const SizedBox(height: 12),
          Text(userName,
              style: const TextStyle(
                  color: Colors.black, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(userEmail,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          const SizedBox(height: 16),

          // ─── Stats ────────────────────────────────────────────────────────
          isLoading
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(color: Color(0xFF0284C7), strokeWidth: 3),
          )
              : Row(children: [
            Expanded(
              child: _StatTile(
                value: totalScan.toString(),
                label: 'Total Scan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: statusAman,
                label: 'Status Aman',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                value: hariAktif.toString(),
                label: 'Hari Aktif',
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}

// ─── Settings List ────────────────────────────────────────────────────────────
class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.isRealtimeNotifEnabled, required this.onRealtimeChanged});
  final bool isRealtimeNotifEnabled;
  final ValueChanged<bool> onRealtimeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifikasi Real-time',
                    style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('Peringatan gas Warning & Bahaya',
                    style: TextStyle(color: Colors.black45, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: isRealtimeNotifEnabled,
            onChanged: onRealtimeChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF06B6D4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ]),
      ),
    );
  }
}

// ─── Device Info + Logout ─────────────────────────────────────────────────────
class _DeviceInfoList extends StatelessWidget {
  const _DeviceInfoList();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(children: [
        _InfoRow(label: 'Firmware ESP32', value: 'v3.2.1'),
        const Divider(height: 1),
        _InfoRow(label: 'Device ID', value: 'FG-ESP32-009'),
        const Divider(height: 1),
        _InfoRow(label: 'Logout', isDestructive: true),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.isDestructive = false});
  final String label;
  final String? value;
  final bool isDestructive;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        if (isDestructive) {
          AwesomeDialog(
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
              Navigator.pushNamedAndRemoveUntil(
                  context, LoginScreen.routeName, (route) => false);
            },
          ).show();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: isDestructive ? const Color(0xFFDC2626) : Colors.black87,
                    fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600)),
          ),
          if (!isDestructive && value != null)
            Text(value!, style: const TextStyle(color: Colors.black45)),
        ]),
      ),
    );
  }
}