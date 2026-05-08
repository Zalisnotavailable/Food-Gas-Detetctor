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
  bool isAutoDetectionEnabled = true;
  bool isCloudSyncEnabled = true;
  final TextEditingController thresholdNh3Controller =
      TextEditingController(text: '27');
  final TextEditingController thresholdH2sController =
      TextEditingController(text: '5');
  final TextEditingController thresholdVocController =
      TextEditingController(text: '0,5');

  @override
  void dispose() {
    thresholdNh3Controller.dispose();
    thresholdH2sController.dispose();
    thresholdVocController.dispose();
    super.dispose();
  }

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
                  isAutoDetectionEnabled: isAutoDetectionEnabled,
                  isCloudSyncEnabled: isCloudSyncEnabled,
                  onRealtimeChanged: (v) =>
                      setState(() => isRealtimeNotifEnabled = v),
                  onAutoDetectionChanged: (v) =>
                      setState(() => isAutoDetectionEnabled = v),
                  onCloudSyncChanged: (v) =>
                      setState(() => isCloudSyncEnabled = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ThresholdList(
                  nh3Controller: thresholdNh3Controller,
                  h2sController: thresholdH2sController,
                  vocController: thresholdVocController,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: const [
                    _SensorCalibrationCard(
                      title: 'Sensor NH3 (MQ-137)',
                      statusText: 'Terkalibrasi',
                      statusColor: Color(0xFFD1FAE5),
                      statusTextColor: Color(0xFF059669),
                      lastDate: '1 Nov 2024',
                      driftPercent: '0.5%',
                      actionText: 'Kalibrasi Ulang',
                      gradientStart: Color(0xFF06B6D4),
                      gradientEnd: Color(0xFF10B981),
                    ),
                    SizedBox(height: 12),
                    _SensorCalibrationCard(
                      title: 'Sensor H2S (MQ-136)',
                      statusText: 'Perlu Kalibrasi',
                      statusColor: Color(0xFFFDE68A),
                      statusTextColor: Color(0xFF92400E),
                      lastDate: '15 Okt 2024',
                      driftPercent: '2.8%',
                      actionText: 'Kalibrasi Sekarang',
                      gradientStart: Color(0xFF0EA5E9),
                      gradientEnd: Color(0xFF10B981),
                    ),
                  ],
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            // Use Awesome Snackbar for feedback
            SnackBar(
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              content: AwesomeSnackbarContent(
                title: 'Terapkan',
                message: 'Pengaturan diterapkan',
                contentType: ContentType.success,
              ),
            ),
          );
        },
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

class _FixedHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FixedHeaderDelegate({required this.child, required this.height});
  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

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

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.getCurrentUser();
    final userPhoto = AuthService.getCurrentUserPhoto();
    final userName = currentUser?['nama'] ?? 'User';
    final userEmail = currentUser?['email'] ?? '';
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    alignment: Alignment.center,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(userName,
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(userEmail,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54)),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: _StatTile(value: '247', label: 'Total Scan')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(value: '98.5%', label: 'Akurasi')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(value: '12', label: 'Hari Aktif')),
            ],
          )
        ],
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
          BoxShadow(
              color: Color.fromARGB(17, 255, 75, 75),
              blurRadius: 10,
              offset: Offset(0, 4)),
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

class _SettingsList extends StatelessWidget {
  const _SettingsList({
    required this.isRealtimeNotifEnabled,
    required this.isAutoDetectionEnabled,
    required this.isCloudSyncEnabled,
    required this.onRealtimeChanged,
    required this.onAutoDetectionChanged,
    required this.onCloudSyncChanged,
  });

  final bool isRealtimeNotifEnabled;
  final bool isAutoDetectionEnabled;
  final bool isCloudSyncEnabled;
  final ValueChanged<bool> onRealtimeChanged;
  final ValueChanged<bool> onAutoDetectionChanged;
  final ValueChanged<bool> onCloudSyncChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color.fromARGB(19, 255, 56, 56),
              blurRadius: 20,
              offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          _SettingRow(
            title: 'Notifikasi Real-time',
            value: isRealtimeNotifEnabled,
            onChanged: onRealtimeChanged,
          ),
          const Divider(height: 1),
          _SettingRow(
            title: 'Auto-Detection',
            value: isAutoDetectionEnabled,
            onChanged: onAutoDetectionChanged,
          ),
          const Divider(height: 1),
          _SettingRow(
            title: 'Cloud Sync',
            value: isCloudSyncEnabled,
            onChanged: onCloudSyncChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {required this.title, required this.value, required this.onChanged});
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
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
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

class _ThresholdList extends StatelessWidget {
  const _ThresholdList({
    required this.nh3Controller,
    required this.h2sController,
    required this.vocController,
  });
  final TextEditingController nh3Controller;
  final TextEditingController h2sController;
  final TextEditingController vocController;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        children: [
          _ThresholdRow(label: 'Threshold NH3', controller: nh3Controller),
          const Divider(height: 1),
          _ThresholdRow(label: 'Threshold H2S', controller: h2sController),
          const Divider(height: 1),
          _ThresholdRow(label: 'Threshold VOC', controller: vocController),
        ],
      ),
    );
  }
}

class _ThresholdRow extends StatelessWidget {
  const _ThresholdRow({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCalibrationCard extends StatelessWidget {
  const _SensorCalibrationCard({
    required this.title,
    required this.statusText,
    required this.statusColor,
    required this.statusTextColor,
    required this.lastDate,
    required this.driftPercent,
    required this.actionText,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String title;
  final String statusText;
  final Color statusColor;
  final Color statusTextColor;
  final String lastDate;
  final String driftPercent;
  final String actionText;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
              ),
              Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(statusText,
                    style: TextStyle(
                        color: statusTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Terakhir', style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 4),
                    // lastDate placeholder below via builder to keep const above minimal
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Drift', style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),
          // Inject values row (non-const)
          Row(
            children: [
              Expanded(
                child: Text(lastDate,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(driftPercent,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1106B6D4),
                    blurRadius: 16,
                    offset: Offset(0, 8)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: Text(actionText,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceInfoList extends StatelessWidget {
  const _DeviceInfoList();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 10)),
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
          // Show confirmation dialog
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
                    color: isDestructive
                        ? const Color(0xFFDC2626)
                        : Colors.black87,
                    fontWeight:
                        isDestructive ? FontWeight.w700 : FontWeight.w600,
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
