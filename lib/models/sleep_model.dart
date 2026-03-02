class SleepLog {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? notes;
  final DateTime createdAt;

  SleepLog({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.notes,
    required this.createdAt,
  });

  factory SleepLog.fromJson(Map<String, dynamic> json) {
    return SleepLog(
      id: json['id'],
      userId: json['user_id'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
