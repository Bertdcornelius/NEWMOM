import 'package:flutter/material.dart';
import '../premium_ui_components.dart';

class ChatMessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isTyping;

  const ChatMessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTyping) {
      return _buildTypingIndicator(context);
    }

    final colors = PremiumColors(context);
    final isDark = colors.isDark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, val, child) => Transform.translate(
        offset: Offset(isUser ? 20 * (1 - val) : -20 * (1 - val), 0),
        child: Opacity(opacity: val, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildBotAvatar(),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: _bubbleDecoration(isUser, isDark, colors),
                child: Text(
                  text,
                  style: PremiumTypography(context).body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isUser ? Colors.white : colors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
      ),
    );
  }

  BoxDecoration _bubbleDecoration(bool isUser, bool isDark, PremiumColors colors) {
    return BoxDecoration(
      gradient: isUser ? const LinearGradient(colors: [Color(0xFF5BA692), Color(0xFF4ACCA1)]) : null,
      color: isUser ? null : (isDark ? colors.surface : Colors.white),
      border: (!isUser) ? Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)) : null,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: Radius.circular(isUser ? 20 : 4),
        bottomRight: Radius.circular(isUser ? 4 : 20),
      ),
      boxShadow: [
        BoxShadow(
          color: isUser ? const Color(0xFF5BA692).withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colors = PremiumColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _buildBotAvatar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.isDark ? colors.surface : const Color(0xFFF2F3F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0, colors),
                const SizedBox(width: 4),
                _buildDot(1, colors),
                const SizedBox(width: 4),
                _buildDot(2, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, PremiumColors colors) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: colors.textMuted.withValues(alpha: 0.4 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
