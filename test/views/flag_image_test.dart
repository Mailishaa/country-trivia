import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:country_trivia/views/widgets/flag_image.dart';

void main() {
  group('FlagImage', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlagImage(url: 'https://flagcdn.com/w320/us.png'),
          ),
        ),
      );

      // Should show placeholder or image (not crash)
      expect(find.byType(FlagImage), findsOneWidget);
    });

    testWidgets('accepts custom dimensions', (tester) async {
      const widget = FlagImage(
        url: 'https://flagcdn.com/w320/us.png',
        width: 200,
        height: 150,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: widget),
        ),
      );

      expect(find.byType(FlagImage), findsOneWidget);
    });
  });
}
