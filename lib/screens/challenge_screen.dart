import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/kid_profile.dart';
import '../models/problem_attempt.dart';
import '../models/rewards_model.dart';
import '../providers/profile_provider.dart';
import '../services/adaptive_engine.dart';
import '../services/problem_attempt_service.dart';
import '../services/problem_generator.dart';
import '../services/rewards_service.dart';
import '../widgets/interactive_number_bond_widget.dart';
import '../widgets/rewards_display.dart';
import '../widgets/celebration_animations.dart';
import '../services/language_service.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key});

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen>
    with TickerProviderStateMixin {
  MathProblem? _currentProblem;
  int _currentAttempt = 1;
  bool _showFeedback = false;
  bool _showExplanation = false;
  bool _showNextButton = false;
  String _feedbackMessage = '';
  Color _feedbackColor = Colors.green;
  
  // Rewards system
  ChildRewards? _currentRewards;
  bool _showCelebration = false;
  RewardResult? _lastRewardResult;
  int _currentLevel = 1;
  bool _isLoading = true;
  bool _showNextChallenge = false;
  bool _showRetryChallenge = false;
  bool _showSuccessMessage = false;
  
  // Animation controllers
  late AnimationController _feedbackController;
  late AnimationController _bounceController;
  late AnimationController _successController;
  late Animation<double> _feedbackAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _successAnimation;

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
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _feedbackAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _feedbackController, curve: Curves.easeOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    
    _initializeChallenge();
    _loadRewards();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _bounceController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadRewards() async {
    final profileAsync = ref.read(profileProvider);
    profileAsync.whenData((profile) async {
      if (profile != null) {
        final rewards = await RewardsService.getRewards(profile.id);
        if (mounted) {
          setState(() {
            _currentRewards = rewards;
          });
        }
      }
    });
  }

  Future<void> _nextChallenge() async {
    // Reset state for new challenge
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
      _currentAttempt = 1;
    });
    
    // Generate new problem
    _generateNewProblem();
  }
  
  Future<void> _retryChallenge() async {
    // Reset state for retry
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
      _currentAttempt = 1;
    });
    
    // Keep the same problem but reset the number bond widget
    // The InteractiveNumberBondWidget will reset itself when we rebuild
  }

  Future<void> _awardStar(String childId, String description) async {
    final result = await RewardsService.addStar(
      childId,
      description: description,
      metadata: {
        'problem': _currentProblem?.problemText,
        'attempt': _currentAttempt,
        'level': _currentLevel,
      },
    );
    
    if (mounted && result.success && result.rewards != null) {
      setState(() {
        _currentRewards = result.rewards;
        _lastRewardResult = result;
        
        // Show celebration if there's a new badge, sticker, or level up
        if (result.newBadge != null || result.newSticker != null || result.levelUp) {
          _showCelebration = true;
        }
      });
      
      // Hide celebration after delay
      if (_showCelebration) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showCelebration = false;
            });
          }
        });
      }
    }
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
        
        // Check if we have extra parameters from navigation (from failed challenges)
        final extra = GoRouterState.of(context).extra;
        if (extra is Map<String, dynamic> && extra['problem'] != null) {
          // Load the specific problem from failed challenge
          _loadSpecificProblem(extra['problem'] as Map<String, dynamic>);
          
          // If showExplanation is true, show the explanation immediately
          if (extra['showExplanation'] == true) {
            setState(() {
              _showExplanation = true;
            });
          }
        } else {
          // Generate first problem normally
          _generateNewProblem();
        }
        
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
    final profile = ref.read(profileProvider).value;
    final favoriteNumbers = profile?.favoriteNumbers ?? [];
    final problem = ProblemGenerator.generateProblem(
      level: _currentLevel,
      favoriteNumbers: favoriteNumbers,
    );
    setState(() {
      _currentProblem = problem;
      _currentAttempt = 1;
      _showFeedback = false;
      _showExplanation = false;
      _showNextButton = false;
    });
    
    print('🧮 New challenge: ${problem.problemText} (Level ${problem.level})');
  }

  void _loadSpecificProblem(Map<String, dynamic> problemData) {
    final problem = MathProblem(
      operand1: problemData['operand1'] as int,
      operand2: problemData['operand2'] as int,
      operator: problemData['operator'] as String,
      correctAnswer: problemData['correctAnswer'] as int,
      problemText: '${problemData['operand1']} + ${problemData['operand2']} = ?',
      options: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], // Default options
      strategy: ProblemStrategy.values.firstWhere(
        (s) => s.toString().split('.').last == problemData['strategy'],
        orElse: () => ProblemStrategy.basic,
      ),
      level: _currentLevel,
      explanation: 'This is a practice problem from your failed challenges.',
    );
    
    setState(() {
      _currentProblem = problem;
      _currentAttempt = 1;
      _showFeedback = false;
      _showExplanation = false;
      _showNextButton = false;
    });
    
    print('🧮 Loaded specific problem: ${problem.problemText}');
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
 // Clear selection
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
    final currentLanguage = profileAsync.value?.language ?? 'en';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('math_challenge'.tr(currentLanguage)),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
          tooltip: 'back_to_home'.tr(currentLanguage),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showHint,
            tooltip: 'get_hint'.tr(currentLanguage),
          ),
          // Language flag in app bar
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text(
                LanguageService.getFlag(currentLanguage),
                style: const TextStyle(fontSize: 24),
              ),
            ),
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

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                  // Header with profile info
                  _buildHeader(profile),
                  const SizedBox(height: 24),
                  
                  // Current problem display
                  if (_currentProblem != null) ...[
                    _buildProblemCard(currentLanguage),
                    const SizedBox(height: 24),
                    
                    // Number bond visualization
                    _buildNumberBondVisualization(),
                    const SizedBox(height: 24),
                    
                    const SizedBox(height: 24),
                    
                    // Explanation section (after 3 failures)
                    if (_showExplanation) _buildExplanationSection(),
                    
                    // Feedback section
                    if (_showFeedback) _buildFeedbackSection(),
                    
                    // Challenge completion buttons
                    if (_showNextChallenge || _showRetryChallenge) ...[
                      const SizedBox(height: 24),
                      _buildChallengeCompletionButtons(),
                    ],
                  ],
                ],
              ),
            ),
            
            // Beautiful success message overlay
            if (_showSuccessMessage) _buildSuccessOverlay(),
          ],
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
                    'level_challenge'.tr(profile.language, params: {'level': _currentLevel.toString()}),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${profile.name} • Attempt $_currentAttempt/3',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (_currentRewards != null) ...[
                    const SizedBox(height: 4),
                    CompactRewardsDisplay(rewards: _currentRewards!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProblemCard(String language) {
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
            Text(
              'Solve this problem:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _bounceAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnimation.value,
                  child: Text(
                    '${_currentProblem!.operand1} + ${_currentProblem!.operand2} = ?',
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
              key: ValueKey('${_currentProblem!.operand1}_${_currentProblem!.operand2}_$_currentAttempt'),
              operand1: _currentProblem!.operand1,
              operand2: _currentProblem!.operand2,
              strategy: _currentProblem!.strategy,
              showSolution: _showExplanation,
              onBondComplete: (bool isCorrect) async {
                final profile = ref.read(profileProvider).value;
                if (profile != null && _currentProblem != null) {
                  // Record the problem attempt
                  final attempt = ProblemAttempt(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    childId: profile.id,
                    problemText: '${_currentProblem!.operand1} + ${_currentProblem!.operand2} = ?',
                    operand1: _currentProblem!.operand1,
                    operand2: _currentProblem!.operand2,
                    operator: '+',
                    correctAnswer: _currentProblem!.operand1 + _currentProblem!.operand2,
                    userAnswer: null, // We don't track the exact user answer in number bonds
                    isCorrect: isCorrect,
                    timestamp: DateTime.now(),
                    attemptNumber: _currentAttempt,
                    timeSpentSeconds: 30.0, // Estimated time spent
                    strategy: _currentProblem!.strategy.toString(),
                    difficultyLevel: _currentProblem!.level,
                    skillArea: 'number_bonds_${_currentProblem!.strategy.toString()}',
                    usedHint: false,
                    hintType: null,
                    explanation: isCorrect ? 'Correct number bond completion' : 'Failed after 3 attempts',
                  );
                  
                  await ProblemAttemptService.recordAttempt(attempt);
                }
                
                if (isCorrect) {
                  // Award star for correct answer
                  if (profile != null) {
                    await _awardStar(profile.id, 'Correct number bond completion');
                    
                    // Show beautiful success message
                    setState(() {
                      _showSuccessMessage = true;
                    });
                    
                    // Start success animation
                    _successController.forward();
                    
                    // Hide success message and show next challenge button after animation
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() {
                          _showSuccessMessage = false;
                          _showNextChallenge = true;
                        });
                        _successController.reset();
                      }
                    });
                  }
                } else {
                  // Show feedback for incorrect after 3 attempts
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('💪 Keep trying! You can do it!'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  // Show both retry and next challenge buttons after failure
                  setState(() {
                    _showRetryChallenge = true;
                    _showNextChallenge = true;
                  });
                }
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

  Widget _buildChallengeCompletionButtons() {
    return Column(
      children: [
        if (_showNextChallenge && !_showRetryChallenge) ...[
          // Success case: Only Next Challenge button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_forward, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Next Challenge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        if (_showRetryChallenge && _showNextChallenge) ...[
          // Failure case: Both buttons side by side
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retryChallenge,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.orange[600]!, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Try This Challenge Again',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_forward, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Next Challenge',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Transform.scale(
              scale: _successAnimation.value,
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Celebration icon with animation
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.rotate(
                          angle: value * 0.3,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.yellow[400]!, Colors.orange[400]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.yellow.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Success message
                    Text(
                      '🎉 Fantastic!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'You built the number bond correctly!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Star reward
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.yellow[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+1 Star',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Current rewards display
                    if (_currentRewards != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '⭐ ${_currentRewards!.totalStars}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '🏅 ${_currentRewards!.totalBadges}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
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
          ),
        );
      },
    );
  }
}
