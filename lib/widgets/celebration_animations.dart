import 'dart:math';
import 'package:flutter/material.dart' hide Badge;
import '../models/rewards_model.dart';

/// Celebration animation widget for level ups and achievements
class CelebrationAnimation extends StatefulWidget {
  final Widget child;
  final bool showCelebration;
  final String message;
  final Badge? newBadge;
  final Sticker? newSticker;
  final bool levelUp;

  const CelebrationAnimation({
    super.key,
    required this.child,
    required this.showCelebration,
    required this.message,
    this.newBadge,
    this.newSticker,
    this.levelUp = false,
  });

  @override
  State<CelebrationAnimation> createState() => _CelebrationAnimationState();
}

class _CelebrationAnimationState extends State<CelebrationAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late AnimationController _badgeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _confettiAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    ));

    _badgeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _badgeController,
      curve: Curves.elasticOut,
    ));

    if (widget.showCelebration) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    _controller.forward();
    _confettiController.forward();
    
    if (widget.newBadge != null || widget.newSticker != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _badgeController.forward();
      });
    }
  }

  @override
  void didUpdateWidget(CelebrationAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCelebration && !oldWidget.showCelebration) {
      _startCelebration();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showCelebration) ...[
          // Confetti animation
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, child) {
              return CustomPaint(
                painter: ConfettiPainter(_confettiAnimation.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          
          // Celebration overlay
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: _buildCelebrationContent(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCelebrationContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration title
          Text(
            widget.levelUp ? 'LEVEL UP!' : 'ACHIEVEMENT UNLOCKED!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2ECC71),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Message
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 20),
          
          // Badge or Sticker animation
          if (widget.newBadge != null || widget.newSticker != null)
            AnimatedBuilder(
              animation: _badgeAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _badgeAnimation.value,
                  child: _buildRewardDisplay(),
                );
              },
            ),
          
          const SizedBox(height: 24),
          
          // Continue button
          ElevatedButton(
            onPressed: () {
              _controller.reverse();
              _confettiController.reverse();
              _badgeController.reverse();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardDisplay() {
    if (widget.newBadge != null) {
      return _buildBadgeDisplay(widget.newBadge!);
    } else if (widget.newSticker != null) {
      return _buildStickerDisplay(widget.newSticker!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildBadgeDisplay(Badge badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            badge.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStickerDisplay(Sticker sticker) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        children: [
          Text(
            sticker.emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            sticker.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            sticker.description,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Custom painter for confetti animation
class ConfettiPainter extends CustomPainter {
  final double animationValue;
  final List<ConfettiParticle> particles;

  ConfettiPainter(this.animationValue) : particles = _generateParticles();

  static List<ConfettiParticle> _generateParticles() {
    final random = Random();
    return List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        size: 4 + random.nextDouble() * 6,
        color: _getRandomColor(),
        velocity: 0.5 + random.nextDouble() * 1.5,
        angle: random.nextDouble() * 2 * pi,
        rotationSpeed: (random.nextDouble() - 0.5) * 0.2,
      );
    });
  }

  static Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
    ];
    final random = Random();
    return colors[random.nextInt(colors.length)];
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      final x = particle.x * size.width;
      final y = particle.y * size.height + (animationValue * size.height);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.angle + (animationValue * particle.rotationSpeed));
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size,
        ),
        paint,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// Represents a single confetti particle
class ConfettiParticle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double velocity;
  final double angle;
  final double rotationSpeed;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.angle,
    required this.rotationSpeed,
  });
}

/// Simple star burst animation
class StarBurstAnimation extends StatefulWidget {
  final Widget child;
  final bool showAnimation;
  final Duration duration;

  const StarBurstAnimation({
    super.key,
    required this.child,
    required this.showAnimation,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<StarBurstAnimation> createState() => _StarBurstAnimationState();
}

class _StarBurstAnimationState extends State<StarBurstAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(StarBurstAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAnimation && !oldWidget.showAnimation) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showAnimation)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: StarBurstPainter(_animation.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),
      ],
    );
  }
}

/// Custom painter for star burst animation
class StarBurstPainter extends CustomPainter {
  final double animationValue;

  StarBurstPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(1 - animationValue)
      ..style = PaintingStyle.fill;

    // Draw multiple stars radiating from center
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi * 2) / 8;
      final distance = 100 * animationValue;
      final starCenter = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      
      _drawStar(canvas, starCenter, 15 * (1 - animationValue), paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final innerRadius = radius * 0.4;
    
    for (int i = 0; i < 10; i++) {
      final angle = (i * pi) / 5;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
