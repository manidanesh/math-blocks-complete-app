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

    // Draw lines from top center to bottom left and right
    final topCenter = Offset(size.width / 2, 0);
    final bottomLeft = Offset(size.width * 0.25, size.height);
    final bottomRight = Offset(size.width * 0.75, size.height);

    canvas.drawLine(topCenter, bottomLeft, paint);
    canvas.drawLine(topCenter, bottomRight, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class InteractiveNumberBondWidget extends StatefulWidget {
  final int operand1;
  final int operand2;
  final ProblemStrategy strategy;
  final bool showSolution;
  final Function(bool isCorrect)? onBondComplete;

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
  Map<String, List<int>> _circleNumbers = {
    'result': [],
    'operand1': [],
    'operand2': [],
  };
  List<int> _availableNumbers = [];
  bool _bondComplete = false;
  bool _isValidating = false;
  bool? _isCorrectAnswer;
  bool _showExplanation = false;
  int _attemptCount = 0;
  bool _showTryAgain = false;

  @override
  void initState() {
    super.initState();
    _initializeNumbers();
  }

  @override
  void dispose() {
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
      // Fill left circle first, then right circle
      if (_circleNumbers['operand1']!.isEmpty) {
        _circleNumbers['operand1']!.add(number);
      } else if (_circleNumbers['operand2']!.isEmpty) {
        _circleNumbers['operand2']!.add(number);
        
        // When both circles are filled, validate the answer
        _validateAnswer();
      }
    });
    
    // Animation removed - just change background color
    
    // Check if bond is complete
    _checkBondCompletion();
  }

  void _validateAnswer() {
    if (_circleNumbers['operand1']!.isNotEmpty && _circleNumbers['operand2']!.isNotEmpty) {
      _attemptCount++;
      
      // Check if the answer is correct using Make Ten strategy
      final operand1 = _circleNumbers['operand1']!.first;
      final operand2 = _circleNumbers['operand2']!.first;
      
      // For Make Ten strategy: the first part should make 10 with the original first operand
      final shouldMakeTen = operand1 + widget.operand1 == 10;
      final shouldAddToSecondOperand = operand1 + operand2 == widget.operand2;
      
      // Both conditions must be true for Make Ten strategy
      final isCorrect = shouldMakeTen && shouldAddToSecondOperand;
      
      setState(() {
        _isCorrectAnswer = isCorrect;
        
        if (isCorrect) {
          // Correct answer - show explanation and notify parent
          _showExplanation = true;
          widget.onBondComplete?.call(true);
        } else if (_attemptCount >= 3) {
          // 3rd attempt failed - show failure with explanation
          _showExplanation = true;
          widget.onBondComplete?.call(false);
        } else {
          // Wrong answer but still have attempts - show try again message
          _showTryAgain = true;
        }
      });
    }
  }
  
  void _refreshForRetry() {
    // Clear the circles for retry
    setState(() {
      _circleNumbers['operand1']!.clear();
      _circleNumbers['operand2']!.clear();
      _isCorrectAnswer = null;
      _showExplanation = false;
      _showTryAgain = false;
    });
  }

  void _removeNumberFromCircle(String circleKey, int number) {
    setState(() {
      _circleNumbers[circleKey]!.remove(number);
      _bondComplete = false;
      _isValidating = false;
      _isCorrectAnswer = null;
      _showExplanation = false;
      _attemptCount = 0;
      _showTryAgain = false;
    });
  }

  List<int> _getNumbersInCircle(String circleKey) {
    return _circleNumbers[circleKey] ?? [];
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
    // Check if result circle has the correct sum
    final resultNumbers = _circleNumbers['result']!;
    final expectedSum = widget.operand1 + widget.operand2;
    final resultSum = resultNumbers.fold<int>(0, (sum, n) => sum + n);
    
    if (resultSum == expectedSum && !_bondComplete) {
      setState(() {
        _bondComplete = true;
      });
      // Animation removed
    }
  }

  void _checkCrossingCompletion() {
    // Check if result circle has the correct sum
    final resultNumbers = _circleNumbers['result']!;
    final expectedSum = widget.operand1 + widget.operand2;
    final resultSum = resultNumbers.fold<int>(0, (sum, n) => sum + n);
    
    if (resultSum == expectedSum && !_bondComplete) {
      setState(() {
        _bondComplete = true;
      });
      // Animation removed
    }
  }

  void _checkBasicCompletion() {
    // Check if result circle has the correct sum
    final resultNumbers = _circleNumbers['result']!;
    final expectedSum = widget.operand1 + widget.operand2;
    final resultSum = resultNumbers.fold<int>(0, (sum, n) => sum + n);
    
    if (resultSum == expectedSum && !_bondComplete) {
      setState(() {
        _bondComplete = true;
      });
      // Animation removed
    }
  }

  void _clearBond() {
    setState(() {
      _circleNumbers['result']!.clear();
      _circleNumbers['operand1']!.clear();
      _circleNumbers['operand2']!.clear();
      _bondComplete = false;
    });
    // Animation removed
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
              if (_circleNumbers.values.any((list) => list.isNotEmpty))
                IconButton(
                  onPressed: _clearBond,
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  tooltip: 'Clear and try again',
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Interactive circle for selected numbers
          _buildInteractiveCircle(),
          const SizedBox(height: 20),
          
          
          const SizedBox(height: 16),
          
          // Available numbers grid
          _buildNumberGrid(),
          
          const SizedBox(height: 16),
          
          // Success feedback - animation removed
          if (_bondComplete)
            Container(
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
          
          // Solution display (after 3 failures)
          if (widget.showSolution)
            _buildSolutionDisplay(),
        ],
      ),
    );
  }

  Widget _buildInteractiveCircle() {
    return Column(
      children: [
              // Three-circle number bond structure: Top circle with second number, two empty circles below
              SizedBox(
                width: 300,
                height: 220,
                child: Stack(
                  children: [
                    // Top circle - SECOND NUMBER (given) - centered
                    Positioned(
                      top: 30,
                      left: 125, // Center horizontally (300/2 - 25)
                      child: _buildNumberCircle(
                        widget.operand2.toString(), 
                        Colors.purple
                      ),
                    ),
                    
                    // Bottom left circle - EMPTY for user selection
                    Positioned(
                      bottom: 30,
                      left: 75, // Aligned under the top circle
                      child: _buildNumberCircle(
                        _getNumbersInCircle('operand1').isNotEmpty 
                          ? _getNumbersInCircle('operand1').first.toString()
                          : '?',
                        _getNumbersInCircle('operand1').isNotEmpty 
                          ? (_isCorrectAnswer == true ? Colors.green : Colors.yellow)
                          : Colors.grey[300]!
                      ),
                    ),
                    
                    // Bottom right circle - EMPTY for user selection
                    Positioned(
                      bottom: 30,
                      left: 175, // Aligned under the top circle
                      child: _buildNumberCircle(
                        _getNumbersInCircle('operand2').isNotEmpty 
                          ? _getNumbersInCircle('operand2').first.toString()
                          : '?',
                        _getNumbersInCircle('operand2').isNotEmpty 
                          ? (_isCorrectAnswer == true ? Colors.green : Colors.yellow)
                          : Colors.grey[300]!
                      ),
                    ),
                  ],
                ),
              ),
              
              
              // Show try again message for wrong answers
              if (_showTryAgain && _isCorrectAnswer == false) ...[
                const SizedBox(height: 24),
                _buildTryAgainMessage(),
              ],
              
              // Show Make Ten strategy explanation when correct or after 3 attempts
              if (_showExplanation) ...[
                const SizedBox(height: 24),
                _buildMakeTenExplanation(),
              ],
      ],
    );
  }

  Widget _buildNumberCircle(String number, Color color, {String? label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 20,
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

  Widget _buildResultCircle() {
    final resultNumbers = _getNumbersInCircle('result');
    final expectedSum = widget.operand1 + widget.operand2;
    final isCorrect = resultNumbers.isNotEmpty && 
                     resultNumbers.fold<int>(0, (sum, n) => sum + n) == expectedSum;
    
    return GestureDetector(
      onTap: () {
        // Allow dropping numbers here
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect ? Colors.green[100] : Colors.blue[50],
          border: Border.all(
            color: isCorrect ? Colors.green : Colors.blue,
            width: 3,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (resultNumbers.isEmpty)
              const Text(
                'Sum',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.center,
                children: resultNumbers.map((number) => 
                  GestureDetector(
                    onTap: () => _removeNumberFromCircle('result', number),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        number.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            if (isCorrect)
              const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOperandCircle(int operandNumber, String label) {
    final expectedValue = operandNumber == 1 ? widget.operand1 : widget.operand2;
    final circleNumbers = _getNumbersInCircle('operand$operandNumber');
    final isCorrect = circleNumbers.isNotEmpty && 
                     circleNumbers.fold<int>(0, (sum, n) => sum + n) == expectedValue;
    
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Allow dropping numbers here
          },
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? Colors.orange[100] : Colors.grey[100],
              border: Border.all(
                color: isCorrect ? Colors.orange : Colors.grey,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (circleNumbers.isEmpty)
                  Text(
                    expectedValue.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: circleNumbers.map((number) => 
                      GestureDetector(
                        onTap: () => _removeNumberFromCircle('operand$operandNumber', number),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: operandNumber == 1 ? Colors.orange : Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            number.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ).toList(),
                  ),
                if (isCorrect)
                  const Icon(Icons.check, color: Colors.green, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
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
              final allSelected = _circleNumbers.values.expand((list) => list).toList();
              final isSelected = allSelected.contains(number);
              final selectionCount = allSelected.where((n) => n == number).length;
              
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


  Widget _buildMakeTenExplanation() {
    // Calculate the correct answer for Make Ten strategy
    final makeTenNumber = 10 - widget.operand1; // The number that makes 10 with operand1
    final remainingNumber = widget.operand2 - makeTenNumber; // The remaining number
    final tenPlusRemaining = 10 + remainingNumber;
    
    // Check if this is a failure case (after 3 attempts)
    final isFailure = _attemptCount >= 3 && _isCorrectAnswer != true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFailure 
            ? [Colors.orange[50]!, Colors.orange[100]!]
            : [Colors.green[50]!, Colors.green[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFailure ? Colors.orange[300]! : Colors.green[300]!, 
          width: 2
        ),
        boxShadow: [
          BoxShadow(
            color: (isFailure ? Colors.orange : Colors.green).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isFailure ? Icons.school : Icons.lightbulb, 
                color: isFailure ? Colors.orange[600] : Colors.green[600], 
                size: 24
              ),
              const SizedBox(width: 8),
              Text(
                isFailure 
                  ? 'Let\'s learn the Make Ten Strategy:'
                  : 'Great! Here\'s the Make Ten Strategy:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isFailure ? Colors.orange[700] : Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Step 1: Make Ten
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  'Step 1: Make Ten',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildExplanationNumber(widget.operand1.toString(), Colors.orange),
                    const Text(' + ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _buildExplanationNumber(makeTenNumber.toString(), Colors.blue),
                    const Text(' = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _buildExplanationNumber('10', Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.operand1} + $makeTenNumber = 10 ✓',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Arrow
          Icon(Icons.keyboard_arrow_down, color: Colors.green[600], size: 32),
          
          const SizedBox(height: 16),
          
          // Step 2: Add remaining
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple[200]!),
            ),
            child: Column(
              children: [
                const Text(
                  'Step 2: Add the Remaining',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildExplanationNumber('10', Colors.green),
                    const Text(' + ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _buildExplanationNumber(remainingNumber.toString(), Colors.purple),
                    const Text(' = ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    _buildExplanationNumber(tenPlusRemaining.toString(), Colors.red),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '10 + $remainingNumber = $tenPlusRemaining ✓',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Final answer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.red[300]!, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.red[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Final Answer: ${widget.operand1} + ${widget.operand2} = $tenPlusRemaining',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationNumber(String number, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTryAgainMessage() {
    final remainingAttempts = 3 - _attemptCount;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, color: Colors.orange[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Not quite right!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Text(
            'You have $remainingAttempts more ${remainingAttempts == 1 ? 'try' : 'tries'}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.orange[600],
            ),
          ),
          
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: _refreshForRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh, size: 20),
                SizedBox(width: 8),
                Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
