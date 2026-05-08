import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:math';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static Map<String, dynamic>? _currentUser;

  // Hash password menggunakan SHA-256
  static String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String _generateNumericToken({int length = 6}) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
  }

  static Future<bool> sendResetTokenEmail(String email) async {
    try {
      // Cek user berdasarkan email
      final user = await _supabase
          .from('users')
          .select('id, nama, email')
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        return false; // email belum terdaftar
      }

      final token = _generateNumericToken(length: 6);
      final expiry = DateTime.now().add(const Duration(minutes: 10));

      // Simpan token & expired_token
      await _supabase.from('users').update({
        'token': token,
        'expired_token': expiry.toIso8601String(),
      }).eq('id', user['id']);

      // Kirim email menggunakan SMTP
      final smtpHost = dotenv.env['SMTP_HOST'];
      final smtpPort = int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
      final smtpUser = dotenv.env['SMTP_USERNAME'];
      final smtpPass = dotenv.env['SMTP_PASSWORD'];
      final fromEmail = dotenv.env['FROM_EMAIL'] ?? smtpUser;
      final appName = dotenv.env['APP_NAME'] ?? 'FoodGuardPro';

      if (smtpHost == null || smtpUser == null || smtpPass == null) {
        throw Exception('SMTP configuration missing in .env');
      }

      final server = SmtpServer(
        smtpHost,
        port: smtpPort,
        username: smtpUser,
        password: smtpPass,
        ignoreBadCertificate: false,
        ssl: smtpPort == 465,
        allowInsecure: smtpPort != 465,
      );

      final htmlBody = '''
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kode Reset Password</title>
  <style>
    body { background:#0F2027; margin:0; font-family: Arial, Helvetica, sans-serif; }
    .wrap { max-width:560px; margin:0 auto; padding:24px; }
    .card { background:#ffffff; border-radius:12px; overflow:hidden; }
    .header { background: linear-gradient(135deg,#24c6dc,#514a9d); color:#fff; padding:20px 24px; }
    .content { padding:24px; color:#233; }
    .greet { margin:0 0 8px 0; font-size:16px; }
    .title { margin:0 0 12px 0; font-size:18px; font-weight:700; color:#102a43; }
    .token { letter-spacing:3px; font-size:28px; font-weight:800; color:#102a43; background:#eef6ff; padding:12px 16px; border-radius:10px; display:inline-block; }
    .muted { color:#556; font-size:13px; }
    .footer { text-align:center; color:#ccd; font-size:12px; padding:16px; }
  </style>
  <!--[if mso]><style>.token{letter-spacing:2px;}</style><![endif]-->
  <!-- Preheader text -->
  <span style="display:none!important;opacity:0;color:transparent;height:0;width:0;overflow:hidden;">Kode reset password $appName: $token</span>
  <!-- End Preheader -->
  </head>
<body>
  <div class="wrap">
    <div class="card">
      <div class="header"><h2 style="margin:0;">$appName</h2></div>
      <div class="content">
        <p class="greet">Halo ${user['nama']},</p>
        <p class="title">Berikut adalah kode untuk mengatur ulang kata sandi Anda:</p>
        <p><span class="token">$token</span></p>
        <p class="muted">Kode ini berlaku hingga ${expiry.toLocal()} (10 menit). Jika Anda tidak meminta reset, abaikan email ini.</p>
      </div>
    </div>
    <div class="footer">&copy; ${DateTime.now().year} $appName</div>
  </div>
  </body>
</html>
''';

      final message = Message()
        ..from = Address(fromEmail!, appName)
        ..recipients.add(email)
        ..subject = 'Kode Reset Password $appName'
        ..text = 'Halo ${user['nama']},\n\n' 
            'Gunakan kode berikut untuk mengatur ulang password Anda: $token\n' 
            'Kode berlaku hingga ${expiry.toLocal()} (10 menit).\n\n' 
            'Jika Anda tidak meminta reset, abaikan email ini.'
        ..html = htmlBody;

      await send(message, server);

      return true;
    } catch (e) {
      print('sendResetTokenEmail error: $e');
      rethrow;
    }
  }

  static Future<bool> verifyResetToken(String email, String token) async {
    try {
      final user = await _supabase
          .from('users')
          .select('id, expired_token')
          .eq('email', email)
          .eq('token', token)
          .maybeSingle();

      if (user == null) return false;

      final expiredToken = user['expired_token'];
      if (expiredToken == null) return false;

      final expiry = DateTime.tryParse(expiredToken.toString());
      if (expiry == null) return false;

      // token masih berlaku?
      if (DateTime.now().isAfter(expiry)) {
        return false;
      }
      return true;
    } catch (e) {
      print('verifyResetToken error: $e');
      return false;
    }
  }

  static Future<bool> resetPassword(String email, String token, String newPassword) async {
    try {
      // validasi token
      final valid = await verifyResetToken(email, token);
      if (!valid) return false;

      final hashed = _hashPassword(newPassword);
      await _supabase
          .from('users')
          .update({
            'password': hashed,
            'token': null,
            'expired_token': null,
          })
          .eq('email', email)
          .eq('token', token);

      return true;
    } catch (e) {
      print('resetPassword error: $e');
      return false;
    }
  }

  // Login dengan username/email dan password
  static Future<bool> login(String identifier, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      
      // Cari user berdasarkan username atau email
      final response = await _supabase
          .from('users')
          .select('*')
          .or('username.eq.$identifier,email.eq.$identifier')
          .eq('password', hashedPassword)
          .maybeSingle();

      if (response != null) {
        _currentUser = response;
        // Simpan session ke SharedPreferences
        await _saveUserSession(response);
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Simpan session user ke SharedPreferences
  static Future<void> _saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_session', jsonEncode(user));
  }

  // Load session user dari SharedPreferences
  static Future<Map<String, dynamic>?> _loadUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user_session');
      if (userString != null) {
        return jsonDecode(userString);
      }
    } catch (e) {
      print('Load session error: $e');
    }
    return null;
  }

  // Initialize session saat app start
  static Future<void> initializeSession() async {
    _currentUser = await _loadUserSession();
  }

  // Register user baru
  static Future<bool> register(String name, String username, String email, String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      
      // Cek apakah username atau email sudah ada
      final existingUser = await _supabase
          .from('users')
          .select('id')
          .or('username.eq.$username,email.eq.$email')
          .maybeSingle();

      if (existingUser != null) {
        return false; // User sudah ada
      }

      // Insert user baru
      await _supabase.from('users').insert({
        'nama': name,
        'username': username,
        'email': email,
        'password': hashedPassword,
      });

      return true;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  // Cek apakah user sudah login
  static bool isLoggedIn() {
    return _currentUser != null;
  }

  // Logout
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
  }

  // Get current user data
  static Map<String, dynamic>? getCurrentUser() {
    return _currentUser;
  }

  // Get current user photo URL
  static String? getCurrentUserPhoto() {
    return _currentUser?['foto'];
  }

  // Google Sign-In
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }
      
      // Cek apakah user sudah ada di database
      final existingUser = await _supabase
          .from('users')
          .select('*')
          .eq('email', googleUser.email)
          .maybeSingle();

      if (existingUser != null) {
        // User sudah ada, update foto jika berbeda
        if (existingUser['foto'] != googleUser.photoUrl) {
          await _supabase
              .from('users')
              .update({'foto': googleUser.photoUrl})
              .eq('id', existingUser['id']);
          
          // Update current user data
          existingUser['foto'] = googleUser.photoUrl;
        }
        
        _currentUser = existingUser;
        await _saveUserSession(existingUser);
        return existingUser;
      } else {
        // User baru, simpan ke database dengan password kosong
        final newUser = {
          'nama': googleUser.displayName ?? '',
          'email': googleUser.email,
          'username': googleUser.email.split('@')[0], // Generate username from email
          'password': '', // Empty password for Google users initially
          'foto': googleUser.photoUrl, // Simpan foto profile dari Google
        };

        final response = await _supabase
            .from('users')
            .insert(newUser)
            .select()
            .single();

        _currentUser = response;
        await _saveUserSession(response);
        return response;
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      return null; // Return null instead of rethrowing to prevent UI errors
    }
  }

  // Check if user needs to set password (for new Google users)
  static bool needsPasswordSetup() {
    if (_currentUser == null) return false;
    return _currentUser!['password'] == null || _currentUser!['password'] == '';
  }

  // Set password for Google users
  static Future<bool> setPasswordForGoogleUser(String password) async {
    try {
      if (_currentUser == null) return false;
      
      final hashedPassword = _hashPassword(password);
      
      await _supabase
          .from('users')
          .update({'password': hashedPassword})
          .eq('id', _currentUser!['id']);

      // Update current user data
      _currentUser!['password'] = hashedPassword;
      await _saveUserSession(_currentUser!);
      
      return true;
    } catch (e) {
      print('Set password error: $e');
      return false;
    }
  }

  // Google Sign-Out
  static Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await logout();
  }
}
