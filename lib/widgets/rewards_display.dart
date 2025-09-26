import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rewards_model.dart';
import '../providers/profile_provider.dart';
import '../services/language_service.dart';

/// Widget to display current rewards and progress
class RewardsDisplay extends StatelessWidget {
  final ChildRewards rewards;
  final String childName;
  final bool showDetailed;

  const RewardsDisplay({
    super.key,
    required this.rewards,
    required this.childName,
    this.showDetailed = false,
  });

  String _getLevelName(ChildLevel level, String language) {
    switch (level) {
      case ChildLevel.onesExplorer:
        return LanguageService.translate('ones_explorer', language);
      case ChildLevel.tensBuilder:
        return LanguageService.translate('tens_builder', language);
      case ChildLevel.hundredsHero:
        return LanguageService.translate('hundreds_hero', language);
      case ChildLevel.thousandsChampion:
        return LanguageService.translate('thousands_champion', language);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final profile = ref.watch(profileProvider).value;
        final language = profile?.language ?? 'en';
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '${rewards.currentLevel.emoji} ${_getLevelName(rewards.currentLevel, language)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const Spacer(),
              Text(
                '${rewards.totalStars} ⭐',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.translate('progress_to_next_level', language),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${rewards.starsToNextLevel} ${LanguageService.translate('stars_to_go', language)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: rewards.levelProgress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2ECC71)),
                minHeight: 6,
              ),
            ],
          ),
          
          if (showDetailed) ...[
            const SizedBox(height: 16),
            
            // Detailed stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Badges',
                    rewards.totalBadges.toString(),
                    '🏅',
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Stickers',
                    rewards.totalStickers.toString(),
                    '🎨',
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
      },
    );
  }

  Widget _buildStatCard(String label, String value, String emoji, Color color) {
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
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display motivational message with rewards
class MotivationalMessage extends StatelessWidget {
  final String childName;
  final ChildRewards rewards;
  final bool showCelebration;

  const MotivationalMessage({
    super.key,
    required this.childName,
    required this.rewards,
    this.showCelebration = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green[100]!,
            Colors.blue[100]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        children: [
          // Celebration icon if showing celebration
          if (showCelebration) ...[
            const Icon(
              Icons.celebration,
              size: 32,
              color: Color(0xFFFFD700),
            ),
            const SizedBox(height: 8),
          ],
          
          // Motivational message
          Text(
            _generateMessage(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Current stats
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip('${rewards.totalStars} ⭐', Colors.amber),
              const SizedBox(width: 8),
              _buildStatChip('${rewards.totalBadges} 🏅', Colors.orange),
              if (rewards.totalStickers > 0) ...[
                const SizedBox(width: 8),
                _buildStatChip('${rewards.totalStickers} 🎨', Colors.purple),
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Level info
          Text(
            'Level: ${rewards.currentLevel.name} ${rewards.currentLevel.emoji}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _generateMessage() {
    final messages = [
      'Great job, $childName! You now have ${rewards.totalStars} stars ⭐',
      'Amazing work, $childName! ${rewards.totalStars} stars earned! 🌟',
      'Fantastic, $childName! You\'re doing great! 🎉',
      'Incredible, $childName! Keep up the excellent work! ⭐',
      'Outstanding, $childName! You\'re a math star! 🌟',
      'Wonderful, $childName! ${rewards.totalStars} stars and counting! 🎯',
    ];
    
    // Add level-specific messages
    if (rewards.levelProgress > 0.8) {
      messages.addAll([
        'Almost there, $childName! You\'re close to the next level! 🚀',
        'So close, $childName! Just ${rewards.starsToNextLevel} more stars! ⭐',
      ]);
    }
    
    // Note: newBadge and newSticker are handled in the RewardResult, not ChildRewards
    
    // Select a random message
    final random = DateTime.now().millisecond % messages.length;
    return messages[random];
  }
}

/// Compact rewards display for small spaces
class CompactRewardsDisplay extends StatelessWidget {
  final ChildRewards rewards;

  const CompactRewardsDisplay({
    super.key,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Stars
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                rewards.totalStars.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 6),
        
        // Badges
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏅', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                rewards.totalBadges.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
        ),
        
        if (rewards.totalStickers > 0) ...[
          const SizedBox(width: 6),
          
          // Stickers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎨', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  rewards.totalStickers.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
