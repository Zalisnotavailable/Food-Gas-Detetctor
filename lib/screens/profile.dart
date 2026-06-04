// lib/screens/profile.dart
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

  // ─── Edit Profile ──────────────────────────────────────────────────────────
  Future<void> _showEditProfile() async {
    final user = AuthService.getCurrentUser();
    final namaCtrl     = TextEditingController(text: user?['nama'] ?? '');
    final usernameCtrl = TextEditingController(text: user?['username'] ?? '');
    final formKey      = GlobalKey<FormState>();
    bool saving        = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Edit Profil',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.onSurface)),
                const SizedBox(height: 20),

                // Nama
                TextFormField(
                  controller: namaCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 14),

                // Username
                TextFormField(
                  controller: usernameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Username tidak boleh kosong' : null,
                ),
                const SizedBox(height: 20),

                // Tombol simpan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModal(() => saving = true);
                      try {
                        final userId = user?['id']?.toString();
                        if (userId == null) throw Exception('User tidak ditemukan');

                        // Cek username sudah dipakai user lain
                        final existing = await Supabase.instance.client
                            .from('users')
                            .select('id')
                            .eq('username', usernameCtrl.text.trim())
                            .neq('id', userId)
                            .maybeSingle();

                        if (existing != null) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Username sudah digunakan'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          setModal(() => saving = false);
                          return;
                        }

                        // Update ke Supabase
                        await Supabase.instance.client
                            .from('users')
                            .update({
                          'nama':     namaCtrl.text.trim(),
                          'username': usernameCtrl.text.trim(),
                        })
                            .eq('id', userId);

                        // Update local session
                        final updatedUser = Map<String, dynamic>.from(
                            AuthService.getCurrentUser()!);
                        updatedUser['nama']     = namaCtrl.text.trim();
                        updatedUser['username'] = usernameCtrl.text.trim();
                        await AuthService.updateCurrentUser(updatedUser);

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Profil berhasil diperbarui'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setModal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Gagal: $e'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Ganti Password ────────────────────────────────────────────────────────
  Future<void> _showChangePassword() async {
    final oldCtrl     = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey     = GlobalKey<FormState>();
    bool saving       = false;
    bool showOld      = false;
    bool showNew      = false;
    bool showConfirm  = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Ganti Password',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.onSurface)),
                const SizedBox(height: 20),

                // Password lama
                TextFormField(
                  controller: oldCtrl,
                  obscureText: !showOld,
                  decoration: InputDecoration(
                    labelText: 'Password Lama',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(showOld
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setModal(() => showOld = !showOld),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.isEmpty) ? 'Masukkan password lama' : null,
                ),
                const SizedBox(height: 14),

                // Password baru
                TextFormField(
                  controller: newCtrl,
                  obscureText: !showNew,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(showNew
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setModal(() => showNew = !showNew),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Masukkan password baru';
                    if (v.length < 6) return 'Minimal 6 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Konfirmasi password baru
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: !showConfirm,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(showConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setModal(() => showConfirm = !showConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Konfirmasi password baru';
                    if (v != newCtrl.text) return 'Password tidak cocok';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;
                      setModal(() => saving = true);
                      try {
                        final success = await AuthService.changePassword(
                          oldPassword: oldCtrl.text,
                          newPassword: newCtrl.text,
                        );

                        if (!success) {
                          setModal(() => saving = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Password lama tidak sesuai'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Password berhasil diperbarui'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setModal(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Gagal: $e'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: saving
                        ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                        : const Text('Simpan Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Delete Account ────────────────────────────────────────────────────────
  Future<void> _deleteAccount() async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      title: 'Hapus Akun',
      desc: 'Semua data akun Anda akan dihapus permanen dan tidak dapat dikembalikan. Lanjutkan?',
      btnCancelText: 'Batal',
      btnOkText: 'Hapus',
      btnOkColor: Theme.of(context).colorScheme.error,
      btnCancelOnPress: () {},
      btnOkOnPress: () => _confirmDelete(),
    ).show();
  }

  Future<void> _confirmDelete() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Konfirmasi Akhir',
              style: TextStyle(fontWeight: FontWeight.w800, color: cs.error)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ketik ', style: TextStyle(color: cs.onSurface)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('HAPUS',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: cs.error,
                        letterSpacing: 2)),
              ),
              const SizedBox(height: 8),
              Text('untuk mengkonfirmasi penghapusan akun.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Ketik HAPUS',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.error, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cs.error),
              onPressed: () {
                if (controller.text.trim() == 'HAPUS') {
                  Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Ketik HAPUS dengan huruf kapital'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: const Text('Hapus Akun'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      _showLoadingDialog();
      final user   = AuthService.getCurrentUser();
      final userId = user?['id']?.toString();

      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('id', userId);
      }

      await AuthService.logout();
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.pushNamedAndRemoveUntil(
          context, LoginScreen.routeName, (_) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Akun berhasil dihapus'),
            behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Gagal',
        desc: 'Gagal menghapus akun: $e',
        btnOkOnPress: () {},
      ).show();
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memproses...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final sb = Supabase.instance.client;
      final totalRes = await sb.from('sensor_readings').select('id').count(CountOption.exact);
      final total = totalRes.count ?? 0;

      final hariRes = await sb
          .from('sensor_readings')
          .select('timestamp')
          .order('timestamp', ascending: false)
          .limit(1000);
      final hariSet = <String>{};
      for (final row in hariRes as List) {
        final dt = DateTime.tryParse(row['timestamp'].toString());
        if (dt != null) hariSet.add('${dt.year}-${dt.month}-${dt.day}');
      }

      final gasRes = await sb
          .from('sensor_readings')
          .select('nh3,h2s,ch4,co2,voc,c2h5oh,co,h2')
          .order('timestamp', ascending: false)
          .limit(100);
      int aman = 0;
      for (final row in gasRes as List) {
        if (!_cekDanger(row)) aman++;
      }
      final persen =
      gasRes.isEmpty ? 0 : ((aman / gasRes.length) * 100).round();

      if (mounted) {
        setState(() {
          _totalScan  = total;
          _hariAktif  = hariSet.length;
          _statusAman = '$persen%';
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  bool _cekDanger(Map<String, dynamic> row) {
    const t = {
      'nh3': 10.0, 'h2s': 5.0, 'ch4': 50.0,
      'co2': 1000.0, 'voc': 0.5, 'c2h5oh': 20.0,
      'co': 9.0, 'h2': 20.0,
    };
    for (final e in t.entries) {
      final v = (row[e.key] as num?)?.toDouble();
      if (v != null && v >= e.value) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs    = Theme.of(context).colorScheme;
    final user  = AuthService.getCurrentUser();
    final photo = AuthService.getCurrentUserPhoto();
    final name  = user?['nama'] ?? 'User';
    final email = user?['email'] ?? '';

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: cs.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ─── App Bar ──────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Pengaturan',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20)),
                    Text('Akun & Konfigurasi',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF64B5F6)],
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [

                  // ─── Profile Card ────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        // Avatar
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: cs.primaryContainer,
                              backgroundImage: photo != null
                                  ? NetworkImage(photo)
                                  : null,
                              child: photo == null
                                  ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onPrimaryContainer))
                                  : null,
                            ),
                        const SizedBox(height: 12),
                        Text(name,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface)),
                        const SizedBox(height: 4),
                        Text(email,
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 16),

                        // Stats
                        _loadingStats
                            ? const CircularProgressIndicator()
                            : Row(children: [
                          _StatCard(
                              value: _totalScan.toString(),
                              label: 'Total Scan',
                              cs: cs),
                          const SizedBox(width: 10),
                          _StatCard(
                              value: _statusAman,
                              label: 'Status Aman',
                              cs: cs),
                          const SizedBox(width: 10),
                          _StatCard(
                              value: _hariAktif.toString(),
                              label: 'Hari Aktif',
                              cs: cs),
                        ]),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Akun Card ───────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      ListTile(
                        leading:
                        Icon(Icons.person_outline, color: cs.primary),
                        title: Text('Edit Profil',
                            style: TextStyle(color: cs.onSurface)),
                        subtitle: Text('Ubah nama & username',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right,
                            color: cs.onSurfaceVariant),
                        onTap: _showEditProfile,
                      ),
                      Divider(
                          height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading: Icon(Icons.lock_outline, color: cs.primary),
                        title: Text('Ganti Password',
                            style: TextStyle(color: cs.onSurface)),
                        subtitle: Text('Perbarui kata sandi akun',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right,
                            color: cs.onSurfaceVariant),
                        onTap: _showChangePassword,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  // ─── Notifikasi ──────────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text('Notifikasi Real-time',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      subtitle: Text('Peringatan gas Warning & Bahaya',
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12)),
                      secondary: Icon(Icons.notifications_outlined,
                          color: cs.primary),
                      value: _notifEnabled,
                      onChanged: _onNotifToggle,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Device & Aksi ───────────────────────────────────
                  Card(
                    elevation: 0,
                    color: cs.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      ListTile(
                        leading:
                        Icon(Icons.memory_rounded, color: cs.primary),
                        title: Text('Firmware ESP32',
                            style: TextStyle(color: cs.onSurface)),
                        trailing: Text('v3.2.1',
                            style:
                            TextStyle(color: cs.onSurfaceVariant)),
                      ),
                      Divider(
                          height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading:
                        Icon(Icons.devices_rounded, color: cs.primary),
                        title: Text('Device ID',
                            style: TextStyle(color: cs.onSurface)),
                        trailing: Text('FG-ESP32-009',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                      ),
                      Divider(
                          height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading:
                        Icon(Icons.logout_rounded, color: cs.error),
                        title: Text('Logout',
                            style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.w600)),
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
                            Navigator.pushNamedAndRemoveUntil(context,
                                LoginScreen.routeName, (_) => false);
                          },
                        ).show(),
                      ),
                      Divider(
                          height: 1, indent: 56, color: cs.outlineVariant),
                      ListTile(
                        leading: Icon(Icons.delete_forever_rounded,
                            color: cs.error),
                        title: Text('Hapus Akun',
                            style: TextStyle(
                                color: cs.error,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            'Hapus akun dan semua data secara permanen',
                            style: TextStyle(
                                color: cs.onSurfaceVariant, fontSize: 12)),
                        onTap: _deleteAccount,
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
  const _StatCard(
      {required this.value, required this.label, required this.cs});
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
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.primary)),
          const SizedBox(height: 4),
          Text(label,
              style:
              TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}