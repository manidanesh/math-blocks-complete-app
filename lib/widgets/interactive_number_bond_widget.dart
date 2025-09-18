import 'package:flutter/material.dart';
import '../services/problem_generator.dart';

class InteractiveNumberBondWidget extends StatefulWidget {
  final int operand1;
  final int operand2;
  final ProblemStrategy strategy;
  final bool showSolution;
  final VoidCallback? onBondComplete;

  const InteractiveNumberBondWidget({
    super.key,
    required this.operand1,
    required this.operand2,
    required this.strategy,
    this.showSolution = false,
    this.onBondComplete,
  });

  @override
  State<InteractiveNumberBondWidget> createState() => _InteractiveNumberBondWidgetState();
}

class _InteractiveNumberBondWidgetState extends State<InteractiveNumberBondWidget>
    with TickerProviderStateMixin {
  List<int> _selectedNumbers = [];
  List<int> _availableNumbers = [];
  bool _bondComplete = false;
  late AnimationController _circleController;
  late AnimationController _successController;
  late Animation<double> _circleAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _circleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.elasticOut),
    );
    
    _successAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOut),
    );
    
    _initializeNumbers();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _initializeNumbers() {
    // Create available numbers based on strategy
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        _initializeMakeTenNumbers();
        break;
      case ProblemStrategy.crossing:
        _initializeCrossingNumbers();
        break;
      default:
        _initializeBasicNumbers();
        break;
    }
  }

  void _initializeMakeTenNumbers() {
    // For make-ten strategy, provide numbers that help make 10
    final target = 10;
    final needed = target - widget.operand1;
    final remaining = widget.operand2 - needed;
    
    _availableNumbers = [
      widget.operand1,
      needed,
      remaining,
      target,
      widget.operand1 + widget.operand2,
      // Add some extra numbers for choice
      1, 2, 3, 4, 5, 6, 7, 8, 9,
    ].toSet().toList()..sort();
  }

  void _initializeCrossingNumbers() {
    // For crossing strategy, provide component numbers
    final sum = widget.operand1 + widget.operand2;
    _availableNumbers = [
      widget.operand1,
      widget.operand2,
      sum,
      10, 20, // Key crossing points
      // Break down operands
      widget.operand1 ~/ 10, widget.operand1 % 10,
      widget.operand2 ~/ 10, widget.operand2 % 10,
      // Add range of useful numbers
      ...List.generate(15, (i) => i + 1),
    ].toSet().where((n) => n > 0).toList()..sort();
  }

  void _initializeBasicNumbers() {
    // For basic strategy, provide simple counting numbers
    final sum = widget.operand1 + widget.operand2;
    _availableNumbers = [
      widget.operand1,
      widget.operand2,
      sum,
      ...List.generate(20, (i) => i + 1),
    ].toSet().toList()..sort();
  }

  void _selectNumber(int number) {
    setState(() {
      _selectedNumbers.add(number);
    });
    
    _circleController.forward().then((_) => _circleController.reverse());
    
    // Check if bond is complete
    _checkBondCompletion();
  }

  void _removeNumber(int index) {
    if (index < _selectedNumbers.length) {
      setState(() {
        _selectedNumbers.removeAt(index);
        _bondComplete = false;
      });
    }
  }

  void _checkBondCompletion() {
    // Check different completion criteria based on strategy
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        _checkMakeTenCompletion();
        break;
      case ProblemStrategy.crossing:
        _checkCrossingCompletion();
        break;
      default:
        _checkBasicCompletion();
        break;
    }
  }

  void _checkMakeTenCompletion() {
    // Check if user has created the make-ten sequence
    final target = widget.operand1 + widget.operand2;
    
    // Look for pattern: operand1 + needed = 10, then 10 + remaining = target
    if (_selectedNumbers.length >= 4) {
      final needed = 10 - widget.operand1;
      final remaining = widget.operand2 - needed;
      
      bool hasMakeTenSequence = _selectedNumbers.contains(widget.operand1) &&
                               _selectedNumbers.contains(needed) &&
                               _selectedNumbers.contains(10) &&
                               _selectedNumbers.contains(remaining) &&
                               _selectedNumbers.contains(target);
      
      if (hasMakeTenSequence && !_bondComplete) {
        setState(() {
          _bondComplete = true;
        });
        _successController.forward();
        widget.onBondComplete?.call();
      }
    }
  }

  void _checkCrossingCompletion() {
    // Check if user has the main components
    final target = widget.operand1 + widget.operand2;
    
    bool hasComponents = _selectedNumbers.contains(widget.operand1) &&
                        _selectedNumbers.contains(widget.operand2) &&
                        _selectedNumbers.contains(target);
    
    if (hasComponents && !_bondComplete) {
      setState(() {
        _bondComplete = true;
      });
      _successController.forward();
      widget.onBondComplete?.call();
    }
  }

  void _checkBasicCompletion() {
    // Check if user has both operands and the sum
    final target = widget.operand1 + widget.operand2;
    
    bool hasBasicComponents = _selectedNumbers.contains(widget.operand1) &&
                             _selectedNumbers.contains(widget.operand2) &&
                             _selectedNumbers.contains(target);
    
    if (hasBasicComponents && !_bondComplete) {
      setState(() {
        _bondComplete = true;
      });
      _successController.forward();
      widget.onBondComplete?.call();
    }
  }

  void _clearBond() {
    setState(() {
      _selectedNumbers.clear();
      _bondComplete = false;
    });
    _successController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getStrategyTitle(),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              if (_selectedNumbers.isNotEmpty)
                IconButton(
                  onPressed: _clearBond,
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  tooltip: 'Clear and try again',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Problem display
          Text(
            '${widget.operand1} + ${widget.operand2} = ?',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Interactive circle for selected numbers
          _buildInteractiveCircle(),
          const SizedBox(height: 20),
          
          // Strategy hint
          if (!_bondComplete && !widget.showSolution)
            _buildStrategyHint(),
          
          const SizedBox(height: 16),
          
          // Available numbers grid
          _buildNumberGrid(),
          
          const SizedBox(height: 16),
          
          // Success feedback
          if (_bondComplete)
            AnimatedBuilder(
              animation: _successAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _successAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Great job! You built the number bond!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          
          // Solution display (after 3 failures)
          if (widget.showSolution)
            _buildSolutionDisplay(),
        ],
      ),
    );
  }

  Widget _buildInteractiveCircle() {
    return AnimatedBuilder(
      animation: _circleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _circleAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _bondComplete ? Colors.green[100] : Colors.blue[50],
              border: Border.all(
                color: _bondComplete ? Colors.green : Colors.blue,
                width: 3,
              ),
            ),
            child: _selectedNumbers.isEmpty
                ? const Center(
                    child: Text(
                      'Select numbers\nto build the\nnumber bond',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: _selectedNumbers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final number = entry.value;
                        return GestureDetector(
                          onTap: () => _removeNumber(index),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getNumberColor(number),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              number.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNumberGrid() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'Available Numbers (tap to add to circle):',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableNumbers.map((number) {
              final isSelected = _selectedNumbers.contains(number);
              final selectionCount = _selectedNumbers.where((n) => n == number).length;
              
              return GestureDetector(
                onTap: () => _selectNumber(number),
                child: Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[600] : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue[600]! : Colors.grey[400]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    // Show selection count if selected multiple times
                    if (selectionCount > 1)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              selectionCount.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.yellow[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStrategyHintText(),
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolutionDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Solution:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSolutionSteps(),
        ],
      ),
    );
  }

  Widget _buildSolutionSteps() {
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        return _buildMakeTenSolution();
      case ProblemStrategy.crossing:
        return _buildCrossingSolution();
      default:
        return _buildBasicSolution();
    }
  }

  Widget _buildMakeTenSolution() {
    final needed = 10 - widget.operand1;
    final remaining = widget.operand2 - needed;
    final answer = widget.operand1 + widget.operand2;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Make 10 first'),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildSolutionNumber(widget.operand1.toString(), Colors.orange),
            const Text(' + '),
            _buildSolutionNumber(needed.toString(), Colors.green),
            const Text(' = '),
            _buildSolutionNumber('10', Colors.red),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Step 2: Add the remaining'),
        const SizedBox(height: 4),
        Row(
          children: [
            _buildSolutionNumber('10', Colors.red),
            const Text(' + '),
            _buildSolutionNumber(remaining.toString(), Colors.purple),
            const Text(' = '),
            _buildSolutionNumber(answer.toString(), Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildCrossingSolution() {
    final answer = widget.operand1 + widget.operand2;
    return Row(
      children: [
        _buildSolutionNumber(widget.operand1.toString(), Colors.orange),
        const Text(' + '),
        _buildSolutionNumber(widget.operand2.toString(), Colors.purple),
        const Text(' = '),
        _buildSolutionNumber(answer.toString(), Colors.green),
      ],
    );
  }

  Widget _buildBasicSolution() {
    final answer = widget.operand1 + widget.operand2;
    return Row(
      children: [
        _buildSolutionNumber(widget.operand1.toString(), Colors.orange),
        const Text(' + '),
        _buildSolutionNumber(widget.operand2.toString(), Colors.purple),
        const Text(' = '),
        _buildSolutionNumber(answer.toString(), Colors.green),
      ],
    );
  }

  Widget _buildSolutionNumber(String number, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        number,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getNumberColor(int number) {
    // Color code numbers based on their role
    if (number == widget.operand1) return Colors.orange;
    if (number == widget.operand2) return Colors.purple;
    if (number == 10) return Colors.red;
    if (number == widget.operand1 + widget.operand2) return Colors.green;
    return Colors.blue;
  }

  String _getStrategyTitle() {
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        return 'Make Ten Strategy';
      case ProblemStrategy.crossing:
        return 'Crossing Strategy';
      case ProblemStrategy.basic:
        return 'Counting Strategy';
      default:
        return 'Number Bond';
    }
  }

  String _getStrategyHintText() {
    switch (widget.strategy) {
      case ProblemStrategy.makeTen:
        final needed = 10 - widget.operand1;
        return 'Try: First select ${widget.operand1}, then $needed to make 10, then select 10, then the remaining numbers!';
      case ProblemStrategy.crossing:
        return 'Select the two numbers being added, then find their sum!';
      case ProblemStrategy.basic:
        return 'Select both numbers and count to find the total!';
      default:
        return 'Build the number bond step by step!';
    }
  }
}
