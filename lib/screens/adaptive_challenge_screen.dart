import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/app_log.dart';
import '../models/adaptive_challenge.dart';
import '../models/kid_profile.dart';
import '../models/rewards_model.dart';
import '../providers/profile_provider.dart';
import '../services/adaptive_problem_service.dart';
import '../services/language_service.dart';
import '../services/pending_completion_service.dart';
import '../services/problem_generator.dart';
import '../services/rewards_service.dart';
import '../widgets/challenge_workspace.dart';
import '../widgets/interactive_number_bond_widget.dart';

class AdaptiveChallengeScreen extends ConsumerStatefulWidget {
  final MathProblem? initialProblem;
  final bool initialShowSolution;

  const AdaptiveChallengeScreen({
    super.key,
    this.initialProblem,
    this.initialShowSolution = false,
  });

  @override
  ConsumerState<AdaptiveChallengeScreen> createState() =>
      _AdaptiveChallengeScreenState();
}

class _PendingCompletion {
  final KidProfile profile;
  final AdaptiveChallenge challenge;
  final MathProblem problem;
  final String eventId;
  final NumberBondAttempt? attempt;
  final double timeTaken;
  final bool correct;
  final int generation;
  final bool recovered;

  const _PendingCompletion({
    required this.profile,
    required this.challenge,
    required this.problem,
    required this.eventId,
    required this.attempt,
    required this.timeTaken,
    required this.correct,
    required this.generation,
    this.recovered = false,
  });

  Map<String, dynamic> toJson() => {
    'childId': profile.id,
    'eventId': eventId,
    'challenge': challenge.toJson(),
    'problemStrategy': problem.strategy.name,
    'problemExplanation': problem.explanation,
    'timeTaken': timeTaken,
    'correct': correct,
    if (attempt != null)
      'attempt': {
        'attemptNumber': attempt!.attemptNumber,
        'usedHint': attempt!.usedHint,
        'method': attempt!.method,
        'selectedParts': attempt!.selectedParts,
      },
  };

  factory _PendingCompletion.fromJson(
    Map<String, dynamic> json,
    KidProfile profile,
  ) {
    if (json['childId'] != profile.id) {
      throw const FormatException('Pending outcome belongs to another child.');
    }
    final challenge = AdaptiveChallenge.fromJson(
      Map<String, dynamic>.from(json['challenge'] as Map),
    );
    final correct = json['correct'] as bool;
    final timeTaken = (json['timeTaken'] as num).toDouble();
    if (!timeTaken.isFinite || timeTaken < 0) {
      throw const FormatException('Invalid pending outcome time.');
    }
    final attemptData = json['attempt'] as Map?;
    return _PendingCompletion(
      profile: profile,
      challenge: challenge,
      problem: MathProblem(
        operand1: challenge.operand1,
        operand2: challenge.operand2,
        operator: challenge.operator,
        correctAnswer: challenge.correctAnswer,
        problemText: challenge.problemText,
        options: const [],
        strategy: ProblemStrategy.values.firstWhere(
          (strategy) => strategy.name == json['problemStrategy'],
        ),
        level: challenge.level,
        explanation: json['problemExplanation'] as String,
      ),
      eventId: json['eventId'] as String,
      timeTaken: timeTaken,
      correct: correct,
      generation: PendingCompletionService.currentGeneration(profile.id),
      recovered: true,
      attempt: attemptData == null
          ? null
          : NumberBondAttempt(
              isCorrect: correct,
              attemptNumber: attemptData['attemptNumber'] as int,
              usedHint: attemptData['usedHint'] as bool,
              method: attemptData['method'] as String,
              selectedParts:
                  (attemptData['selectedParts'] as List?)
                      ?.cast<int>()
                      .toList() ??
                  const [],
            ),
    );
  }
}

class _AdaptiveChallengeScreenState
    extends ConsumerState<AdaptiveChallengeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  AdaptiveChallenge? _currentChallenge;
  MathProblem? _currentProblem;
  bool _isLoading = true;
  bool _showExplanation = false;
  bool _showAnswer = false;
  bool _showSuccessMessage = false;
  bool _showRetryChallenge = false;
  ChildRewards? _currentRewards;
  final Stopwatch _attemptTimer = Stopwatch();
  int _attemptSequence = 0;
  String? _attemptEventId;
  NumberBondAttempt? _latestAttempt;
  NumberBondAttempt? _restoredAttempt;
  bool _attemptInProgress = false;
  bool _completionRecorded = false;
  _PendingCompletion? _pendingCompletion;
  bool _isSavingCompletion = false;

  // Animation controllers
  late AnimationController _successController;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize animations
    _successController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    _loadNextChallenge(useInitialProblem: true);
    _loadRewards();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _attemptTimer.stop();
    _successController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _attemptInProgress) {
      _attemptTimer.start();
    } else {
      _attemptTimer.stop();
    }
  }

  void _startAttempt() {
    _attemptEventId =
        '${_currentChallenge!.problemId}_'
        '${DateTime.now().microsecondsSinceEpoch}_${++_attemptSequence}';
    _latestAttempt = null;
    _restoredAttempt = null;
    _completionRecorded = false;
    _showAnswer = false;
    _attemptInProgress = true;
    _attemptTimer
      ..reset()
      ..start();
  }

  Future<void> _loadNextChallenge({bool useInitialProblem = false}) async {
    _attemptInProgress = false;
    _attemptTimer.stop();
    setState(() {
      _isLoading = true;
      _currentChallenge = null;
      _currentProblem = null;
      _attemptEventId = null;
      _restoredAttempt = null;
      _showExplanation = false;
      _showAnswer = false;
      _showSuccessMessage = false;
      _showRetryChallenge = false;
    });

    try {
      final profile = await ref.read(profileProvider.future);
      if (!mounted) return;
      if (profile != null) {
        final saved = await PendingCompletionService.load(profile.id);
        if (!mounted) return;
        if (saved != null) {
          final completion = _PendingCompletion.fromJson(saved, profile);
          setState(() {
            _currentChallenge = completion.challenge;
            _currentProblem = completion.problem;
            _attemptEventId = completion.eventId;
            _pendingCompletion = completion;
            _restoredAttempt = completion.attempt;
            _completionRecorded = true;
            _showAnswer = completion.correct;
            _showExplanation = true;
            _isLoading = false;
          });
          await _saveCompletion(completion);
          return;
        }

        final initial = useInitialProblem ? widget.initialProblem : null;
        if (initial != null) {
          setState(() {
            _currentProblem = initial;
            _currentChallenge = AdaptiveChallenge(
              problemId: 'review_${initial.problemText}',
              problemText: initial.problemText,
              level: initial.level,
              bondSteps: initial.explanation,
              operand1: initial.operand1,
              operand2: initial.operand2,
              operator: initial.operator,
              correctAnswer: initial.correctAnswer,
              isReviewProblem: true,
            );
            _isLoading = false;
            _showExplanation = widget.initialShowSolution;
            _showRetryChallenge = widget.initialShowSolution;
            if (!widget.initialShowSolution) _startAttempt();
          });
          return;
        }

        // Get next adaptive challenge
        final challenge = await AdaptiveProblemService.getNextChallenge(
          profile.id,
          profile.name,
          favoriteNumbers: profile.favoriteNumbers,
          preferredOperation: profile.preferredOperation,
        );

        // Convert to MathProblem for existing widgets
        final problem = AdaptiveProblemService.convertToMathProblem(challenge);

        if (!mounted) return;

        setState(() {
          _currentChallenge = challenge;
          _currentProblem = problem;
          _isLoading = false;
          _startAttempt();
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugLog('Error loading adaptive challenge: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRewards() async {
    try {
      final profile = await ref.read(profileProvider.future);
      if (!mounted || profile == null) return;
      final rewards = await RewardsService.getRewards(profile.id);
      if (mounted && ref.read(profileProvider).value?.id == profile.id) {
        setState(() => _currentRewards = rewards);
      }
    } catch (error) {
      debugLog('Could not load rewards: $error');
    }
  }

  Future<void> _onBondComplete(bool isCorrect) async {
    final profile = ref.read(profileProvider).value;
    final challenge = _currentChallenge;
    final problem = _currentProblem;
    final eventId = _attemptEventId;
    if (profile == null ||
        challenge == null ||
        problem == null ||
        eventId == null ||
        _completionRecorded) {
      return;
    }
    _completionRecorded = true;
    setState(() => _showAnswer = isCorrect);
    _attemptInProgress = false;
    _attemptTimer.stop();
    final completion = _PendingCompletion(
      profile: profile,
      challenge: challenge,
      problem: problem,
      eventId: eventId,
      attempt: _latestAttempt,
      timeTaken:
          _attemptTimer.elapsedMicroseconds / Duration.microsecondsPerSecond,
      correct: isCorrect,
      generation: PendingCompletionService.currentGeneration(profile.id),
    );
    _pendingCompletion = completion;
    await _saveCompletion(completion);
  }

  Future<void> _saveCompletion(_PendingCompletion completion) async {
    if (_isSavingCompletion) return;
    final profileNotifier = ref.read(profileProvider.notifier);
    final profile = completion.profile;
    final challenge = completion.challenge;
    final problem = completion.problem;
    final eventId = completion.eventId;
    final attempt = completion.attempt;
    final isCorrect = completion.correct;
    setState(() => _isSavingCompletion = true);
    try {
      final saved = await PendingCompletionService.runCompletion(
        profile.id,
        () async {
          await PendingCompletionService.save(profile.id, completion.toJson());
          await AdaptiveProblemService.recordAttempt(
            childId: profile.id,
            problemId: eventId,
            problemText: challenge.problemText,
            level: challenge.level,
            correct: isCorrect,
            timeTaken: completion.timeTaken,
            bondCorrect: isCorrect,
            operand1: problem.operand1,
            operand2: problem.operand2,
            operator: problem.operator,
            correctAnswer: problem.correctAnswer,
            attemptNumber: attempt?.attemptNumber ?? 1,
            usedHint: attempt?.usedHint ?? false,
            strategy: attempt?.method ?? problem.strategy.name,
            isReviewProblem: challenge.isReviewProblem,
          );

          if (isCorrect) {
            // Award star for correct answer
            await _awardStar(
              profile.id,
              'Correct adaptive challenge completion',
              problem: problem,
              eventId: eventId,
            );
          }
          await profileNotifier.recordChallengeOutcome(
            childId: profile.id,
            correct: isCorrect,
            stars: isCorrect ? 1 : 0,
            eventId: eventId,
          );
          await PendingCompletionService.clear(profile.id, eventId: eventId);
        },
        expectedGeneration: completion.generation,
        expectedEventId: completion.recovered ? eventId : null,
      );
      if (!mounted || _attemptEventId != eventId) return;
      _pendingCompletion = null;
      if (!saved) {
        setState(() => _isSavingCompletion = false);
        await _loadNextChallenge();
        return;
      }

      if (isCorrect) {
        // Show success message
        setState(() {
          _showSuccessMessage = true;
          _showRetryChallenge = false;
        });

        // Start success animation
        _successController.forward();

        // Hide success message and show next challenge button after animation
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _attemptEventId == eventId) {
            setState(() {
              _showSuccessMessage = false;
            });
            _successController.reset();
          }
        });
      } else {
        // Handle incorrect answer - show explanation and buttons after 3 attempts
        setState(() {
          _showExplanation = true;
          _showRetryChallenge = true;
        });
      }
    } catch (error) {
      debugLog('Could not save challenge completion: $error');
      if (!mounted || _attemptEventId != eventId) return;
      setState(() => _showRetryChallenge = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.translate('challenge_save_error', profile.language),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingCompletion = false);
    }
  }

  Future<void> _awardStar(
    String childId,
    String description, {
    required MathProblem problem,
    required String eventId,
  }) async {
    final result = await RewardsService.addStar(
      childId,
      description: description,
      metadata: {
        'problem': problem.problemText,
        'level': problem.level,
        'eventId': eventId,
      },
    );
    if (!result.success) throw StateError('Could not save reward.');

    if (mounted &&
        ref.read(profileProvider).value?.id == childId &&
        result.success &&
        result.rewards != null) {
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

    final language = profile.language;
    final congratsText = LanguageService.translate(
      'congratulations_level_up',
      language,
      params: {'name': profile.name, 'level': rewards.currentLevel.name},
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.yellow[700], size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                LanguageService.translate('level_up', language),
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(congratsText, textAlign: TextAlign.center),
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
    if (_pendingCompletion != null || _isLoading) return;
    setState(() {
      _showRetryChallenge = false;
      _showSuccessMessage = false;
    });

    await _loadNextChallenge();
  }

  Future<void> _retryChallenge() async {
    final pending = _pendingCompletion;
    if (pending != null) {
      await _saveCompletion(pending);
      return;
    }
    setState(() {
      _showRetryChallenge = false;
      _showSuccessMessage = false;
      _showExplanation = false;
      _startAttempt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final profileAsync = ref.watch(profileProvider);

        return profileAsync.when(
          data: (profile) => _buildContent(profile, profile?.language ?? 'en'),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
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

                  return Text(
                    LanguageService.translate('no_profile_found', language),
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final profile = ref.watch(profileProvider).value;
                  final language = profile?.language ?? 'en';

                  return ElevatedButton(
                    onPressed: () => context.go('/profile-creation'),
                    child: Text(
                      LanguageService.translate(
                        'create_profile_button',
                        language,
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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.translate('adaptive_challenge', currentLanguage),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18),
        ),
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
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_currentProblem != null && _currentChallenge != null)
            ChallengeWorkspace(
              childName: profile.name,
              age: profile.age,
              level: _currentChallenge!.level,
              problem: _currentProblem!,
              rewards: _currentRewards,
              language: currentLanguage,
              isReview: _currentChallenge!.isReviewProblem,
              showSolution: _showExplanation,
              showAnswer: _showAnswer,
              showRetry: _showRetryChallenge || _pendingCompletion != null,
              isSavingResult: _isSavingCompletion,
              hasPendingResult: _pendingCompletion != null,
              onBondComplete: _onBondComplete,
              onNextChallenge: _nextChallenge,
              onRetryChallenge: _retryChallenge,
              attemptKey: _attemptEventId,
              restoredAttempt: _restoredAttempt,
              onAttemptChecked: (attempt) => _latestAttempt = attempt,
            )
          else
            Center(
              child: ElevatedButton(
                onPressed: _loadNextChallenge,
                child: Text(
                  LanguageService.translate('try_again', currentLanguage),
                ),
              ),
            ),
          if (_showSuccessMessage) _buildSuccessOverlay(),
        ],
      ),
    );
  }

  Widget _buildSuccessOverlay() {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    key: const ValueKey('challenge-success-scroll'),
                    padding: const EdgeInsets.all(24),
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
                                  color: Colors.yellow.withValues(alpha: 0.3),
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
                              LanguageService.translate(
                                'excellent_celebration',
                                language,
                              ),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        Consumer(
                          builder: (context, ref, child) {
                            final profile = ref.watch(profileProvider).value;
                            final language = profile?.language ?? 'en';

                            return Text(
                              LanguageService.translate(
                                'number_bond_solved',
                                language,
                              ),
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
