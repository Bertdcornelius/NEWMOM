import 'package:intl/intl.dart';

/// Shared utility helpers used across dashboard, explore, and other screens.

/// Parse a UTC date string, appending 'Z' if not present.
DateTime parseUtc(String dateStr) {
  if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
    return DateTime.parse('${dateStr}Z');
  }
  return DateTime.parse(dateStr);
}

/// Format a date as a human-readable "X ago" string.
String formatTimeAgo(dynamic dateStr) {
  if (dateStr == null) return "None";
  try {
    final date = (dateStr is String ? DateTime.parse(dateStr) : (dateStr as DateTime)).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds.abs() < 60) return "Just now";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "Just now";
  } catch (e) {
    return "Unknown";
  }
}

/// Format a Duration as "Xh Ym" or "Ym".
String formatDurationSimple(Duration d) {
  if (d.inHours > 0) return "${d.inHours}h ${d.inMinutes.remainder(60)}m";
  return "${d.inMinutes}m";
}

/// Format a DateTime to a readable time string "h:mm a".
String formatReadableTime(DateTime dt) {
  return DateFormat('h:mm a').format(dt);
}
