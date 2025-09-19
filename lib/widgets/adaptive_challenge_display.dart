import 'package:flutter/material.dart';
import '../models/adaptive_challenge.dart';

/// Widget to display adaptive challenge information
class AdaptiveChallengeDisplay extends StatelessWidget {
  final AdaptiveChallenge challenge;

  const AdaptiveChallengeDisplay({
    super.key,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with level and type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLevelColor(challenge.level),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Level ${challenge.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (challenge.isReviewProblem)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'REVIEW',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Spacer(),
                Icon(
                  _getLevelIcon(challenge.level),
                  color: _getLevelColor(challenge.level),
                  size: 24,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Problem text
            Center(
              child: Text(
                challenge.problemText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Bond steps explanation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Number Bond Strategy:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.bondSteps,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ),
            
            // Motivational message
            if (challenge.motivationalMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.green[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        challenge.motivationalMessage!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getLevelIcon(int level) {
    switch (level) {
      case 1:
        return Icons.star;
      case 2:
        return Icons.star_half;
      case 3:
        return Icons.stars;
      case 4:
        return Icons.diamond;
      default:
        return Icons.help_outline;
    }
  }
}

/// Widget to display performance metrics
class PerformanceMetricsDisplay extends StatelessWidget {
  final PerformanceMetrics metrics;

  const PerformanceMetricsDisplay({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Accuracy
            _buildMetricRow(
              'Accuracy (Last 5 problems)',
              '${(metrics.accuracy * 100).toStringAsFixed(1)}%',
              _getAccuracyColor(metrics.accuracy),
              Icons.track_changes,
            ),
            
            const SizedBox(height: 12),
            
            // Average time
            _buildMetricRow(
              'Average Time',
              '${metrics.averageTime.toStringAsFixed(1)}s',
              Colors.blue,
              Icons.timer,
            ),
            
            const SizedBox(height: 12),
            
            // Consecutive incorrect
            _buildMetricRow(
              'Consecutive Incorrect',
              metrics.consecutiveIncorrect.toString(),
              metrics.consecutiveIncorrect > 1 ? Colors.red : Colors.green,
              Icons.warning,
            ),
            
            const SizedBox(height: 16),
            
            // Level accuracy breakdown
            if (metrics.levelAccuracy.isNotEmpty) ...[
              const Text(
                'Level Performance:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...metrics.levelAccuracy.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('Level ${entry.key}: '),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getAccuracyColor(entry.value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(entry.value * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
