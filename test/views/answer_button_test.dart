import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/views/widgets/answer_button.dart';

void main() {
  group('AnswerButton', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnswerButton(text: 'Test Country'),
          ),
        ),
      );

      expect(find.text('Test Country'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerButton(
              text: 'Test',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerButton(
              text: 'Test',
              onTap: () => tapped = true,
              state: AnswerButtonState.disabled,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(tapped, isFalse);
    });

    testWidgets('correct state enables taps and uses bold text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnswerButton(
              text: 'Correct',
              onTap: () {},
              state: AnswerButtonState.correct,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNotNull);

      final label = tester.widget<Text>(find.text('Correct'));
      expect(label.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('wrong and default states use normal weight text',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AnswerButton(
                  text: 'Wrong',
                  state: AnswerButtonState.wrong,
                ),
                AnswerButton(text: 'Plain'),
              ],
            ),
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('Wrong')).style?.fontWeight,
        FontWeight.normal,
      );
      expect(
        tester.widget<Text>(find.text('Plain')).style?.fontWeight,
        FontWeight.normal,
      );
    });

    testWidgets('revealed state renders bold text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnswerButton(
              text: 'Revealed',
              state: AnswerButtonState.revealed,
            ),
          ),
        ),
      );

      final label = tester.widget<Text>(find.text('Revealed'));
      expect(label.style?.fontWeight, FontWeight.bold);
    });
  });
}
