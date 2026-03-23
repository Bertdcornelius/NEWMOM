import 'package:flutter/material.dart';
import 'dart:ui';
import '../premium_ui_components.dart';

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colors = PremiumColors(context);
    final isDark = colors.isDark;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 24),
          decoration: BoxDecoration(
            color: isDark ? colors.surface.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: controller,
                      style: PremiumTypography(context).body.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: PremiumTypography(context).body.copyWith(
                          color: colors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: onSend,
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onSend(controller.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
