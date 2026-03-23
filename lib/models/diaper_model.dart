class DiaperLog {
  final String id;
  final String userId;
  final String type; // 'pee', 'poop', 'both'
  final String? notes;
  final DateTime createdAt;

  DiaperLog({
    required this.id,
    required this.userId,
    required this.type,
    this.notes,
    required this.createdAt,
  });

  factory DiaperLog.fromJson(Map<String, dynamic> json) {
    return DiaperLog(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
