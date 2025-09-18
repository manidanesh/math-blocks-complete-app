import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/kid_profile.dart';
import '../models/problem_attempt.dart';
import '../providers/profile_provider.dart';
import '../services/adaptive_engine.dart';
import '../services/problem_attempt_service.dart';
import '../services/problem_generator.dart';
import '../widgets/interactive_number_bond_widget.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with TickerProviderStateMixin {
  MathProblem? _currentProblem;
  int _currentAttempt = 1;
  int _selectedAnswer = -1;
  bool _showFeedback = false;
  bool _showExplanation = false;
  bool _showNextButton = false;
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.green;
  int _currentLevel = 1;
  bool _isLoading = true;
  
  // Animation controllers
  late AnimationController _feedbackController;
  late AnimationController _bounceController;
  late Animation<double> _feedbackAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _initializeChallenge();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _initializeChallenge() async {
    try {
      final profileAsync = ref.read(profileProvider);
      final profile = profileAsync.value;
      
      if (profile != null) {
        // Start a new session
        await ProblemAttemptService.startSession(profile.id);
        
        // Get adaptive recommendation
        final recommendation = await ProblemAttemptService.getAdaptiveRecommendation(
          childId: profile.id,
          currentLevel: _currentLevel,
        );
        
        _currentLevel = recommendation.recommendedLevel;
        
        // Generate first problem
        _generateNewProblem();
        
        setState(() {
          _isLoading = false;
        });
        
        print('🎯 Challenge initialized for ${profile.name} at level $_currentLevel');
      }
    } catch (e) {
      print('❌ Error initializing challenge: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateNewProblem() {
    final problem = ProblemGenerator.generateProblem(level: _currentLevel);
    setState(() {
      _currentProblem = problem;
      _currentAttempt = 1;
      _selectedAnswer = -1;
      _showFeedback = false;
      _showExplanation = false;
      _showNextButton = false;
    });
    
    print('🧮 New challenge: ${problem.problemText} (Level ${problem.level})');
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == -1 || _currentProblem == null) return;

    final profileAsync = ref.read(profileProvider);
    final profile = profileAsync.value;
    if (profile == null) return;

    final isCorrect = _selectedAnswer == _currentProblem!.correctAnswer;
    final timeSpent = 5.0 + Random().nextDouble() * 10.0; // Simulated time
    
    // Record the attempt
    final attempt = ProblemAttempt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      childId: profile.id,
      problemText: _currentProblem!.problemText,
      operand1: _currentProblem!.operand1,
      operand2: _currentProblem!.operand2,
      operator: _currentProblem!.operator,
      correctAnswer: _currentProblem!.correctAnswer,
      userAnswer: _selectedAnswer,
      isCorrect: isCorrect,
      timestamp: DateTime.now(),
      attemptNumber: _currentAttempt,
      timeSpentSeconds: timeSpent,
      strategy: _currentProblem!.strategy.toString(),
      difficultyLevel: _currentProblem!.level,
      skillArea: 'addition_level_${_currentProblem!.level}',
      usedHint: false, // TODO: Implement hint system
      explanation: isCorrect ? null : _currentProblem!.explanation,
    );
    
    await ProblemAttemptService.recordAttempt(attempt);

    if (isCorrect) {
      // Correct answer!
      _showSuccessFeedback();
      _updateProfileProgress(profile);
    } else {
      // Wrong answer
      if (_currentAttempt >= 3) {
        // 3rd attempt failed - show explanation and next button
        _showFailureExplanation();
      } else {
        // Still have attempts left
        _showRetryFeedback();
        setState(() {
          _currentAttempt++;
        });
      }
    }
  }

  void _showSuccessFeedback() {
    setState(() {
      _feedbackMessage = _getSuccessMessage();
      _feedbackColor = Colors.green;
      _showFeedback = true;
      _showNextButton = true;
    });
    
    _feedbackController.forward();
    _bounceController.forward().then((_) => _bounceController.reverse());
  }

  void _showRetryFeedback() {
    setState(() {
      _feedbackMessage = _getRetryMessage();
      _feedbackColor = Colors.orange;
      _showFeedback = true;
      _selectedAnswer = -1; // Clear selection
    });
    
    _feedbackController.forward();
    
    // Hide feedback after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _feedbackController.reverse();
        setState(() {
          _showFeedback = false;
        });
      }
    });
  }

  void _showFailureExplanation() {
    setState(() {
      _feedbackMessage = 'Let me show you how to solve this step by step!';
      _feedbackColor = Colors.blue;
      _showFeedback = true;
      _showExplanation = true;
      _showNextButton = true;
    });
    
    _feedbackController.forward();
  }

  String _getSuccessMessage() {
    final messages = [
      'Excellent work! 🌟',
      'Perfect! You got it! 🎉',
      'Amazing! Keep it up! ⭐',
      'Fantastic job! 🏆',
      'You\'re a math star! ✨',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  String _getRetryMessage() {
    final messages = [
      'Not quite right. Try again! 💪',
      'Close! Give it another try! 🤔',
      'Think about it and try once more! 💭',
      'You can do it! Try again! 🎯',
    ];
    return messages[Random().nextInt(messages.length)];
  }

  void _updateProfileProgress(KidProfile profile) {
    // Update profile with new star and problem completion
    final updatedProfile = profile.copyWith(
      totalStars: profile.totalStars + 1,
      totalProblemsCompleted: profile.totalProblemsCompleted + 1,
      lastPlayed: DateTime.now(),
    );
    
    ref.read(profileProvider.notifier).updateProfile(updatedProfile);
  }

  void _nextChallenge() {
    _feedbackController.reset();
    _generateNewProblem();
  }

  void _showHint() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💡 Hint'),
        content: Text(_getHintMessage()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  String _getHintMessage() {
    if (_currentProblem == null) return 'Think step by step!';
    
    switch (_currentProblem!.strategy) {
      case ProblemStrategy.makeTen:
        return 'Try making 10 first! What number goes with ${_currentProblem!.operand1} to make 10?';
      case ProblemStrategy.crossing:
        return 'Break down the bigger number! Think about tens and ones.';
      case ProblemStrategy.basic:
        return 'Count up from the bigger number!';
      default:
        return 'Use your favorite strategy: counting, making 10, or breaking numbers apart!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Challenge'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showHint,
            tooltip: 'Get a hint',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              ElevatedButton(
                onPressed: () => context.go('/profile-creation'),
                child: const Text('Back to Profile'),
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
                  ElevatedButton(
                    onPressed: () => context.go('/profile-creation'),
                    child: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header with profile info
                _buildHeader(profile),
                const SizedBox(height: 24),
                
                // Current problem display
                if (_currentProblem != null) ...[
                  _buildProblemCard(),
                  const SizedBox(height: 24),
                  
                  // Number bond visualization
                  _buildNumberBondVisualization(),
                  const SizedBox(height: 24),
                  
                  // Answer options
                  if (!_showExplanation) _buildAnswerOptions(),
                  const SizedBox(height: 24),
                  
                  // Explanation section (after 3 failures)
                  if (_showExplanation) _buildExplanationSection(),
                  
                  // Feedback section
                  if (_showFeedback) _buildFeedbackSection(),
                  
                  // Action buttons
                  _buildActionButtons(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(KidProfile profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.green[100],
              child: Text(
                profile.name[0].toUpperCase(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level $_currentLevel Challenge',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${profile.name} • ${profile.totalStars} ⭐ • Attempt $_currentAttempt/3',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemCard() {
    return Card(
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Solve this problem:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Text(
                    _currentProblem!.problemText,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberBondVisualization() {
    if (_currentProblem == null) return const SizedBox();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Interactive Number Bond',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            InteractiveNumberBondWidget(
              operand1: _currentProblem!.operand1,
              operand2: _currentProblem!.operand2,
              strategy: _currentProblem!.strategy,
              showSolution: _showExplanation,
              onBondComplete: () {
                // Give positive feedback when bond is completed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Great! You built the number bond correctly!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choose your answer:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _currentProblem!.options.length,
              itemBuilder: (context, index) {
                final option = _currentProblem!.options[index];
                final isSelected = _selectedAnswer == option;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAnswer = option;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[600] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        option.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationSection() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Step-by-Step Solution',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problem: ${_currentProblem!.problemText}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Correct Answer: ${_currentProblem!.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'How to solve it:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentProblem!.explanation,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return AnimatedBuilder(
      animation: _feedbackAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackAnimation.value,
          child: Opacity(
            opacity: _feedbackAnimation.value,
            child: Card(
              elevation: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _feedbackColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _feedbackColor, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackColor == Colors.green ? Icons.check_circle : Icons.info,
                      color: _feedbackColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _feedbackMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _feedbackColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_showNextButton && !_showExplanation)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedAnswer != -1 ? _submitAnswer : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedAnswer != -1 ? 'Submit Answer' : 'Select an answer first',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        
        if (_showNextButton)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next Challenge',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        
        const SizedBox(height: 12),
        
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/mode-select'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
