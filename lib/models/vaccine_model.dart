class Vaccine {
  final String id;
  final String userId;
  final String name;
  final DateTime? dueDate;
  final DateTime? givenDate;
  final String status; // 'pending', 'given', 'skipped'
  final DateTime createdAt;

  Vaccine({
    required this.id,
    required this.userId,
    required this.name,
    this.dueDate,
    this.givenDate,
    required this.status,
    required this.createdAt,
  });

  factory Vaccine.fromJson(Map<String, dynamic> json) {
    return Vaccine(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      givenDate: json['given_date'] != null ? DateTime.parse(json['given_date']) : null,
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'due_date': dueDate?.toIso8601String(),
      'given_date': givenDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
