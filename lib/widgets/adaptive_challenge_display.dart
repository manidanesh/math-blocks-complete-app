import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/adaptive_challenge.dart';
import '../providers/profile_provider.dart';
import '../services/language_service.dart';

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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Level button on top
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getLevelColor(challenge.level),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(profileProvider).value;
                      final language = profile?.language ?? 'en';
                      
                      return Text(
                        '${LanguageService.translate('level', language)} ${challenge.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Challenge below
                Expanded(
                  child: _NumberBondFormat(challenge: challenge),
                ),
              ],
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
    return LanguageService.translate(key, language);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                _getText('performance_overview'),
                style: TextStyle(
                  fontSize: isLandscape ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Metrics in simple responsive grid
              _buildSimpleMetricsGrid(isLandscape),
              
              const SizedBox(height: 16),
              
              // Level performance
              if (metrics.levelAccuracy.isNotEmpty)
                _buildSimpleLevelPerformance(isLandscape),
            ],
          ),
        ),
      ),
    );
  }


  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSimpleMetricsGrid(bool isLandscape) {
    final metrics = [
      {
        'label': _getText('recent_accuracy'),
        'value': '${(this.metrics.accuracy * 100).toStringAsFixed(1)}%',
        'color': _getAccuracyColor(this.metrics.accuracy),
        'icon': Icons.track_changes,
      },
      {
        'label': _getText('average_time'),
        'value': '${this.metrics.averageTime.toStringAsFixed(1)}s',
        'color': Colors.blue,
        'icon': Icons.timer,
      },
      {
        'label': _getText('consecutive_incorrect'),
        'value': this.metrics.consecutiveIncorrect.toString(),
        'color': this.metrics.consecutiveIncorrect > 1 ? Colors.red : Colors.green,
        'icon': Icons.warning,
      },
    ];

    if (isLandscape) {
      // In landscape, use 2 columns
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSimpleMetricCard(metrics[0], isLandscape)),
              const SizedBox(width: 8),
              Expanded(child: _buildSimpleMetricCard(metrics[1], isLandscape)),
            ],
          ),
          const SizedBox(height: 8),
          _buildSimpleMetricCard(metrics[2], isLandscape),
        ],
      );
    } else {
      // In portrait, stack vertically
      return Column(
        children: metrics.map((metric) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildSimpleMetricCard(metric, isLandscape),
          )
        ).toList(),
      );
    }
  }

  Widget _buildSimpleMetricCard(Map<String, dynamic> metric, bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label row
          Row(
            children: [
              Icon(
                metric['icon'], 
                color: metric['color'], 
                size: isLandscape ? 14 : 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  metric['label'],
                  style: TextStyle(
                    fontSize: isLandscape ? 10 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Value
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (metric['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              metric['value'],
              style: TextStyle(
                fontSize: isLandscape ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: metric['color'],
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleLevelPerformance(bool isLandscape) {
    return Container(
      padding: EdgeInsets.all(isLandscape ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getText('level_performance'),
            style: TextStyle(
              fontSize: isLandscape ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3498DB),
            ),
          ),
          const SizedBox(height: 8),
          ...metrics.levelAccuracy.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_getText('level')} ${entry.key}',
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: isLandscape ? 10 : 12,
                          fontWeight: FontWeight.bold,
                          color: _getAccuracyColor(entry.value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: entry.value,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getAccuracyColor(entry.value),
                    ),
                    minHeight: isLandscape ? 3 : 5,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

}

/// Separate widget for displaying number bond decomposition format
class _NumberBondFormat extends StatelessWidget {
  final AdaptiveChallenge challenge;

  const _NumberBondFormat({
    required this.challenge,
  });

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse the problem text to extract operands and operator
    final problemText = challenge.problemText;
    print('🔍 _NumberBondFormat - problemText: $problemText');
    
    // Handle different formats: "11 - 9 = ?" or "8 + 9 = ?"
    final RegExp regex = RegExp(r'(\d+)\s*([+\-])\s*(\d+)\s*=\s*\?');
    final match = regex.firstMatch(problemText);
    
    if (match != null) {
      final int operand1 = int.parse(match.group(1)!);
      final String operator = match.group(2)!;
      final int operand2 = int.parse(match.group(3)!);
      
      if (operator == '-') {
        // Subtraction: A - B = A - [__] - [__]
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$operand1',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' - ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '$operand2',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '$operand1',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' - ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Flexible(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: const Center(
                          child: Text(
                            '__',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(' - ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Flexible(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: const Center(
                          child: Text(
                            '__',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      } else {
        // Addition: A + B = A + [__] + [__]
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$operand1',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' + ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '$operand2',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '$operand1',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Text(' + ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Flexible(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: const Center(
                          child: Text(
                            '__',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(' + ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Flexible(
                      child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        child: const Center(
                          child: Text(
                            '__',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }
    
    // Fallback to original text if parsing fails
    return Text(
      problemText,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
