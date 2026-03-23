import 'dart:io';
import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  try {
    // Load env manually
    final envFile = File('.env');
    final lines = await envFile.readAsLines();
    final env = <String, String>{};
    for (var line in lines) {
      final parts = line.split('=');
      if (parts.length >= 2) {
        env[parts[0].trim()] = parts.sublist(1).join('=').trim();
      }
    }

    final supabaseUrl = env['SUPABASE_URL']!;
    final supabaseKey = env['SUPABASE_ANON_KEY']!;
    
    final client = SupabaseClient(supabaseUrl, supabaseKey);
    
    // Attempt anonymous sign in to get a legitimate user_id
    print("Signing in anonymously...");
    final authResponse = await client.auth.signInAnonymously();
    final user = authResponse.user;
    if (user == null) {
      print("Failed to sign in anonymously!");
      return;
    }
    
    print("User ID: ${user.id}");
    
    // Attempt to insert a sleep log
    print("Attempting to insert into sleep_logs...");
    try {
      await client.from('sleep_logs').insert({
        'user_id': user.id,
        'start_time': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print("SUCCESS: sleep_logs insertion worked");
    } catch (e) {
      print("ERROR on sleep_logs insert: $e");
    }

    // Attempt to insert a feed
    print("Attempting to insert into feeds...");
    try {
      await client.from('feeds').insert({
        'user_id': user.id,
        'type': 'breast',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print("SUCCESS: feeds insertion worked");
    } catch (e) {
      print("ERROR on feeds insert: $e");
    }

    // Attempt to insert a diaper
    print("Attempting to insert into diapers...");
    try {
      await client.from('diapers').insert({
        'user_id': user.id,
        'type': 'pee',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print("SUCCESS: diapers insertion worked");
    } catch (e) {
      print("ERROR on diapers insert: $e");
    }

  } catch (e) {
    print("Fatal Script Error: $e");
  }
}
