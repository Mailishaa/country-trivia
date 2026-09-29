import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// Shows visual indicators for remaining attempts.
class AttemptsIndicator extends StatelessWidget {
  final int attemptsUsed;

  const AttemptsIndicator({
    super.key,
    required this.attemptsUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(kMaxAttempts, (index) {
        final isUsed = index < attemptsUsed;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isUsed ? Colors.red : Colors.green,
          ),
        );
      }),
    );
  }
}
