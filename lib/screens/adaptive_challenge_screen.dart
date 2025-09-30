import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/adaptive_challenge.dart';
import '../models/kid_profile.dart';
import '../models/rewards_model.dart';
import '../providers/profile_provider.dart';
import '../services/adaptive_problem_service.dart';
import '../services/language_service.dart';
import '../services/debug_validator.dart';
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
  // Motivational message is now displayed within AdaptiveChallengeDisplay widget
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
        
        print('🔍 Challenge details:');
        print('   problemText: ${challenge.problemText}');
        print('   operand1: ${challenge.operand1}');
        print('   operand2: ${challenge.operand2}');
        print('   operator: ${challenge.operator}');
        print('   correctAnswer: ${challenge.correctAnswer}');
        print('   level: ${challenge.level}');
        print('🔍 Converted problem: ${problem != null ? 'SUCCESS' : 'NULL'}');
        
        // Get performance metrics
        final metrics = await AdaptiveProblemService.getPerformanceMetrics(profile.id);
        
        setState(() {
          _currentChallenge = challenge;
          _currentProblem = problem;
          _performanceMetrics = metrics;
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
      // Handle incorrect answer - show explanation and buttons after 3 attempts
      setState(() {
        _showExplanation = true;
        _showRetryChallenge = true;
        _showNextChallenge = true;
      });
    }
  }

  Future<void> _awardStar(String childId, String description) async {
    final result = await RewardsService.addStar(
      childId,
      description: description,
      metadata: {
        'problem': _currentProblem?.problemText,
        'level': _currentChallenge?.level,
      },
    );
    
    if (mounted && result.success && result.rewards != null) {
      setState(() {
        _currentRewards = result.rewards;
      });
      
      // Show level up celebration if user leveled up
      if (result.levelUp) {
        _showLevelUpCelebration(result.rewards!);
      }
    }
  }

  void _showLevelUpCelebration(ChildRewards rewards) {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;
    
    final language = profile.language ?? 'en';
    final congratsText = LanguageService.translate('congratulations_level_up', language, params: {
      'name': profile.name,
      'level': rewards.currentLevel.name,
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.yellow[700], size: 30),
            const SizedBox(width: 8),
            Text(
              LanguageService.translate('level_up', language),
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              congratsText,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Text(
                '${rewards.currentLevel.emoji} ${rewards.currentLevel.name}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text(LanguageService.translate('continue', language)),
          ),
        ],
      ),
    );
  }

  Future<void> _nextChallenge() async {
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
    });
    
    await _loadNextChallenge();
  }

  Future<void> _retryChallenge() async {
    setState(() {
      _showNextChallenge = false;
      _showRetryChallenge = false;
      _showSuccessMessage = false;
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
              Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(profileProvider).value;
                  final language = profile?.language ?? 'en';
                  
                  return Text(LanguageService.translate('no_profile_found', language));
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(profileProvider).value;
                  final language = profile?.language ?? 'en';
                  
                  return ElevatedButton(
                    onPressed: () => context.go('/profile-creation'),
                    child: Text(LanguageService.translate('create_profile_button', language)),
                  );
                },
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
        title: Text(LanguageService.translate('adaptive_challenge', currentLanguage)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Check if we can go back in the navigation stack
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // Fallback to mode select if no previous route
              context.go('/mode-select');
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              if (_currentChallenge != null) {
                final validation = DebugValidator.validateProblem(
                  _currentChallenge!.operand1,
                  _currentChallenge!.operand2,
                  _currentChallenge!.operator,
                );
                print('🔍 Problem Validation:');
                print(validation);
              }
            },
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
                            Consumer(
                              builder: (context, ref, child) {
                                final profile = ref.watch(profileProvider).value;
                                final language = profile?.language ?? 'en';
                                
                                return Text(
                                  LanguageService.translate('interactive_number_bond', language),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Consumer(
                              builder: (context, ref, child) {
                                final profile = ref.watch(profileProvider).value;
                                final language = profile?.language ?? 'en';
                                
                                return InteractiveNumberBondWidget(
                                  key: ValueKey('${_currentProblem!.operand1}_${_currentProblem!.operand2}'),
                                  operand1: _currentProblem!.operand1,
                                  operand2: _currentProblem!.operand2,
                                  strategy: _currentProblem!.strategy,
                                  showSolution: _showExplanation,
                                  onBondComplete: _onBondComplete,
                                  operation: _currentProblem!.operator == '+' ? 'addition' : 'subtraction',
                                  language: language,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  
                  // Challenge completion buttons - Always show Next Challenge
                  const SizedBox(height: 24),
                  _buildChallengeCompletionButtons(),
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
        // ALWAYS show Next Challenge button first
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
            child: Consumer(
              builder: (context, ref, child) {
                final profile = ref.watch(profileProvider).value;
                final language = profile?.language ?? 'en';
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_forward, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      LanguageService.translate('next_challenge', language),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        
        // Show Try Again button below if needed
        if (_showRetryChallenge) ...[
          const SizedBox(height: 12),
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
              child: Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(profileProvider).value;
                  final language = profile?.language ?? 'en';
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.refresh, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        LanguageService.translate('try_again', language),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success animation
                Transform.scale(
                  scale: _successAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
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
                ),
                const SizedBox(height: 20),
                
                // Success message
                Consumer(
                  builder: (context, ref, child) {
                    final profile = ref.watch(profileProvider).value;
                    final language = profile?.language ?? 'en';
                    
                    return Text(
                      LanguageService.translate('excellent_celebration', language),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                
                Consumer(
                  builder: (context, ref, child) {
                    final profile = ref.watch(profileProvider).value;
                    final language = profile?.language ?? 'en';
                    
                    return Text(
                      LanguageService.translate('number_bond_solved', language),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}
