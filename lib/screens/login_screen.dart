import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'for_newuser.dart';
import '../auth/auth_service.dart';
import '../navigation_bar/main_navigation.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  Future<void> _signInWithEmailOrUsername() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final identifier = _usernameController.text.trim();
      final password = _passwordController.text;

      if (identifier.isEmpty || password.isEmpty) {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Validasi',
            message: 'Username/Email dan password harus diisi',
            contentType: ContentType.warning,
          ),
        );
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(snackBar);
        return;
      }

      // Login menggunakan custom authentication
      final success = await AuthService.login(identifier, password);
      
      if (success) {
        if (!mounted) return;
        final snackBar = SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: const AwesomeSnackbarContent(
            title: 'Berhasil',
            message: 'Login berhasil!',
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
            message: 'Username/Email atau password salah',
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
          message: 'Gagal login, coba lagi',
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
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  const _HeaderIllustration(),
                  const SizedBox(height: 12),
                  Text(
                    'WITFood',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat datang kembali',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  _FrostedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                          controller: _passwordController,
                          obscureText: _obscurePassword,
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(context, ForgotPasswordScreen.routeName),
                            child: const Text('Lupa password?'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signInWithEmailOrUsername,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF24c6dc),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Masuk'),
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
                            const Text("Belum punya akun?"),
                            TextButton(
                              onPressed: () => Navigator.pushReplacementNamed(context, RegisterScreen.routeName),
                              child: const Text('Daftar'),
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


class _HeaderIllustration extends StatelessWidget {
  const _HeaderIllustration();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SafeAssetImage('assets/images/login_header.jpg'),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.black.withOpacity(0.25),
                child: const Text(
                  'Selamat datang di Food Goard Pro',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeAssetImage extends StatelessWidget {
  const _SafeAssetImage(this.path);

  final String path;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.black26,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.white70),
      ),
      color: Colors.black.withOpacity(0.3),
      colorBlendMode: BlendMode.darken,
    );
  }
}


