import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'for_newuser.dart';
import '../navigation_bar/main_navigation.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController(); // 1. Add controller for name
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  Future<void> _register() async {
    if (_loading) return;
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    // Validation checks
    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
      final snackBar = SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: const AwesomeSnackbarContent(
          title: 'Validasi',
          message: 'Lengkapi semua field',
          contentType: ContentType.warning,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }
    if (password != confirm) {
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
      // Register menggunakan custom authentication
      final success = await AuthService.register(name, username, email, password);
      
      if (success) {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Berhasil',
            message: 'Registrasi berhasil! Silakan login.',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Gagal',
            message: 'Username atau email sudah digunakan',
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
          message: 'Registrasi gagal, coba lagi',
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

  Future<void> _signInWithGoogle() async {
    if (_loading) return;
    setState(() => _loading = true);
    
    try {
      final user = await AuthService.signInWithGoogle();
      
      if (user != null) {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Berhasil',
            message: 'Login Google berhasil!',
            contentType: ContentType.success,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        
        // Check if user needs to set password
        if (AuthService.needsPasswordSetup()) {
          Navigator.pushReplacementNamed(context, ForNewUserScreen.routeName);
        } else {
          Navigator.pushReplacementNamed(context, MainNavigation.routeName);
        }
      } else {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Dibatalkan',
            message: 'Login Google dibatalkan',
            contentType: ContentType.warning,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      // Don't show error message for Google Sign-In as it often throws exceptions even on success
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose(); // Dispose name controller
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF232526), Color(0xFF414345)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Buat Akun',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WITFood',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  _FrostedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController, // 5. Name TextField
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                            onPressed: _loading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24c6dc),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Daftar'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: Colors.white24)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'atau',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
                              ),
                            ),
                            const Expanded(child: Divider(color: Colors.white24)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _loading ? null : _signInWithGoogle,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: Image.asset(
                              'assets/images/icon google.png',
                              width: 20,
                              height: 20,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 20),
                            ),
                            label: const Text('Continue with Google'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Sudah punya akun?"),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                              child: const Text('Masuk'),
                            ),
                          ],
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
          textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        child: child,
      ),
    );
  }
}