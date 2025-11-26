import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/checkpoint_model.dart';

class CheckpointButton extends StatelessWidget {
  final Checkpoint checkpoint;
  final bool isEnabled;
  final bool isCompleted;
  final VoidCallback? onPressed;

  const CheckpointButton({
    super.key,
    required this.checkpoint,
    required this.isEnabled,
    required this.isCompleted,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isEnabled ? onPressed : null,
      icon: Icon(
        Icons.location_on,
        color: isCompleted ? Colors.greenAccent : Colors.white,
      ),
      label: Text(checkpoint.name),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCompleted
            ? Colors.green.withAlpha(8)
            : isEnabled
            ? Colors.blueAccent
            : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
      ),
    );
  }
}
