import 'package:supabase/supabase.dart';

void main() async {
    const supabaseUrl = 'https://ficmvzbcjlolaqykryfb.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpY212emJjamxvbGFxeWtyeWZiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0Mjc0NjAsImV4cCI6MjA4MDAwMzQ2MH0.H6Vt14W0PQVETlU2bH6YdTyKrOzcvWByXH8zBZ7w0zU';
    
    final client = SupabaseClient(supabaseUrl, supabaseKey);
    final authResponse = await client.auth.signInAnonymously();
    final user = authResponse.user;
    
    print("User ID: ${user?.id}");
    
    try {
      await client.from('tummy_time_sessions').insert({
        'user_id': user?.id,
        'duration_sec': 120,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      print("SUCCESS: tummy_time_sessions insertion worked");
    } catch (e) {
      print("ERROR on tummy_time_sessions insert: $e");
    }

    try {
      await client.from('mom_care_checklist').insert({
        'id': 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'user_id': user?.id,
        'title': 'Test Checklist',
      });
      print("SUCCESS: mom_care_checklist insertion worked");
    } catch (e) {
      print("ERROR on mom_care_checklist insert: $e");
    }
}
