class Prescription {
  final String id;
  final String userId;
  final String medicineName;
  final String? dosage;
  final String? frequency;
  final String? notes;
  final String? imageUrl;
  final DateTime createdAt;

  Prescription({
    required this.id,
    required this.userId,
    required this.medicineName,
    this.dosage,
    this.frequency,
    this.notes,
    this.imageUrl,
    required this.createdAt,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      userId: json['user_id'],
      medicineName: json['medicine_name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      notes: json['notes'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'frequency': frequency,
      'notes': notes,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
