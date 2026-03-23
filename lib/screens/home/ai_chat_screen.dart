import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../widgets/premium_ui_components.dart';
import '../../widgets/ai/chat_message_bubble.dart';
import '../../widgets/ai/chat_input_area.dart';
import 'package:provider/provider.dart';
import '../../repositories/feeding_repository.dart';
import '../../repositories/sleep_repository.dart';
import '../../repositories/care_repository.dart';
import 'package:intl/intl.dart';

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final AIService _aiService = AIService();
  bool _isTyping = false;

  String _contextData = "";

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
    
    // Fetch context data behind the scenes
    _buildContextData();
  }

  Future<void> _buildContextData() async {
    try {
      final fRepo = context.read<FeedingRepository>();
      final sRepo = context.read<SleepRepository>();
      final cRepo = context.read<CareRepository>();
      
      final buffer = StringBuffer();
      final now = DateTime.now();
      buffer.writeln("Current User Time: ${DateFormat('yyyy-MM-dd h:mm a').format(now)}");
      
      final feedsRes = await fRepo.getFeeds(limit: 3);
      if (feedsRes.isSuccess && (feedsRes.data?.isNotEmpty ?? false)) {
          buffer.writeln("\nRecent Feeds:");
          for (var f in feedsRes.data!) {
             final d = DateTime.tryParse(f['created_at']?.toString() ?? '');
             final dStr = d != null ? DateFormat('h:mm a').format(d.toLocal()) : 'unknown';
             buffer.writeln("- ${f['type']} feed (${f['amount_ml']}ml / ${f['duration_min']}m) at $dStr");
          }
      }
      
      final sleepsRes = await sRepo.getSleepLogs(limit: 3);
      if (sleepsRes.isSuccess && (sleepsRes.data?.isNotEmpty ?? false)) {
          buffer.writeln("\nRecent Sleep:");
          for (var s in sleepsRes.data!) {
             final st = DateTime.tryParse(s['start_time']?.toString() ?? '');
             final en = DateTime.tryParse(s['end_time']?.toString() ?? '');
             final stStr = st != null ? DateFormat('h:mm a').format(st.toLocal()) : 'unknown';
             final enStr = en != null ? DateFormat('h:mm a').format(en.toLocal()) : 'Ongoing';
             buffer.writeln("- Slept from $stStr to $enStr");
          }
      }
      
      if (mounted) {
         _contextData = buffer.toString();
      }
    } catch (e) {
      debugPrint("Context build error: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    
    _controller.clear();
    _scrollToBottom();

    final result = await _aiService.sendMessage(text, contextData: _contextData);
    
    setState(() {
      _messages.add(_ChatMessage(
        text: result.isSuccess ? result.data! : result.message!, 
        isUser: false
      ));
      _isTyping = false;
    });
    
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = PremiumColors(context);

    return PremiumScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colors),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Neo AI is not a doctor. Always consult a pediatrician for medical advice.',
                      style: PremiumTypography(context).caption.copyWith(color: colors.isDark ? Colors.amber[200] : Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return const ChatMessageBubble(text: '', isUser: false, isTyping: true);
                  }
                  final msg = _messages[index];
                  return ChatMessageBubble(text: msg.text, isUser: msg.isUser);
                },
              ),
            ),
            if (_messages.length <= 2) _buildQuickChips(colors),
            ChatInputArea(controller: _controller, onSend: _sendMessage),
          ],
        ),
      ),
    );
  }

  // --- Extracted Complex UI Chunk ---
  Widget _buildHeader(PremiumColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          if (Navigator.canPop(context)) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(color: colors.surfaceMuted, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_rounded, color: colors.textPrimary, size: 20),
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF007AFF), Color(0xFF5856D6)]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
                style: PremiumTypography(context).caption.copyWith(color: _isTyping ? const Color(0xFF007AFF) : null),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _showSuggestions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: colors.surfaceMuted, borderRadius: BorderRadius.circular(20)),
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
    );
  }

  void _showSuggestions() {
    final colors = PremiumColors(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: colors.textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Quick Questions', style: PremiumTypography(context).h2),
            const SizedBox(height: 16),
            _buildSuggestionTile('How often should I feed my newborn?', Icons.restaurant, colors),
            _buildSuggestionTile('When will my baby start sleeping through the night?', Icons.bedtime, colors),
            _buildSuggestionTile('Tips for colic and fussy babies', Icons.child_care, colors),
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

  Widget _buildQuickChips(PremiumColors colors) {
    return Container(
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
          ],
        ),
      ),
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
          border: Border.all(color: colors.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06)),
        ),
        child: Text(label, style: PremiumTypography(context).body.copyWith(fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
