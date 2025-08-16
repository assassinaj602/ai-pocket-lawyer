import 'package:flutter/material.dart';

class VoiceInputButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final bool enabled;

  const VoiceInputButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isListening
                  ? Colors.red
                  : enabled
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
          boxShadow:
              isListening
                  ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                  : null,
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
