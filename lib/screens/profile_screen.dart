import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/kid_profile.dart';
import '../models/problem_attempt.dart';
import '../providers/profile_provider.dart';
import '../services/problem_attempt_service.dart';
import '../widgets/favorite_numbers_selector.dart';
import '../widgets/language_selector.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<ProblemAttempt> _failedAttempts = [];
  Map<String, dynamic> _performanceSummary = {};
  List<int> _tempFavoriteNumbers = [];
  bool _isLoading = true;
  bool _isEditing = false;
  String _tempLanguage = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileAsync = ref.read(profileProvider);
      if (profileAsync.value != null) {
        await _loadPerformanceData(profileAsync.value!.id);
        setState(() {
          _tempFavoriteNumbers = List.from(profileAsync.value!.favoriteNumbers);
          _tempLanguage = profileAsync.value!.language;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPerformanceData(String profileId) async {
    try {
      final attempts = await ProblemAttemptService.getAttemptsForChild(profileId);
      _failedAttempts = await ProblemAttemptService.getUniqueFailedAttempts(profileId);
      
      // Debug information
      print('🔍 Profile Data Debug:');
      print('  Total attempts: ${attempts.length}');
      print('  Failed attempts: ${_failedAttempts.length}');
      print('  Correct attempts: ${attempts.where((a) => a.isCorrect).length}');
      
      // Calculate performance summary
      _performanceSummary = _calculatePerformanceSummary(attempts);
    } catch (e) {
      print('Error loading performance data: $e');
    }
  }

  Map<String, dynamic> _calculatePerformanceSummary(List<ProblemAttempt> attempts) {
    if (attempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'correctAttempts': 0,
        'accuracy': 0.0,
        'averageTime': 0.0,
        'mostStruggledStrategy': 'None',
        'strengths': <String>[],
        'improvements': <String>[],
      };
    }

    final correctAttempts = attempts.where((a) => a.isCorrect).length;
    final accuracy = correctAttempts / attempts.length;
    final averageTime = attempts.map((a) => a.timeSpentSeconds).reduce((a, b) => a + b) / attempts.length;

    // Analyze by strategy
    final strategyPerformance = <String, List<ProblemAttempt>>{};
    for (final attempt in attempts) {
      strategyPerformance.putIfAbsent(attempt.strategy.toString(), () => []).add(attempt);
    }

    String mostStruggledStrategy = 'None';
    double lowestAccuracy = 1.0;
    final strengths = <String>[];
    final improvements = <String>[];

    for (final entry in strategyPerformance.entries) {
      final strategyAttempts = entry.value;
      final strategyAccuracy = strategyAttempts.where((a) => a.isCorrect).length / strategyAttempts.length;
      
      if (strategyAccuracy < lowestAccuracy) {
        lowestAccuracy = strategyAccuracy;
        mostStruggledStrategy = entry.key;
      }

      if (strategyAccuracy >= 0.8) {
        strengths.add(entry.key);
      } else if (strategyAccuracy < 0.6) {
        improvements.add(entry.key);
      }
    }

    return {
      'totalAttempts': attempts.length,
      'correctAttempts': correctAttempts,
      'accuracy': accuracy,
      'averageTime': averageTime,
      'mostStruggledStrategy': mostStruggledStrategy,
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Reset to original values
      final profile = ref.read(profileProvider).value;
      _tempFavoriteNumbers = List.from(profile?.favoriteNumbers ?? []);
    });
  }


  Future<void> _saveChanges() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      favoriteNumbers: _tempFavoriteNumbers,
    );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
    
    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Favorite numbers updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${profile.name}\'s Profile'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Age: ${profile.age}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Language: ${profile.language.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            '⭐ Stars',
                            profile.totalStars.toString(),
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '🎯 Problems',
                            profile.totalProblemsCompleted.toString(),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            '📊 Accuracy',
                            '${(profile.overallAccuracy * 100).toInt()}%',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Language Settings Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌍 Language Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    LanguageSelector(
                      selectedLanguageCode: _tempLanguage,
                      onLanguageSelected: (languageCode) async {
                        setState(() {
                          _tempLanguage = languageCode;
                        });
                        // Save immediately when language is selected
                        final profile = ref.read(profileProvider).value;
                        if (profile != null) {
                          final updatedProfile = profile.copyWith(language: languageCode);
                          await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Language updated successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Performance Summary Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📈 Performance Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_performanceSummary['totalAttempts'] > 0) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Attempts',
                              _performanceSummary['totalAttempts'].toString(),
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Correct',
                              _performanceSummary['correctAttempts'].toString(),
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Accuracy',
                              '${(_performanceSummary['accuracy'] * 100).toInt()}%',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Avg Time',
                              '${_performanceSummary['averageTime'].toStringAsFixed(1)}s',
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Strengths and Improvements
                      if (_performanceSummary['strengths'].isNotEmpty) ...[
                        _buildPerformanceSection(
                          '🌟 Strengths',
                          _performanceSummary['strengths'],
                          Colors.green,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (_performanceSummary['improvements'].isNotEmpty) ...[
                        _buildPerformanceSection(
                          '💪 Areas to Improve',
                          _performanceSummary['improvements'],
                          Colors.orange,
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      if (_performanceSummary['mostStruggledStrategy'] != 'None') ...[
                        _buildPerformanceSection(
                          '🎯 Focus Area',
                          [_performanceSummary['mostStruggledStrategy']],
                          Colors.red,
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No performance data yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start solving math problems to see your progress!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Failed Challenges Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🤔 You want to try one more time?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_failedAttempts.isNotEmpty) ...[
                      Text(
                        'Review these challenges to improve your skills:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Show last 5 failed attempts
                      ...(_failedAttempts.take(5).map((attempt) => _buildFailedChallengeItem(attempt)).toList()),
                      
                      if (_failedAttempts.length > 5) ...[
                        const SizedBox(height: 8),
                        Text(
                          '... and ${_failedAttempts.length - 5} more failed challenges',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.green[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No failed challenges yet!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Great job! Keep up the excellent work!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Favorite Numbers Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '⭐ Favorite Numbers',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditing)
                          TextButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isEditing) ...[
                      FavoriteNumbersSelector(
                        initialFavorites: _tempFavoriteNumbers,
                        onChanged: (numbers) {
                          setState(() {
                            _tempFavoriteNumbers = numbers;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelEditing,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (profile.favoriteNumbers.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.favoriteNumbers.map((number) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text(
                                number.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'These numbers will appear more often in your math problems! 🎯',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No favorite numbers set yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap Edit to choose your favorite numbers!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Back to Home Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/mode-select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(String title, List<String> items, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedChallengeItem(ProblemAttempt attempt) {
    final timeAgo = DateTime.now().difference(attempt.timestamp);
    String timeString;
    
    if (timeAgo.inDays > 0) {
      timeString = '${timeAgo.inDays} day${timeAgo.inDays == 1 ? '' : 's'} ago';
    } else if (timeAgo.inHours > 0) {
      timeString = '${timeAgo.inHours} hour${timeAgo.inHours == 1 ? '' : 's'} ago';
    } else if (timeAgo.inMinutes > 0) {
      timeString = '${timeAgo.inMinutes} minute${timeAgo.inMinutes == 1 ? '' : 's'} ago';
    } else {
      timeString = 'Just now';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to challenge screen with this specific problem for explanation
        context.go('/challenge', extra: {
          'problem': {
            'operand1': attempt.operand1,
            'operand2': attempt.operand2,
            'operator': attempt.operator,
            'correctAnswer': attempt.correctAnswer,
            'strategy': attempt.strategy,
          },
          'showExplanation': true,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.close,
              color: Colors.red[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.problemText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Your answer: ${attempt.userAnswer ?? 'No answer'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
