import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());
  
  final client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  print("Attempting to sign in to capture auth token...");
  try {
    final authRes = await client.auth.signInWithPassword(email: 'test@example.com', password: 'password123'); // Assuming test acc from earlier
    final user = authRes.user;
    if (user == null) {
       print("Failed to login test account.");
       return;
    }
    
    print("User Auth ID: ${user.id}");
    print("Executing raw insert to diaper logs mimicking the UI...");
    
    final payload = {
      'user_id': user.id,
      'type': 'pee',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    
    print("Payload: $payload");
    await client.from('diaper_logs').insert(payload);
    print("SUCCESS: Inserted diaper log natively!");
    
  } on AuthException catch (e) {
     print("AuthException: $e");
  } on PostgrestException catch (e) {
     print("PostgrestException: ${e.message} \nDetails: ${e.details} \nHint: ${e.hint}");
  } catch (e) {
     print("General Exception: $e");
  }
}
