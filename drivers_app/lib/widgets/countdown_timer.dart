import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/app_utils.dart';

class CountdownTimer extends StatelessWidget {
  final Duration remainingTime;
  final bool showTimer;

  const CountdownTimer({
    super.key,
    required this.remainingTime,
    this.showTimer = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showTimer) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.tealAccent.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "⏰ Remaining Time",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            AppUtils.formatDuration(remainingTime),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.tealAccent,
            ),
          ),
        ],
      ),
    );
  }
}
