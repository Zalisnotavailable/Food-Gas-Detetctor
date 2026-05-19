import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'login_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isRealtimeNotifEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: CustomScrollView(
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
                child: _ProfileCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _SettingsList(
                  isRealtimeNotifEnabled: isRealtimeNotifEnabled,
                  onRealtimeChanged: (v) =>
                      setState(() => isRealtimeNotifEnabled = v),
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
    );
  }
}

// ─── Fixed Header Delegate ────────────────────────────────────────────────────
class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

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
          Text(
            'Pengaturan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: 28,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Akun & Konfigurasi',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
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
          // Avatar
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: userPhoto != null ? Colors.transparent : const Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: userPhoto != null
                ? ClipOval(
              child: Image.network(
                userPhoto,
                width: 92,
                height: 92,
                fit: BoxFit.cover,
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatTile(value: '247',   label: 'Total Scan')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(value: '98.5%', label: 'Akurasi')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(value: '12',    label: 'Hari Aktif')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF10B981),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0284C7))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

// ─── Settings List (hanya Notifikasi Real-time) ───────────────────────────────
class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.isRealtimeNotifEnabled,
    required this.onRealtimeChanged,
  });
  final bool isRealtimeNotifEnabled;
  final ValueChanged<bool> onRealtimeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: _SettingRow(
        title: 'Notifikasi Real-time',
        value: isRealtimeNotifEnabled,
        onChanged: onRealtimeChanged,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF06B6D4),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ],
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
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(label: 'Firmware ESP32', value: 'v3.2.1'),
          const Divider(height: 1),
          _InfoRow(label: 'Device ID', value: 'FG-ESP32-009'),
          const Divider(height: 1),
          _InfoRow(label: 'Logout', value: '', isDestructive: true),
        ],
      ),
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
        if (isDestructive && label.toLowerCase() == 'logout') {
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
                context,
                LoginScreen.routeName,
                    (route) => false,
              );
            },
          ).show();
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    color: isDestructive ? const Color(0xFFDC2626) : Colors.black87,
                    fontWeight: isDestructive ? FontWeight.w700 : FontWeight.w600,
                  )),
            ),
            if (!isDestructive)
              Text(value ?? '', style: const TextStyle(color: Colors.black45)),
          ],
        ),
      ),
    );
  }
}