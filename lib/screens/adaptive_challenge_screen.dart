import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/adaptive_challenge.dart';
import '../models/kid_profile.dart';
import '../models/rewards_model.dart';
import '../providers/profile_provider.dart';
import '../services/adaptive_problem_service.dart';
import '../services/problem_generator.dart';
import '../services/rewards_service.dart';
import '../widgets/adaptive_challenge_display.dart';
import '../widgets/interactive_number_bond_widget.dart';
import '../widgets/rewards_display.dart';

class AdaptiveChallengeScreen extends ConsumerStatefulWidget {
  const AdaptiveChallengeScreen({super.key});

  @override
  ConsumerState<AdaptiveChallengeScreen> createState() => _AdaptiveChallengeScreenState();
}

class _AdaptiveChallengeScreenState extends ConsumerState<AdaptiveChallengeScreen>
    with TickerProviderStateMixin {
  AdaptiveChallenge? _currentChallenge;
  MathProblem? _currentProblem;
  bool _isLoading = true;
  bool _showExplanation = false;
  bool _showSuccessMessage = false;
  bool _showNextChallenge = false;
  bool _showRetryChallenge = false;
  int _currentAttempt = 1;
  String? _motivationalMessage;
  PerformanceMetrics? _performanceMetrics;
  ChildRewards? _currentRewards;

  // Animation controllers
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    
    _loadNextChallenge();
    _loadRewards();
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _loadNextChallenge() async {
    setState(() {
      _isLoading = true;
      _showExplanation = false;
      _showSuccessMessage = false;
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _currentAttempt = 1;
      _motivationalMessage = null;
    });

    try {
      final profile = ref.read(profileProvider).value;
      if (profile != null) {
        // Get next adaptive challenge
        final challenge = await AdaptiveProblemService.getNextChallenge(
          profile.id, 
          profile.name, 
          favoriteNumbers: profile.favoriteNumbers,
        );
        
        // Convert to MathProblem for existing widgets
        final problem = AdaptiveProblemService.convertToMathProblem(challenge);
        
        // Get performance metrics
        final metrics = await AdaptiveProblemService.getPerformanceMetrics(profile.id);
        
        setState(() {
          _currentChallenge = challenge;
          _currentProblem = problem;
          _performanceMetrics = metrics;
          _motivationalMessage = challenge.motivationalMessage;
          _isLoading = false;
        });
        
        print('🎯 Loaded adaptive challenge: ${challenge.problemText} (Level ${challenge.level})');
      }
    } catch (e) {
      print('❌ Error loading adaptive challenge: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRewards() async {
    final profile = ref.read(profileProvider).value;
    if (profile != null) {
      final rewards = await RewardsService.getRewards(profile.id);
      if (mounted) {
        setState(() {
          _currentRewards = rewards;
        });
      }
    }
  }

  Future<void> _onBondComplete(bool isCorrect) async {
    final profile = ref.read(profileProvider).value;
    if (profile == null || _currentChallenge == null || _currentProblem == null) return;

    // Record the attempt
    await AdaptiveProblemService.recordAttempt(
      childId: profile.id,
      problemId: _currentChallenge!.problemId,
      problemText: _currentChallenge!.problemText,
      level: _currentChallenge!.level,
      correct: isCorrect,
      timeTaken: 30.0, // TODO: Track actual time
      bondCorrect: isCorrect,
      operand1: _currentProblem!.operand1,
      operand2: _currentProblem!.operand2,
      operator: _currentProblem!.operator,
      correctAnswer: _currentProblem!.correctAnswer,
    );

    if (isCorrect) {
      // Award star for correct answer
      if (profile != null) {
        await _awardStar(profile.id, 'Correct adaptive challenge completion');
      }
      
      // Show success message
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
    } else {
      // Handle incorrect answer
      if (_currentAttempt >= 3) {
        // Show explanation after 3 attempts
        setState(() {
          _showExplanation = true;
          _showRetryChallenge = true;
          _showNextChallenge = true;
        });
      } else {
        // Increment attempt count
        setState(() {
          _currentAttempt++;
        });
      }
    }
  }

  Future<void> _awardStar(String childId, String description) async {
    final result = await RewardsService.addStar(
      childId,
      description: description,
      metadata: {
        'problem': _currentProblem?.problemText,
        'attempt': _currentAttempt,
        'level': _currentChallenge?.level,
      },
    );
    
    if (mounted && result.success && result.rewards != null) {
      setState(() {
        _currentRewards = result.rewards;
      });
    }
  }

  Future<void> _nextChallenge() async {
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
      _currentAttempt = 1;
    });
    
    await _loadNextChallenge();
  }

  Future<void> _retryChallenge() async {
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
      _currentAttempt = 1;
      _showExplanation = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(profileProvider);

        return profileAsync.when(
          data: (profile) => _buildContent(profile, profile?.language ?? 'en'),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  ElevatedButton(
                    onPressed: () => context.go('/mode-select'),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(KidProfile? profile, String currentLanguage) {
    if (profile == null) {
      return Scaffold(
        body: Center(
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
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showPerformanceDialog(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile info
                _buildProfileHeader(profile),
                const SizedBox(height: 16),
                
                // Rewards display
                if (_currentRewards != null) ...[
                  RewardsDisplay(rewards: _currentRewards!, childName: profile.name),
                  const SizedBox(height: 16),
                ],
                
                
                // Motivational message
                if (_motivationalMessage != null) ...[
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
                        Icon(Icons.celebration, color: Colors.green[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _motivationalMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Challenge display
                if (_currentChallenge != null) ...[
                  AdaptiveChallengeDisplay(challenge: _currentChallenge!),
                  const SizedBox(height: 24),
                  
                  // Interactive number bond
                  if (_currentProblem != null) ...[
                    Card(
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
                              onBondComplete: _onBondComplete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Challenge completion buttons
                  if (_showNextChallenge || _showRetryChallenge) ...[
                    const SizedBox(height: 24),
                    _buildChallengeCompletionButtons(),
                  ],
                ],
              ],
            ),
          ),
          
          // Success message overlay
          if (_showSuccessMessage) _buildSuccessOverlay(),
        ],
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
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Age: ${profile.age} • Language: ${profile.language.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          LayoutBuilder(
            builder: (context, constraints) {
              // If screen is too narrow, stack buttons vertically
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
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
                              'Try Again',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
                            Icon(Icons.arrow_forward, size: 18),
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
                );
              } else {
                // Normal horizontal layout for wider screens
                return Row(
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
                              'Try Again',
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
                            Icon(Icons.arrow_forward, size: 18),
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
                );
              }
            },
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
                    // Celebration icon
                    Container(
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
                    const SizedBox(height: 20),
                    
                    // Success message
                    Text(
                      '🎉 Excellent!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      'You solved the number bond correctly!',
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
                    const SizedBox(height: 16),
                    
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

  void _showPerformanceDialog() {
    if (_performanceMetrics == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Performance Analytics'),
        content: PerformanceMetricsDisplay(metrics: _performanceMetrics!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
