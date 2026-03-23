import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mom_tracker/widgets/ai/chat_message_bubble.dart';

void main() {
  group('ChatMessageBubble Widget Tests', () {
    testWidgets('renders user message correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              text: 'How much sleep does a newborn need?',
              isUser: true,
            ),
          ),
        ),
      );

      // Verify the text is present
      expect(find.text('How much sleep does a newborn need?'), findsOneWidget);

    });

    testWidgets('renders AI message with markdown correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatMessageBubble(
              text: '**Newborns** need 14-17 hours of sleep.',
              isUser: false,
            ),
          ),
        ),
      );

      expect(find.text('**Newborns** need 14-17 hours of sleep.'), findsOneWidget);
    });
  });
}
