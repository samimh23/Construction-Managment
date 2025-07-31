import 'package:flutter/material.dart';

class ErrorDisplay extends StatelessWidget {
  final String? errorMessage;

  const ErrorDisplay({
    super.key,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (errorMessage == null || errorMessage!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const Key('error_display'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}