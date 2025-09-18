import 'package:flutter/material.dart';
import '../services/problem_generator.dart';

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
    // For make-ten strategy: show how to break numbers to make 10 first
    final sum = widget.operand1 + widget.operand2;
    final needed = 10 - widget.operand1;
    final remaining = widget.operand2 - needed;
    
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
            'Make Ten Strategy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 16),
          
          // Original problem
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberCircle(widget.operand1.toString(), Colors.orange),
              const Text(' + ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildNumberCircle(widget.operand2.toString(), Colors.purple),
              const Text(' = ?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (widget.showSolution) ...[
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Opacity(
                  opacity: _animation.value,
                  child: Column(
                    children: [
                      const Text(
                        'Step 1: Make 10 first',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      
                      // Show breaking down the second number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildNumberCircle(widget.operand1.toString(), Colors.orange),
                          const Text(' + ', style: TextStyle(fontSize: 20)),
                          _buildNumberCircle(needed.toString(), Colors.green),
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
                          _buildNumberCircle(remaining.toString(), Colors.purple),
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
            'Crossing Strategy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 16),
          
          // Visual representation with blocks
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNumberBlocks(widget.operand1, Colors.orange),
              const Text(' + ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              _buildNumberBlocks(widget.operand2, Colors.purple),
            ],
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
                        'Solution:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildNumberCircle(sum.toString(), Colors.green, isResult: true),
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
            'Counting Strategy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          
          // Show dots for counting
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDots(widget.operand1, Colors.orange),
              const SizedBox(width: 16),
              const Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              _buildDots(widget.operand2, Colors.purple),
            ],
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
                        'Count them all:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDots(sum, Colors.green),
                      const SizedBox(height: 8),
                      _buildNumberCircle(sum.toString(), Colors.green, isResult: true),
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

  Widget _buildNumberCircle(String number, Color color, {bool isResult = false}) {
    return Container(
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
