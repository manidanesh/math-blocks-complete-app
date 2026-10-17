import 'package:flutter/material.dart';

import '../models/rewards_model.dart';
import '../services/language_service.dart';
import '../services/problem_generator.dart';
import 'interactive_number_bond_widget.dart';
import 'rewards_display.dart';

/// Presents the full challenge page, with an optional compact component layout.
/// Challenge loading, persistence, rewards and celebrations belong to the screen.
class ChallengeWorkspace extends StatelessWidget {
  final String childName;
  final int? age;
  final bool compact;
  final int level;
  final MathProblem problem;
  final ValueChanged<bool> onBondComplete;
  final VoidCallback onNextChallenge;
  final VoidCallback onRetryChallenge;
  final String language;
  final ChildRewards? rewards;
  final bool isReview;
  final bool showSolution;
  final bool showAnswer;
  final bool showRetry;
  final bool isSavingResult;
  final bool hasPendingResult;
  final Object? attemptKey;
  final NumberBondAttempt? restoredAttempt;
  final ValueChanged<NumberBondAttempt>? onAttemptChecked;

  const ChallengeWorkspace({
    super.key,
    required this.childName,
    this.age,
    this.compact = false,
    required this.level,
    required this.problem,
    required this.onBondComplete,
    required this.onNextChallenge,
    required this.onRetryChallenge,
    this.language = 'en',
    this.rewards,
    this.isReview = false,
    this.showSolution = false,
    this.showAnswer = false,
    this.showRetry = false,
    this.isSavingResult = false,
    this.hasPendingResult = false,
    this.attemptKey,
    this.restoredAttempt,
    this.onAttemptChecked,
  });

  String _text(String key, {Map<String, String>? params}) =>
      LanguageService.translate(key, language, params: params);

  @override
  Widget build(BuildContext context) =>
      compact ? _buildCompactPage(context) : _buildFullPage();

  Widget _buildCompactPage(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      key: const ValueKey('challenge-workspace'),
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideways =
              constraints.maxHeight < 390 &&
              constraints.maxWidth > constraints.maxHeight;
          if (sideways) {
            final summaryWidth = (constraints.maxWidth * 0.27).clamp(
              128.0,
              180.0,
            );
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: summaryWidth,
                  child: Column(
                    children: [
                      _buildSummary(narrow: true),
                      const SizedBox(height: 6),
                      _buildQuestion(),
                      const Spacer(),
                      _buildActions(vertical: true),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildBond()),
              ],
            );
          }

          return Column(
            children: [
              _buildSummary(),
              const SizedBox(height: 6),
              _buildQuestion(),
              const SizedBox(height: 6),
              Expanded(child: _buildBond()),
              const SizedBox(height: 6),
              _buildActions(),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildFullPage() => SafeArea(
    top: false,
    child: SingleChildScrollView(
      key: const ValueKey('challenge-page-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        key: const ValueKey('challenge-workspace'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isReview ? _text('review') : '${_text('level')} $level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuestion(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    _text('interactive_number_bond'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBondWidget(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _actionButton(
            key: const ValueKey('challenge-next'),
            label: _text('next_challenge'),
            icon: Icons.arrow_forward,
            onPressed: hasPendingResult ? null : onNextChallenge,
            full: true,
          ),
          if (showRetry) ...[
            const SizedBox(height: 12),
            _actionButton(
              key: const ValueKey('challenge-retry'),
              label: _retryLabel,
              icon: Icons.refresh,
              onPressed: isSavingResult ? null : onRetryChallenge,
              secondary: true,
              full: true,
            ),
          ],
          const SizedBox(height: 24),
          Card(
            key: const ValueKey('challenge-profile-summary'),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      childName.isEmpty
                          ? '?'
                          : childName.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          childName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          [
                            if (age != null) '${_text('profile_age')}: $age',
                            '${_text('profile_language')}: ${language.toUpperCase()}',
                          ].join(' • '),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (rewards != null) ...[
            RewardsDisplay(
              rewards: rewards!,
              childName: childName,
              language: language,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    ),
  );

  Widget _buildSummary({bool narrow = false}) {
    final currentRewards = rewards;
    return Column(
      key: const ValueKey('challenge-profile-summary'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  childName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: isReview ? _text('review') : _text('level'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isReview
                        ? _text('review')
                        : narrow
                        ? '$level'
                        : '${_text('level')} $level',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ),
              if (currentRewards != null && !narrow) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: '${currentRewards.totalBadges} 🏅',
                  child: Text(
                    '${currentRewards.totalStars} ⭐',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (currentRewards != null) ...[
          const SizedBox(height: 2),
          Tooltip(
            message:
                '${_rewardLevelName(currentRewards.currentLevel)} · '
                '${currentRewards.starsToNextLevel} ${_text('stars_to_go')}',
            child: Semantics(
              label: _text('progress_to_next_level'),
              value:
                  '${(currentRewards.levelProgress * 100).round()}% · '
                  '${currentRewards.starsToNextLevel} ${_text('stars_to_go')}',
              child: LinearProgressIndicator(
                key: const ValueKey('challenge-progress'),
                value: currentRewards.levelProgress,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: Colors.blue.shade50,
                color: Colors.green.shade500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _rewardLevelName(ChildLevel rewardLevel) =>
      _text(switch (rewardLevel) {
        ChildLevel.onesExplorer => 'ones_explorer',
        ChildLevel.tensBuilder => 'tens_builder',
        ChildLevel.hundredsHero => 'hundreds_hero',
        ChildLevel.thousandsChampion => 'thousands_champion',
      });

  Widget _buildQuestion() => SizedBox(
    height: 42,
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${problem.operand1} ${problem.operator} ${problem.operand2} = ${showAnswer ? problem.correctAnswer : '?'}',
          key: const ValueKey('challenge-question'),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );

  Widget _buildBond() => SizedBox.expand(
    key: const ValueKey('challenge-bond-region'),
    child: _buildBondWidget(),
  );

  Widget _buildBondWidget() => InteractiveNumberBondWidget(
    key: ValueKey(
      '${problem.operand1}_${problem.operator}_${problem.operand2}_${attemptKey ?? ''}',
    ),
    operand1: problem.operand1,
    operand2: problem.operand2,
    strategy: problem.strategy,
    operation: problem.operator == '+' ? 'addition' : 'subtraction',
    language: language,
    showSolution: showSolution,
    onBondComplete: onBondComplete,
    onAttemptChecked: onAttemptChecked,
    compact: compact,
    enabled: !hasPendingResult,
    restoredAttempt: restoredAttempt,
  );

  Widget _buildActions({bool vertical = false}) {
    final next = _actionButton(
      key: const ValueKey('challenge-next'),
      label: _text('next_challenge'),
      icon: Icons.arrow_forward,
      onPressed: hasPendingResult ? null : onNextChallenge,
    );
    if (!showRetry) return next;
    final retry = _actionButton(
      key: const ValueKey('challenge-retry'),
      label: _retryLabel,
      icon: Icons.refresh,
      onPressed: isSavingResult ? null : onRetryChallenge,
      secondary: true,
    );
    if (vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [retry, const SizedBox(height: 6), next],
      );
    }
    return Row(
      children: [
        Expanded(child: retry),
        const SizedBox(width: 8),
        Expanded(child: next),
      ],
    );
  }

  String get _retryLabel => _text(
    isSavingResult
        ? 'challenge_saving_result'
        : hasPendingResult
        ? 'challenge_retry_save'
        : 'try_again',
  );

  Widget _actionButton({
    required Key key,
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool secondary = false,
    bool full = false,
  }) {
    final fullContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
    final content = full
        ? fullContent
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(fontSize: 15)),
              ],
            ),
          );
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 44),
      maximumSize: full ? Size.infinite : const Size(double.infinity, 44),
      padding: full
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
          : const EdgeInsets.symmetric(horizontal: 8),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: Colors.green.shade600,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
    if (secondary) {
      return OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: style.copyWith(
          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
          foregroundColor: WidgetStatePropertyAll(Colors.orange.shade800),
          side: WidgetStatePropertyAll(
            BorderSide(color: Colors.orange.shade600),
          ),
        ),
        child: content,
      );
    }
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: style,
      child: content,
    );
  }
}
