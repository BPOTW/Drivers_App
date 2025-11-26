import 'package:flutter/material.dart';

import '../widgets/progress_section.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/checkpoint_button.dart';
import '../widgets/status_indicator.dart';
import '../widgets/loading_indicator.dart';
import '../constants/app_constants.dart';
import '../services/dashboard_controller.dart';

class CurrentOrderScreen extends StatefulWidget {
  final String? routeId;

  const CurrentOrderScreen({super.key, this.routeId});

  @override
  State<CurrentOrderScreen> createState() => _CurrentOrderScreenState();
}

class _CurrentOrderScreenState extends State<CurrentOrderScreen> {
  late DashboardController _controller;

   @override
  void initState() {
    super.initState();
    _controller = DashboardController();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _controller.initialize(routeId: widget.routeId);
    if (mounted) {
      _controller.startLocationUpdates();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Order'),
        backgroundColor: Colors.grey[900],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (_controller.isLoading) {
            return LoadingIndicator(
              message: _controller.serverStatus,
            );
          }

          // Show completion message if route is completed
          if (_controller.isRouteCompleted) {
            return _buildCompletionScreen();
          }

          return Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Progress section
                ProgressSection(progress: _controller.progress),
                
                const SizedBox(height: 16),

                // Countdown timer
                CountdownTimer(
                  remainingTime: _controller.remainingTime,
                  showTimer: _controller.currentStep < _controller.checkpoints.length,
                ),

                const SizedBox(height: 20),

                // Checkpoints grid
                Expanded(
                  child: GridView.builder(
                    itemCount: _controller.checkpoints.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.3,
                    ),
                    itemBuilder: (context, index) {
                      final checkpoint = _controller.checkpoints[index];
                      final isEnabled = index == _controller.currentStep;
                      final isCompleted = index < _controller.currentStep;

                      return CheckpointButton(
                        checkpoint: checkpoint,
                        isEnabled: isEnabled,
                        isCompleted: isCompleted,
                        onPressed: () => _controller.saveCheckpoint(index),
                      );
                    },
                  ),
                ),

                // Status indicator
                StatusIndicator(status: _controller.serverStatus),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 120,
              color: Colors.greenAccent,
            ),
            const SizedBox(height: 30),
            Text(
              'Route Completed!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.route != null)
              Text(
                '${_controller.route!.name}',
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 40,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You have successfully completed all checkpoints for this route.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Status indicator
            StatusIndicator(status: _controller.serverStatus),
          ],
        ),
      ),
    );
  }

}