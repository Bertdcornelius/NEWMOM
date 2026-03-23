import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:new_mom_tracker/widgets/ai/chat_input_area.dart';

void main() {
  group('ChatInputArea Widget Tests', () {
    testWidgets('renders input field and sends message', (WidgetTester tester) async {
      String? sentMessage;
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatInputArea(
              controller: controller,
              onSend: (message) {
                sentMessage = message;
              },
            ),
          ),
        ),
      );

      // Verify the text field exists
      expect(find.byType(TextField), findsOneWidget);

      // Verify the send button exists (Icon.send)
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test question');
      await tester.pumpAndSettle();

      // Tap send
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Verify callback was triggered with the correct text
      expect(sentMessage, 'Test question');
    });
  });
}
