import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import '../navigation_bar/main_navigation.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class ForNewUserScreen extends StatefulWidget {
  const ForNewUserScreen({super.key});

  static const String routeName = '/for_newuser';

  @override
  State<ForNewUserScreen> createState() => _ForNewUserScreenState();
}

class _ForNewUserScreenState extends State<ForNewUserScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  Future<void> _setPassword() async {
    if (_loading) return;
    
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation checks
    if (password.isEmpty || confirmPassword.isEmpty) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: const AwesomeSnackbarContent(
          title: 'Validasi',
          message: 'Password dan konfirmasi password harus diisi',
          contentType: ContentType.warning,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }

    if (password != confirmPassword) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: const AwesomeSnackbarContent(
          title: 'Validasi',
          message: 'Konfirmasi password tidak cocok',
          contentType: ContentType.warning,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }

    if (password.length < 6) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: const AwesomeSnackbarContent(
          title: 'Validasi',
          message: 'Password minimal 6 karakter',
          contentType: ContentType.warning,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }

    setState(() => _loading = true);
    try {
      final success = await AuthService.setPasswordForGoogleUser(password);
      
      if (success) {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Berhasil',
            message: 'Password berhasil disimpan!',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        Navigator.pushReplacementNamed(context, MainNavigation.routeName);
      } else {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Gagal',
            message: 'Gagal menyimpan password, coba lagi',
            contentType: ContentType.failure,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (e) {
      if (!mounted) return;
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: const AwesomeSnackbarContent(
          title: 'Error',
          message: 'Terjadi kesalahan, coba lagi',
          contentType: ContentType.failure,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = AuthService.getCurrentUser();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f2027), Color(0xFF2c5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _WelcomeIllustration(),
                  const SizedBox(height: 12),
                  Text(
                    'Selamat Datang!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Halo ${currentUser?['nama'] ?? 'User'}!',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Silakan buat password untuk melengkapi akun Anda',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _FrostedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: 'Tampilkan/Sembunyikan',
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                            prefixIcon: const Icon(Icons.lock_reset_outlined),
                            suffixIcon: IconButton(
                              tooltip: 'Tampilkan/Sembunyikan',
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _setPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24c6dc),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading 
                              ? const SizedBox(
                                  width: 22, 
                                  height: 22, 
                                  child: CircularProgressIndicator(strokeWidth: 2)
                                ) 
                              : const Text('Simpan Password'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Password ini akan digunakan untuk login manual di masa depan',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(color: Colors.black38, offset: Offset(0, 8), blurRadius: 24),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white60),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white70),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIconColor: Colors.white70,
            suffixIconColor: Colors.white70,
          ),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.white, 
            displayColor: Colors.white
          ),
        ),
        child: child,
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF24c6dc), Color(0xFF514a9d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24c6dc).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_add_alt_1,
        size: 60,
        color: Colors.white,
      ),
    );
  }
}
