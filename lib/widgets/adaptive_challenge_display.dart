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
            
            // Motivational message - REMOVED TO ELIMINATE DUPLICATE
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
  final String language;

  const PerformanceMetricsDisplay({
    super.key,
    required this.metrics,
    this.language = 'en',
  });

  String _getText(String key) {
    final translations = {
      'en': {
        'performance_overview': 'Performance Overview',
        'accuracy_last_5': 'Accuracy (Last 5 problems)',
        'average_time': 'Average Time',
        'consecutive_incorrect': 'Consecutive Incorrect',
        'level_performance': 'Level Performance:',
        'level': 'Level',
      },
      'es': {
        'performance_overview': 'Resumen de Rendimiento',
        'accuracy_last_5': 'Precisión (Últimos 5 problemas)',
        'average_time': 'Tiempo Promedio',
        'consecutive_incorrect': 'Incorrectos Consecutivos',
        'level_performance': 'Rendimiento por Nivel:',
        'level': 'Nivel',
      },
      'fr': {
        'performance_overview': 'Aperçu des Performances',
        'accuracy_last_5': 'Précision (5 derniers problèmes)',
        'average_time': 'Temps Moyen',
        'consecutive_incorrect': 'Incorrects Consécutifs',
        'level_performance': 'Performance par Niveau:',
        'level': 'Niveau',
      },
    };
    
    return translations[language]?[key] ?? translations['en']![key]!;
  }

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
            Text(
              _getText('performance_overview'),
              style: const TextStyle(
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
