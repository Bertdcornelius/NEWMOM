class MomNote {
  final String id;
  final String userId;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;

  MomNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
  });

  factory MomNote.fromJson(Map<String, dynamic> json) {
    return MomNote(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      content: json['content'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
