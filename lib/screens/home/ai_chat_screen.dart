import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/premium_ui_components.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(_ChatMessage(
      text: "Hi there! 👋 I'm Neo AI, your baby care assistant. Ask me anything about feeding, sleep schedules, milestones, or parenting tips!",
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Build context from the last 5 messages to provide conversational memory
      String promptContext = "You are Neo AI, a baby care assistant. Give brief, helpful answers.\n";
      final recentMessages = _messages.length > 6 ? _messages.sublist(_messages.length - 6) : _messages;
      
      for (var msg in recentMessages) {
        if (msg.text == 'typing...') continue;
        promptContext += "${msg.isUser ? 'User' : 'Neo'}: ${msg.text}\n";
      }
      promptContext += "User: ${text.trim()}\nNeo AI:";

      final uri = Uri.parse(
        'https://purple-haze-b795.kebadan2704.workers.dev/?prompt=${Uri.encodeComponent(promptContext)}',
      );
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String answer = data['answer']?.toString() ?? 'Sorry, I couldn\'t understand that.';
        // Strip out "Neo:" prefix
        answer = answer.replaceAll(RegExp(r'neo( ai)?:?', caseSensitive: false), '');
        // Strip out markdown formatting (asterisks, hashes, etc.)
        answer = answer.replaceAll(RegExp(r'\*\*?'), ''); // Remove * and **
        answer = answer.replaceAll(RegExp(r'#+\s*'), ''); // Remove #, ##, etc.
        answer = answer.trim();
        setState(() {
          _messages.add(_ChatMessage(text: answer, isUser: false));
          _isTyping = false;
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(text: 'Oops! Something went wrong. Please try again.', isUser: false));
          _isTyping = false;
        });
      }
    } catch (e) {
      debugPrint('AI Chat Error: $e');
      setState(() {
        _messages.add(_ChatMessage(text: 'Connection error: ${e.toString()}', isUser: false));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = PremiumColors(context);
    final isDark = colors.isDark;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Neo AI', style: PremiumTypography(context).h2),
                  Text(
                    _isTyping ? 'typing...' : 'Baby Care Assistant',
                    style: PremiumTypography(context).caption.copyWith(
                      color: _isTyping ? const Color(0xFF007AFF) : null,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Suggestion chips
              GestureDetector(
                onTap: () => _showSuggestions(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: colors.softAmber),
                      const SizedBox(width: 4),
                      Text('Tips', style: PremiumTypography(context).caption),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Messages List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isTyping) {
                return _buildTypingIndicator(colors);
              }
              return _buildMessageBubble(_messages[index], colors, isDark);
            },
          ),
        ),

        // Quick Suggestion Chips
        if (_messages.length <= 2)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('🍼 Feeding tips', colors),
                  const SizedBox(width: 8),
                  _buildChip('😴 Sleep schedule', colors),
                  const SizedBox(width: 8),
                  _buildChip('🧸 Milestones', colors),
                  const SizedBox(width: 8),
                  _buildChip('🤱 Postpartum care', colors),
                ],
              ),
            ),
          ),

        // Input Area
        ClipRRect(
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
                          controller: _controller,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: colors.textMuted,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: _sendMessage,
                          textInputAction: TextInputAction.send,
                          maxLines: null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _sendMessage(_controller.text),
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
        ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatMessage message, PremiumColors colors, bool isDark) {
    final isUser = message.isUser;

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
          if (!isUser) ...[
            Container(
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
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: [Color(0xFF5BA692), Color(0xFF4ACCA1)])
                    : null,
                color: isUser
                    ? null
                    : (isDark ? colors.surface : Colors.white),
                border: !isUser
                    ? Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isUser
                        ? const Color(0xFF5BA692).withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isUser
                      ? Colors.white
                      : colors.textPrimary,
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

  Widget _buildTypingIndicator(PremiumColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
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
          const SizedBox(width: 8),
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
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: PremiumColors(context).textMuted.withValues(alpha: 0.4 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, PremiumColors colors) {
    return GestureDetector(
      onTap: () => _sendMessage(label.replaceAll(RegExp(r'[^\w\s]'), '').trim()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colors.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
    );
  }

  void _showSuggestions() {
    final colors = PremiumColors(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text('Quick Questions', style: PremiumTypography(context).h2),
            const SizedBox(height: 16),
            _buildSuggestionTile('How often should I feed my newborn?', Icons.restaurant, colors),
            _buildSuggestionTile('When will my baby start sleeping through the night?', Icons.bedtime, colors),
            _buildSuggestionTile('What are the milestones for a 3-month-old?', Icons.star, colors),
            _buildSuggestionTile('Tips for colic and fussy babies', Icons.child_care, colors),
            _buildSuggestionTile('When should I start solid foods?', Icons.food_bank, colors),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(String text, IconData icon, PremiumColors colors) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: PremiumBubbleIcon(icon: icon, color: colors.sageGreen, size: 18, padding: 8),
      title: Text(text, style: PremiumTypography(context).body.copyWith(color: colors.textPrimary)),
      onTap: () {
        Navigator.pop(context);
        _sendMessage(text);
      },
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}
