import 'package:flutter/material.dart';

/// A button for answering trivia questions with color-coded feedback.
class AnswerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final AnswerButtonState state;

  const AnswerButton({
    super.key,
    required this.text,
    this.onTap,
    this.state = AnswerButtonState.defaultState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (state) {
      case AnswerButtonState.correct:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        borderColor = Colors.green;
      case AnswerButtonState.wrong:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        borderColor = Colors.red;
      case AnswerButtonState.revealed:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        borderColor = Colors.green;
      case AnswerButtonState.disabled:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade600;
        borderColor = Colors.grey.shade400;
      case AnswerButtonState.defaultState:
        backgroundColor = theme.colorScheme.surface;
        textColor = theme.colorScheme.onSurface;
        borderColor = theme.colorScheme.outline;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state == AnswerButtonState.disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: state == AnswerButtonState.correct ||
                    state == AnswerButtonState.revealed
                ? FontWeight.bold
                : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Visual states for [AnswerButton].
enum AnswerButtonState {
  defaultState,
  correct,
  wrong,
  revealed,
  disabled,
}
