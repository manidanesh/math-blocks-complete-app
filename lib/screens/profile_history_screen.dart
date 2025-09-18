import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/kid_profile.dart';
import '../models/problem_attempt.dart';
import '../providers/profile_provider.dart';
import '../services/problem_attempt_service.dart';
import '../widgets/language_selector.dart';

class ProfileHistoryScreen extends ConsumerStatefulWidget {
  const ProfileHistoryScreen({super.key});

  @override
  ConsumerState<ProfileHistoryScreen> createState() => _ProfileHistoryScreenState();
}

class _ProfileHistoryScreenState extends ConsumerState<ProfileHistoryScreen> {
  List<ProblemAttempt> _failedAttempts = [];
  Map<String, dynamic> _performanceSummary = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileAsync = ref.read(profileProvider);
      final profile = profileAsync.value;
      
      if (profile != null) {
        // Load failed attempts for failure transaction history
        final failedAttempts = await ProblemAttemptService.getFailedAttempts(profile.id);
        
        // Load performance summary
        final summary = await ProblemAttemptService.getPerformanceSummary(profile.id);
        
        setState(() {
          _failedAttempts = failedAttempts;
          _performanceSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/profile-creation'),
                child: const Text('Back to Profile Creation'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No profile found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/profile-creation'),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(profile),
                const SizedBox(height: 24),
                
                // Language Settings
                _buildLanguageSection(profile),
                const SizedBox(height: 24),
                
                // Performance Summary
                _buildPerformanceSummary(),
                const SizedBox(height: 24),
                
                // Failure Transaction History
                _buildFailureHistory(),
                const SizedBox(height: 24),
                
                // Action Buttons
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(KidProfile profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Age: ${profile.age}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Language: ${_getLanguageName(profile.language)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Stars: ${profile.totalStars}',
                    style: const TextStyle(fontSize: 16, color: Colors.amber),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(KidProfile profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change your preferred language:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            LanguageSelector(
              selectedLanguageCode: profile.language,
              onLanguageSelected: (newLanguage) async {
                // Update profile language
                final updatedProfile = profile.copyWith(language: newLanguage);
                await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
                
                // Show confirmation
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Language changed to ${_getLanguageName(newLanguage)}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatRow('Total Problems', '${_performanceSummary['totalProblems'] ?? 0}'),
              _buildStatRow('Accuracy', '${((_performanceSummary['accuracy'] ?? 0.0) * 100).toStringAsFixed(1)}%'),
              _buildStatRow('Current Streak', '${_performanceSummary['streak'] ?? 0}'),
              _buildStatRow('Average Time', '${(_performanceSummary['averageTime'] ?? 0.0).toStringAsFixed(1)}s'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureHistory() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Failure Transaction History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_failedAttempts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.celebration, size: 64, color: Colors.green),
                      SizedBox(height: 8),
                      Text(
                        'No failures yet!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Keep up the great work!'),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _failedAttempts.length,
                itemBuilder: (context, index) {
                  final attempt = _failedAttempts[index];
                  return _buildFailureCard(attempt, index + 1);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureCard(ProblemAttempt attempt, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        title: Text(
          '${attempt.problemText} = ${attempt.userAnswer}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Attempt #$index • ${_formatDate(attempt.timestamp)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        leading: const Icon(Icons.error, color: Colors.red),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Correct Answer: ${attempt.correctAnswer}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your Answer: ${attempt.userAnswer}',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time Spent: ${attempt.timeSpentSeconds.toStringAsFixed(1)} seconds',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                if (attempt.usedHint)
                  const Text(
                    'Hint was used',
                    style: TextStyle(fontSize: 14, color: Colors.orange),
                  ),
                const SizedBox(height: 12),
                if (attempt.explanation?.isNotEmpty == true) ...[
                  const Text(
                    'Explanation:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      attempt.explanation ?? '',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/practice'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Continue Practice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/mode-select'),
            icon: const Icon(Icons.home),
            label: const Text('Back to Home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showClearDataDialog(),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Clear All Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your progress, including:\n'
          '• All problem attempts\n'
          '• Performance history\n'
          '• Failure transactions\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ProblemAttemptService.clearAllAttempts();
              await _loadProfileData(); // Reload data
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      default:
        return 'English';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}