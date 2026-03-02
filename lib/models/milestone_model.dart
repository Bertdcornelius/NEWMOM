class Milestone {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;

  Milestone({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.notes,
    this.imageUrl,
    required this.createdAt,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'date': date.toIso8601String(),
      'notes': notes,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
