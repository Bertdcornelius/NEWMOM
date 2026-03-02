class Feed {
  final String id;
  final String userId;
  final String type; // 'breast', 'bottle', 'solid'
  final String? side; // 'L', 'R', 'Both'
  final int? amountMl;
  final int? durationMin;
  final DateTime? nextDue;
  final DateTime createdAt;
  final String? notes;

  Feed({
    required this.id,
    required this.userId,
    required this.type,
    this.side,
    this.amountMl,
    this.durationMin,
    this.nextDue,
    required this.createdAt,
    this.notes,
  });

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      side: json['side'],
      amountMl: json['amount_ml'],
      durationMin: json['duration_min'],
      nextDue: json['next_due'] != null ? DateTime.parse(json['next_due']) : null,
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'type': type,
      'side': side,
      'amount_ml': amountMl,
      'duration_min': durationMin,
      'next_due': nextDue?.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'notes': notes,
    };
  }
}
