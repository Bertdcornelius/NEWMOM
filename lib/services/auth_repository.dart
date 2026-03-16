import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    await _client.auth.signInAnonymously();
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    notifyListeners();
  }

  Future<UserResponse> updateUser(String email, String password) async {
    return await _client.auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> resendConfirmationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  // --- Google Sign-In ---
  Future<void> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      if (webClientId.isEmpty) {
        throw Exception(
          'Google Sign-In is not configured yet. '
          'Please add GOOGLE_WEB_CLIENT_ID to your .env file.'
        );
      }
      final googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In was cancelled.');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('Could not get ID token from Google. Please try again.');

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      notifyListeners();
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('GOOGLE_WEB_CLIENT_ID')) {
        rethrow;
      }
      if (msg.contains('network') || msg.contains('Network')) {
        throw Exception('Network error. Please check your internet connection and try again.');
      }
      if (msg.contains('channel-error') || msg.contains('PlatformException')) {
        throw Exception(
          'Google Sign-In is not configured for this device. '
          'Please ensure google-services.json is set up correctly.'
        );
      }
      if (msg.contains('cancelled')) {
        rethrow;
      }
      throw Exception('Google Sign-In failed: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
