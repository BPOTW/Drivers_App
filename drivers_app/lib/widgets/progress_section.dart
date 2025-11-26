import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class ProgressSection extends StatelessWidget {
  final double progress;

  const ProgressSection({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Progress',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: AppConstants.progressBarHeight,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(
              Colors.tealAccent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('Progress: ${(progress * 100).toStringAsFixed(0)}%'),
      ],
    );
  }
}
