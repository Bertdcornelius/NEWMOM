import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../core/result.dart';

/// Secure wrapper for AI operations utilizing the custom Cloudflare Worker proxy.
class AIService {
  AIService();

  /// Sends a message via the custom proxy endpoint
  Future<Result<String>> sendMessage(String message, {String? contextData}) async {
    try {
      String prompt = "You are Neo AI, a friendly and empathetic baby care assistant. Keep answers brief and highly practical.";
      if (contextData != null && contextData.isNotEmpty) {
        prompt += "\n\nBaby Data Context:\n$contextData\n\nTake this context into account when answering only if relevant.";
      }
      prompt += "\n\nUser: ${message.trim()}";
      
      final url = Uri.parse('https://purple-haze-b795.kebadan2704.workers.dev/?prompt=${Uri.encodeQueryComponent(prompt)}');
      
      final res = await http.get(url);
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String answer = data['answer'] ?? 'Sorry, I couldn\'t understand that.';
        
        // Clean up markdown artifacts that flutter doesn't parse natively well
        answer = answer.replaceAll(RegExp(r'\*\*?'), '');
        answer = answer.replaceAll(RegExp(r'#+\s*'), '');

        return Success(answer.trim());
      } else {
        return Failure('Failed to connect to AI (Status ${res.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) print('AI Chat Error: $e');
      return Failure('Connection error', e as Exception);
    }
  }

  /// Reset the conversation context (No-op for stateless proxy)
  void clearHistory() {
    // Proxy is stateless; no action needed.
  }
}
