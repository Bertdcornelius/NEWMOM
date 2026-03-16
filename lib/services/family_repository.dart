import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamilyRepository extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _membersChannel;

  User? get currentUser => _client.auth.currentUser;

  /// Initialize Realtime updates for a specific circle
  void initRealtime(String circleId) {
    if (_membersChannel != null) return;
    _membersChannel = _client.channel('public:family_members').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'family_members',
      filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'circle_id', value: circleId),
      callback: (payload) {
        notifyListeners();
      }
    ).subscribe();
  }

  @override
  void dispose() {
    _membersChannel?.unsubscribe();
    super.dispose();
  }

  /// Create a new family circle and return the invite code
  Future<String> createFamilyCircle(String name) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Generate a 6-char invite code
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final code = List.generate(6, (i) => chars[(DateTime.now().microsecondsSinceEpoch + i * 7) % chars.length]).join();

    await _client.from('family_circles').insert({
      'owner_id': user.id,
      'name': name,
      'invite_code': code,
    });

    // Also add the owner as a member
    final circles = await _client.from('family_circles').select().eq('invite_code', code).limit(1);
    if (circles.isNotEmpty) {
      await _client.from('family_members').insert({
        'circle_id': circles[0]['id'],
        'user_id': user.id,
        'role': 'Parent',
        'display_name': user.email ?? 'Owner',
      });
    }

    return code;
  }

  /// Get the user's family circle (if they belong to one)
  Future<Map<String, dynamic>?> getMyFamilyCircle() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Check if user is a member of any circle
      final memberships = await _client
          .from('family_members')
          .select('circle_id')
          .eq('user_id', user.id)
          .limit(1);

      if (memberships.isEmpty) return null;

      final circleId = memberships[0]['circle_id'];
      final circles = await _client
          .from('family_circles')
          .select()
          .eq('id', circleId)
          .limit(1);

      if (circles.isEmpty) return null;
      return circles[0];
    } catch (e) {
      debugPrint('Error fetching family circle: $e');
      return null;
    }
  }

  /// Get all members of a family circle
  Future<List<Map<String, dynamic>>> getFamilyMembers(String circleId) async {
    try {
      initRealtime(circleId); // Hook up realtime
      final members = await _client
          .from('family_members')
          .select()
          .eq('circle_id', circleId);
      return List<Map<String, dynamic>>.from(members);
    } catch (e) {
      debugPrint('Error fetching family members: $e');
      return [];
    }
  }

  /// Join a family circle using an invite code
  Future<bool> joinFamilyCircle(String inviteCode, String displayName, String role) async {
    final user = currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final circles = await _client
          .from('family_circles')
          .select()
          .eq('invite_code', inviteCode.toUpperCase())
          .limit(1);

      if (circles.isEmpty) return false; // Invalid code

      final circleId = circles[0]['id'];

      // Check if already a member
      final existing = await _client
          .from('family_members')
          .select()
          .eq('circle_id', circleId)
          .eq('user_id', user.id)
          .limit(1);

      if (existing.isNotEmpty) return true; // Already joined

      await _client.from('family_members').insert({
        'circle_id': circleId,
        'user_id': user.id,
        'role': role,
        'display_name': displayName,
      });

      return true;
    } catch (e) {
      debugPrint('Error joining family circle: $e');
      return false;
    }
  }

  /// Remove a member from the family circle
  Future<void> removeFamilyMember(String memberId) async {
    await _client.from('family_members').delete().eq('id', memberId);
  }
}
