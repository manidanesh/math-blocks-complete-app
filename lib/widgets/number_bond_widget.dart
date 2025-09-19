import 'package:flutter/material.dart';
import '../services/problem_generator.dart';

/// Custom painter for drawing lines between number bond circles
class NumberBondLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Calculate proper positions for 50px circles with 25px radius
    final circleRadius = 25.0;
    
    // Top circle center (center horizontally, 25px from top)
    final topCenter = Offset(size.width / 2, circleRadius);
    
    // Bottom left circle center (75px from left edge, 25px from bottom)
    final bottomLeft = Offset(75.0, size.height - circleRadius);
    
    // Bottom right circle center (125px from left edge, 25px from bottom)
    final bottomRight = Offset(125.0, size.height - circleRadius);

    // Draw lines connecting the circle centers
    canvas.drawLine(topCenter, bottomLeft, paint);
    canvas.drawLine(topCenter, bottomRight, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class NumberBondWidget extends StatefulWidget {
  final int operand1;
  final int operand2;
  final ProblemStrategy strategy;
  final bool showSolution;

  const NumberBondWidget({
    super.key,
    required this.operand1,
    required this.operand2,
    required this.strategy,
    this.showSolution = false,
  });

  @override
  State<NumberBondWidget> createState() => _NumberBondWidgetState();
}

class _NumberBondWidgetState extends State<NumberBondWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.showSolution) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(NumberBondWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSolution && !oldWidget.showSolution) {
      _animationController.forward();
    } else if (!widget.showSolution && oldWidget.showSolution) {
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        return _buildMakeTenVisualization();
      case ProblemStrategy.crossing:
        return _buildCrossingVisualization();
      case ProblemStrategy.basic:
        return _buildBasicVisualization();
      default:
        return _buildBasicVisualization();
    }
  }

  Widget _buildMakeTenVisualization() {
    final sum = widget.operand1 + widget.operand2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Number Bond',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          
          // Three-circle number bond structure: Top circle with second number, two empty circles below
          SizedBox(
            width: 200,
            height: 120,
            child: Stack(
              children: [
                // Lines connecting the circles
                CustomPaint(
                  size: const Size(200, 120),
                  painter: NumberBondLinePainter(),
                ),
                
                // Top circle - SECOND NUMBER (given)
                Positioned(
                  top: 0,
                  left: 75, // Center horizontally (200/2 - 25)
                  child: _buildNumberCircle(
                    widget.operand2.toString(), 
                    Colors.purple,
                    label: 'Second\nNumber'
                  ),
                ),
                
                // Bottom left circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 50, // 75 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '4' : '?', // Example: 6 = 4 + 2
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'First\nPart'
                  ),
                ),
                
                // Bottom right circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 100, // 125 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '2' : '?', // Example: 6 = 4 + 2
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'Second\nPart'
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (widget.showSolution) ...[
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Column(
                    children: [
                      const Text(
                        'Make Ten Strategy',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Show breaking down the second number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNumberCircle(widget.operand1.toString(), Colors.orange),
                          const Text(' + ', style: TextStyle(fontSize: 20)),
                              _buildNumberCircle((10 - widget.operand1).toString(), Colors.green),
                          const Text(' = ', style: TextStyle(fontSize: 20)),
                          _buildNumberCircle('10', Colors.red),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      const Text(
                        'Step 2: Add the rest',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNumberCircle('10', Colors.red),
                          const Text(' + ', style: TextStyle(fontSize: 20)),
                              _buildNumberCircle((sum - 10).toString(), Colors.purple),
                          const Text(' = ', style: TextStyle(fontSize: 20)),
                          _buildNumberCircle(sum.toString(), Colors.green, isResult: true),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            // Show hint without solution
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: Text(
                'Hint: What number goes with ${widget.operand1} to make 10?',
                style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCrossingVisualization() {
    // For crossing ten/twenty strategy
    final sum = widget.operand1 + widget.operand2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Number Bond',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 20),
          
          // Three-circle number bond structure: Top circle with second number, two empty circles below
          SizedBox(
            width: 200,
            height: 120,
            child: Stack(
              children: [
                // Lines connecting the circles
                CustomPaint(
                  size: const Size(200, 120),
                  painter: NumberBondLinePainter(),
                ),
                
                // Top circle - SECOND NUMBER (given)
                Positioned(
                  top: 0,
                  left: 75, // Center horizontally (200/2 - 25)
                  child: _buildNumberCircle(
                    widget.operand2.toString(), 
                    Colors.purple,
                    label: 'Second\nNumber'
                  ),
                ),
                
                // Bottom left circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 50, // 75 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '5' : '?', // Example breakdown
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'First\nPart'
                  ),
                ),
                
                // Bottom right circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 100, // 125 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '1' : '?', // Example breakdown
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'Second\nPart'
                  ),
                ),
              ],
            ),
          ),
          
          if (widget.showSolution) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Column(
                    children: [
                      const Text(
                        'Crossing Strategy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.operand2} = 5 + 1 (example)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicVisualization() {
    // For basic counting strategy
    final sum = widget.operand1 + widget.operand2;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          const Text(
            'Number Bond',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 20),
          
          // Three-circle number bond structure: Top circle with second number, two empty circles below
          SizedBox(
            width: 200,
            height: 120,
            child: Stack(
              children: [
                // Lines connecting the circles
                CustomPaint(
                  size: const Size(200, 120),
                  painter: NumberBondLinePainter(),
                ),
                
                // Top circle - SECOND NUMBER (given)
                Positioned(
                  top: 0,
                  left: 75, // Center horizontally (200/2 - 25)
                  child: _buildNumberCircle(
                    widget.operand2.toString(), 
                    Colors.purple,
                    label: 'Second\nNumber'
                  ),
                ),
                
                // Bottom left circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 50, // 75 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '3' : '?', // Example breakdown
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'First\nPart'
                  ),
                ),
                
                // Bottom right circle - EMPTY for user selection
                Positioned(
                  bottom: 0,
                  left: 100, // 125 - 25 (center - radius)
                  child: _buildNumberCircle(
                    widget.showSolution ? '3' : '?', // Example breakdown
                    widget.showSolution ? Colors.orange : Colors.grey[300]!,
                    label: 'Second\nPart'
                  ),
                ),
              ],
            ),
          ),
          
          if (widget.showSolution) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Column(
                    children: [
                      const Text(
                        'Basic Counting',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.operand2} = 3 + 3 (example)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberCircle(String number, Color color, {bool isResult = false, String? label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isResult ? 60 : 50,
          height: isResult ? 60 : 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isResult
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: isResult ? 24 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildNumberBlocks(int number, Color color) {
    // Show number as blocks (tens and ones)
    final tens = number ~/ 10;
    final ones = number % 10;
    
    return Column(
      children: [
        if (tens > 0) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(tens, (index) => 
              Container(
                width: 8,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(ones, (index) => 
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          number.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDots(int count, Color color) {
    // Limit dots to prevent UI overflow
    final displayCount = count.clamp(1, 15);
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(displayCount, (index) =>
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

