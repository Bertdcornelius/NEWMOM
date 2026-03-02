import 'package:flutter/material.dart';

class Routine {
  final String id;
  final String userId;
  final String title;
  final TimeOfDay time;
  final bool enabled;
  final DateTime createdAt;

  Routine({
    required this.id,
    required this.userId,
    required this.title,
    required this.time,
    required this.enabled,
    required this.createdAt,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    // Supabase returns time as "HH:MM:SS" string
    final timeParts = (json['time'] as String).split(':');
    final time = TimeOfDay(
      hour: int.parse(timeParts[0]), 
      minute: int.parse(timeParts[1])
    );
    
    return Routine(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      time: time,
      enabled: json['enabled'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    // Format TimeOfDay to HH:MM for backend/storage
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    return {
      'user_id': userId,
      'title': title,
      'time': '$hour:$minute:00',
      'enabled': enabled,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
