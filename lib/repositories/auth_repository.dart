import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/result.dart';
import 'base_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthRepository extends BaseRepository {
  User? get currentUser => supabase.auth.currentUser;
  
  Stream<AuthState> get onAuthStateChange => supabase.auth.onAuthStateChange;

  Future<Result<void>> signUp(String email, String password, String name) async {
    return execute(() async {
      await supabase.auth.signUp(email: email, password: password, data: {'full_name': name});
    }, errorMessage: 'Failed to sign up');
  }

  Future<Result<void>> updateUser(UserAttributes attributes) async {
    return execute(() async {
      await supabase.auth.updateUser(attributes);
    }, errorMessage: 'Failed to update user');
  }

  Future<Result<void>> resetPasswordForEmail(String email) async {
    return execute(() async {
      await supabase.auth.resetPasswordForEmail(email);
    }, errorMessage: 'Failed to reset password');
  }

  Future<Result<void>> signInAnonymously() async {
    return execute(() async {
      await supabase.auth.signInAnonymously();
    }, errorMessage: 'Failed to sign in anonymously');
  }

  Future<Result<void>> resendConfirmationEmail(String email) async {
    return execute(() async {
      await supabase.auth.resend(type: OtpType.signup, email: email);
    }, errorMessage: 'Failed to resend confirmation email');
  }

  Future<Result<void>> signIn(String email, String password) async {
    return execute(() async {
      await supabase.auth.signInWithPassword(email: email, password: password);
    }, errorMessage: 'Invalid email or password');
  }

  Future<Result<void>> signInWithGoogle() async {
    return execute(() async {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      if (webClientId.isEmpty) {
        throw Exception(
          'Google Sign-In is not configured yet. '
          'Please add GOOGLE_WEB_CLIENT_ID to your .env file.'
        );
      }
      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google Sign-In was cancelled.');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) throw Exception('Could not get ID token from Google.');

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    }, errorMessage: 'Google Sign-In failed');
  }

  Future<Result<void>> signOut() async {
    return execute(() async {
      await supabase.auth.signOut();
    }, errorMessage: 'Failed to sign out');
  }

  Future<Result<Map<String, dynamic>?>> getProfile() async {
    return execute(() async {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('Not logged in');
      return await supabase.from('profiles').select().eq('id', userId).maybeSingle();
    }, errorMessage: 'Failed to load profile');
  }

  Future<Result<void>> updateProfile(Map<String, dynamic> updates) async {
    return execute(() async {
      final userId = currentUser?.id;
      if (userId == null) throw Exception('Not logged in');
      await supabase.from('profiles').upsert({'id': userId, ...updates});
    }, errorMessage: 'Failed to update profile');
  }

  Future<bool> isPremiumUser() async {
    final res = await getProfile();
    if (res is Success && res.data != null) {
      return res.data!['is_premium'] == true;
    }
    return false;
  }
}
