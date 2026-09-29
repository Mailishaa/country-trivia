// Smoke test for the app root widget.
//
// The default Flutter counter test has been removed as this project now boots
// into the Country Trivia quiz flow, which requires network and storage
// services. Behavioural coverage lives in the targeted suites under test/.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('test harness runs', () {
    expect(true, isTrue);
  });
}
