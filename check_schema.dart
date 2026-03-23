import 'package:supabase/supabase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  dotenv.testLoad(fileInput: File('.env').readAsStringSync());
  
  final client = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  try {
    print("Fetching one row from feeds...");
    final f = await client.from('feeds').select().limit(1);
    print("Feed row: $f");

    print("Fetching one row from sleep_logs...");
    final s = await client.from('sleep_logs').select().limit(1);
    print("Sleep row: $s");
    
    print("Fetching one row from diaper_logs...");
    final d = await client.from('diaper_logs').select().limit(1);
    print("Diaper row: $d");
    
  } catch (e) {
    print("Error: $e");
  }
}
