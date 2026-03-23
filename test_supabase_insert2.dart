import 'package:supabase/supabase.dart';

void main() async {
  try {
    const supabaseUrl = 'https://ficmvzbcjlolaqykryfb.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpY212emJjamxvbGFxeWtyeWZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0Mjc0NjAsImV4cCI6MjA4MDAwMzQ2MH0.H6Vt14W0PQVETlU2bH6YdTyKrOzcvWByXH8zBZ7w0zU';
    
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
    print("Attempting to insert into diaper_logs...");
    try {
      await client.from('diaper_logs').insert({
        'user_id': user.id,
        'type': 'pee',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      print("SUCCESS: diaper_logs insertion worked");
    } catch (e) {
      print("ERROR on diaper_logs insert: $e");
    }
    
    // Attempt to SELECT feeds
    print("Attempting to SELECT from feeds...");
    try {
       final data = await client.from('feeds').select().limit(5);
       print("SUCCESS: feeds select returned ${data.length} rows");
    } catch(e) {
       print("ERROR on feeds SELECT: $e");
    }

    print("Done.");

  } catch (e) {
    print("Fatal Script Error: $e");
  }
}
