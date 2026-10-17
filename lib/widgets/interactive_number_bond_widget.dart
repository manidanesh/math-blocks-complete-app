import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/answer_validator.dart';
import '../services/language_service.dart';
import '../services/problem_generator.dart';

/// Connects the whole number to a row of parts.
class NumberBondLinePainter extends CustomPainter {
  final int partCount;
  final List<double>? partCenters;
  const NumberBondLinePainter({this.partCount = 2, this.partCenters});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;
    for (var i = 0; i < partCount; i++) {
      final end = partCenters?[i] ?? size.width * (i + 0.5) / partCount;
      if (end < 0 || end > size.width) continue;
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(end, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(NumberBondLinePainter oldDelegate) =>
      oldDelegate.partCount != partCount ||
      oldDelegate.partCenters != partCenters;
}

/// Details of one checked entry, used by challenge history and analytics.
class NumberBondAttempt {
  final bool isCorrect;
  final int attemptNumber;
  final bool usedHint;
  final String method;
  final List<int> selectedParts;

  const NumberBondAttempt({
    required this.isCorrect,
    required this.attemptNumber,
    required this.usedHint,
    required this.method,
    this.selectedParts = const [],
  });
}

class InteractiveNumberBondWidget extends StatefulWidget {
  final int operand1;
  final int operand2;
  final ProblemStrategy strategy;
  final bool showSolution;
  final Function(bool isCorrect)? onBondComplete;
  final String? operation;
  final String language;
  final bool compact;
  final bool enabled;
  final NumberBondAttempt? restoredAttempt;
  final ValueChanged<NumberBondAttempt>? onAttemptChecked;

  const InteractiveNumberBondWidget({
    super.key,
    required this.operand1,
    required this.operand2,
    required this.strategy,
    this.showSolution = false,
    this.onBondComplete,
    this.operation,
    this.language = 'en',
    this.compact = false,
    this.enabled = true,
    this.restoredAttempt,
    this.onAttemptChecked,
  });
  @override
  State<InteractiveNumberBondWidget> createState() =>
      _InteractiveNumberBondWidgetState();
}

class _InteractiveNumberBondWidgetState
    extends State<InteractiveNumberBondWidget> {
  List<int?> _parts = [null, null];
  List<int> _availableNumbers = [];
  int? _selectedPartIndex = 0;
  int _attemptCount = 0;
  bool? _isCorrectAnswer;
  bool _showTryAgain = false;
  bool _completionReported = false;
  bool _showFinalSolution = false;
  ValidationResult? _lastValidation;
  Timer? _answerCheckTimer;
  int _entryRevision = 0;
  int? _lastValidatedRevision;
  int _problemRevision = 0;
  int _pickerSession = 0;
  bool _pickerOpen = false;
  BuildContext? _pickerContext;
  int _numberPage = 0;
  bool _hintViewed = false;
  double _branchScrollOffset = 0;

  static const _answerCheckDelay = Duration(milliseconds: 700);

  bool get _entryLocked => _completionReported || !widget.enabled;

  String get _action =>
      widget.operation == 'subtraction' ? 'subtraction' : 'addition';
  String get _operator => _action == 'subtraction' ? '-' : '+';
  String _text(String key, {Map<String, String>? params}) =>
      LanguageService.translate(key, widget.language, params: params);

  @override
  void initState() {
    super.initState();
    _initializeNumbers();
    _restoreSubmittedAttempt();
  }

  void _restoreSubmittedAttempt() {
    final attempt = widget.restoredAttempt;
    if (attempt == null || attempt.selectedParts.isEmpty) return;
    _parts = List<int?>.from(attempt.selectedParts);
    _selectedPartIndex = null;
    _attemptCount = attempt.attemptNumber - (attempt.isCorrect ? 1 : 0);
    _hintViewed = attempt.usedHint;
    _lastValidation = AnswerValidator.validateParts(
      number1: widget.operand1,
      number2: widget.operand2,
      action: _action,
      userParts: attempt.selectedParts,
    );
    _isCorrectAnswer = attempt.isCorrect;
    _completionReported = true;
    _showFinalSolution = true;
    _lastValidatedRevision = _entryRevision;
  }

  @override
  void didUpdateWidget(InteractiveNumberBondWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedProblem =
        oldWidget.operand1 != widget.operand1 ||
        oldWidget.operand2 != widget.operand2 ||
        oldWidget.operation != widget.operation;
    final restartedProblem = oldWidget.showSolution && !widget.showSolution;
    if (widget.showSolution || !widget.enabled) _cancelAnswerCheck();
    if (changedProblem || restartedProblem) {
      _cancelAnswerCheck();
      _problemRevision++;
      _pickerSession++;
      _pickerOpen = false;
      _dismissPicker(_pickerContext);
      _pickerContext = null;
      _entryRevision = 0;
      _lastValidatedRevision = null;
      _numberPage = 0;
      _hintViewed = false;
      _branchScrollOffset = 0;
      _parts = [null, null];
      _selectedPartIndex = 0;
      _attemptCount = 0;
      _isCorrectAnswer = null;
      _showTryAgain = false;
      _completionReported = false;
      _showFinalSolution = false;
      _lastValidation = null;
      _initializeNumbers();
    }
  }

  @override
  void dispose() {
    _cancelAnswerCheck();
    _dismissPicker(_pickerContext);
    super.dispose();
  }

  void _dismissPicker(BuildContext? pickerContext) {
    if (pickerContext == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pickerContext.mounted &&
          ModalRoute.of(pickerContext)?.isCurrent == true) {
        Navigator.of(pickerContext).pop();
      }
    });
  }

  void _initializeNumbers() {
    final suggestions = AnswerValidator.suggestedBreakdowns(
      number1: widget.operand1,
      number2: widget.operand2,
      action: _action,
    );
    // Reserve all supported teaching values, including large remainders.
    _availableNumbers = {
      for (var n = 1; n <= 9 && n <= widget.operand2; n++) n,
      ...suggestions.expand((parts) => parts),
    }.where((n) => n >= 0).toList()..sort();
  }

  void _selectNumber(int number, {int? partIndex}) {
    final index = partIndex ?? _selectedPartIndex;
    if (_entryLocked || index == null || index >= _parts.length) return;
    if (_parts[index] == number) {
      _scheduleAnswerCheck();
      return;
    }
    setState(() {
      _parts[index] = number;
      _entryRevision++;
      final nextEmpty = _parts.indexOf(null);
      _selectedPartIndex = nextEmpty < 0 ? null : nextEmpty;
      _isCorrectAnswer = null;
      _showTryAgain = false;
    });
    _scheduleAnswerCheck();
  }

  void _clearBond() {
    if (!widget.enabled) return;
    _cancelAnswerCheck();
    setState(() {
      _entryRevision++;
      _parts = [null, null];
      _selectedPartIndex = 0;
      _isCorrectAnswer = null;
      _showTryAgain = false;
      // Preserve the last checked explanation and the completion lock.
    });
  }

  void _cancelAnswerCheck() {
    _answerCheckTimer?.cancel();
    _answerCheckTimer = null;
  }

  void _scheduleAnswerCheck() {
    _cancelAnswerCheck();
    if (_entryLocked ||
        widget.showSolution ||
        _pickerOpen ||
        _parts.any((part) => part == null) ||
        _lastValidatedRevision == _entryRevision) {
      return;
    }
    final revision = _entryRevision;
    _answerCheckTimer = Timer(_answerCheckDelay, () {
      _answerCheckTimer = null;
      if (!mounted ||
          !widget.enabled ||
          _entryRevision != revision ||
          _pickerOpen ||
          widget.showSolution) {
        return;
      }
      if (_extendPlaceValueEntry()) return;
      _validateUserAnswer();
    });
  }

  // A complete place-value answer may need more than the initial two circles.
  // Keep a valid unfinished decomposition open so the child can finish it.
  bool _extendPlaceValueEntry() {
    final missing = AnswerValidator.placeValueParts(widget.operand2).toList();
    if (_parts.length >= missing.length) return false;
    for (final part in _parts) {
      if (!missing.remove(part)) return false;
    }
    setState(() {
      _parts.addAll(List<int?>.filled(missing.length, null));
      _selectedPartIndex = _parts.indexOf(null);
    });
    return true;
  }

  Future<void> _openNumberPicker(int index) async {
    if (_entryLocked || _pickerOpen) return;
    _cancelAnswerCheck();
    final problemRevision = _problemRevision;
    final session = ++_pickerSession;
    final selectedNumber = _parts[index];
    final availableNumbers = List<int>.of(_availableNumbers);
    final title = _text(
      'bond_number_picker_title',
      params: {'number': '${index + 1}'},
    );
    final closeLabel = _text('bond_number_picker_close');
    setState(() {
      _selectedPartIndex = index;
      _pickerOpen = true;
    });
    final number = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      builder: (sheetContext) {
        if (!mounted || session != _pickerSession) {
          _dismissPicker(sheetContext);
        } else {
          _pickerContext = sheetContext;
        }
        return SafeArea(
          child: Padding(
            key: const ValueKey('bond-number-picker'),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('bond-picker-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(closeLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableNumbers.map((number) {
                        return _numberChoice(
                          number,
                          key: ValueKey('bond-picker-number-$number'),
                          selected: selectedNumber == number,
                          onTap: () => Navigator.of(sheetContext).pop(number),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || session != _pickerSession) return;
    _pickerContext = null;
    _pickerOpen = false;
    if (problemRevision != _problemRevision || _entryLocked) return;
    if (number != null && index < _parts.length) {
      _selectNumber(number, partIndex: index);
    } else {
      _scheduleAnswerCheck();
    }
  }

  void _validateUserAnswer() {
    if (_entryLocked ||
        widget.showSolution ||
        _parts.any((part) => part == null) ||
        _lastValidatedRevision == _entryRevision) {
      return;
    }
    _lastValidatedRevision = _entryRevision;
    final result = AnswerValidator.validateParts(
      number1: widget.operand1,
      number2: widget.operand2,
      action: _action,
      userParts: _parts.cast<int>(),
    );
    final usedHint = _hintViewed;
    var reportCompletion = false;
    setState(() {
      _lastValidation = result;
      _isCorrectAnswer = result.success;
      if (result.success) {
        _showTryAgain = false;
        _showFinalSolution = true;
        _completionReported = true;
        reportCompletion = true;
      } else {
        _attemptCount++;
        _showTryAgain = _attemptCount < 3;
        if (_attemptCount >= 3) {
          _showFinalSolution = true;
          _completionReported = true;
          reportCompletion = true;
        }
      }
    });
    widget.onAttemptChecked?.call(
      NumberBondAttempt(
        isCorrect: result.success,
        attemptNumber: _attemptCount + (result.success ? 1 : 0),
        usedHint: usedHint,
        method: result.method.name,
        selectedParts: List<int>.unmodifiable(_parts.cast<int>()),
      ),
    );
    if (!widget.compact && _showTryAgain) _hintViewed = true;
    if (reportCompletion) widget.onBondComplete?.call(result.success);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _text('number_bond'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              if (_parts.any((part) => part != null))
                IconButton(
                  onPressed: widget.enabled ? _clearBond : null,
                  icon: const Icon(Icons.refresh),
                  tooltip: _text('bond_clear'),
                ),
            ],
          ),
          Text(
            _text(
              'bond_choose_parts',
              params: {'number': '${widget.operand2}'},
            ),
          ),
          const SizedBox(height: 4),
          Text(_text('bond_auto_check_instruction')),
          const SizedBox(height: 16),
          _buildDiagram(),
          const SizedBox(height: 12),
          Text(_text('tap_numbers_instruction')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableNumbers
                .map(
                  (number) => _numberChoice(
                    number,
                    key: ValueKey('bond-number-$number'),
                    selected: _parts.contains(number),
                    onTap: _entryLocked ? null : () => _selectNumber(number),
                  ),
                )
                .toList(),
          ),
          if (_isCorrectAnswer == true) ...[
            const SizedBox(height: 12),
            Text(
              _text('great_number_bond'),
              style: const TextStyle(color: Colors.green),
            ),
          ],
          if (_showTryAgain) ...[
            const SizedBox(height: 16),
            _buildRetryFeedback(),
          ],
          if (_showFinalSolution || widget.showSolution) ...[
            const SizedBox(height: 16),
            _buildSolution(),
          ],
        ],
      ),
    );
  }

  bool get _hasFeedback =>
      _showTryAgain || _showFinalSolution || widget.showSolution;

  String get _feedbackSummary => _showTryAgain
      ? _text('bond_compact_retry', params: {'count': '${3 - _attemptCount}'})
      : _isCorrectAnswer == true
      ? _text('great_number_bond')
      : _text('step_by_step_solution');

  Widget _buildCompact() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.shade200),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final short = constraints.maxHeight < 300;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      short && _hasFeedback
                          ? _feedbackSummary
                          : _text('number_bond'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: short && _hasFeedback ? 12 : 16,
                        fontWeight: FontWeight.bold,
                        color: _isCorrectAnswer == true
                            ? Colors.green.shade700
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                  if (_parts.any((part) => part != null))
                    IconButton(
                      onPressed: widget.enabled ? _clearBond : null,
                      icon: const Icon(Icons.refresh),
                      tooltip: _text('bond_clear'),
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                    ),
                  if (short && _hasFeedback) _feedbackButton(),
                ],
              ),
            ),
            _buildCompactDiagram(),
            const SizedBox(height: 4),
            Expanded(child: _buildCompactNumbers()),
            if (!short) ...[
              const SizedBox(height: 4),
              if (_hasFeedback)
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _feedbackSummary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isCorrectAnswer == true
                                ? Colors.green.shade700
                                : Colors.orange.shade900,
                          ),
                        ),
                      ),
                      _feedbackButton(),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      _text('bond_compact_instruction'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    ),
  );

  Widget _buildCompactDiagram() => SizedBox(
    height: 64,
    child: Row(
      children: [
        _circle('${widget.operand2}', Colors.purple, size: 44),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const ValueKey('bond-parts-row'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_parts.length, (index) {
                final color = _isCorrectAnswer == true
                    ? Colors.green
                    : _isCorrectAnswer == false
                    ? Colors.orange
                    : Colors.blue;
                return Padding(
                  padding: EdgeInsets.only(left: index == 0 ? 0 : 6),
                  child: _buildPart(index, color),
                );
              }),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildPart(
    int index,
    Color color, {
    double size = 44,
    double labelHeight = 18,
  }) {
    final label = _text('bond_part_label', params: {'number': '${index + 1}'});
    final onTap = _entryLocked ? null : () => _openNumberPicker(index);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          key: ValueKey('bond-part-semantics-$index'),
          label: label,
          value: _parts[index]?.toString() ?? _text('bond_empty_part'),
          button: true,
          enabled: onTap != null,
          selected: _selectedPartIndex == index,
          onTap: onTap,
          excludeSemantics: true,
          child: InkWell(
            key: ValueKey('bond-part-$index'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: _circle(
              '${_parts[index] ?? '?'}',
              color,
              size: size,
              selected: _selectedPartIndex == index,
            ),
          ),
        ),
        ExcludeSemantics(
          child: SizedBox(
            width: size,
            height: labelHeight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size > 44 ? 12 : 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<int> get _compactNumbers {
    final suggestions = AnswerValidator.suggestedBreakdowns(
      number1: widget.operand1,
      number2: widget.operand2,
      action: _action,
    );
    // Put familiar teaching splits on the first page, retaining every choice.
    return {
      ...AnswerValidator.placeValueParts(widget.operand2),
      if (suggestions.isNotEmpty) ...suggestions.first,
      ..._availableNumbers,
    }.where(_availableNumbers.contains).toList();
  }

  Widget _buildCompactNumbers() => LayoutBuilder(
    builder: (context, constraints) {
      const cell = 44.0;
      const gap = 6.0;
      final columns = ((constraints.maxWidth + gap) / (cell + gap))
          .floor()
          .clamp(1, 20);
      final numbers = _compactNumbers;
      final allRows = ((constraints.maxHeight + gap) / (cell + gap)).floor();
      final paged = numbers.length > columns * allRows;
      final gridHeight = constraints.maxHeight - (paged ? 44 : 0);
      final rows = ((gridHeight + gap) / (cell + gap)).floor().clamp(1, 100);
      final capacity = columns * rows;
      final pageCount = (numbers.length / capacity).ceil().clamp(1, 100);
      final page = _numberPage.clamp(0, pageCount - 1);
      final visible = numbers.skip(page * capacity).take(capacity).toList();
      return Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                children: visible.map((number) {
                  return _numberChoice(
                    number,
                    key: ValueKey('bond-number-$number'),
                    selected: _parts.contains(number),
                    onTap: _entryLocked ? null : () => _selectNumber(number),
                    size: cell,
                  );
                }).toList(),
              ),
            ),
          ),
          if (paged)
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const ValueKey('bond-numbers-previous'),
                    tooltip: _text('bond_previous_numbers'),
                    onPressed: page == 0
                        ? null
                        : () => setState(() => _numberPage = page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Semantics(
                    label: _text(
                      'bond_number_page',
                      params: {'current': '${page + 1}', 'total': '$pageCount'},
                    ),
                    child: Text(
                      '${page + 1} / $pageCount',
                      key: const ValueKey('bond-number-page'),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('bond-numbers-next'),
                    tooltip: _text('bond_next_numbers'),
                    onPressed: page + 1 >= pageCount
                        ? null
                        : () => setState(() => _numberPage = page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );

  Widget _feedbackButton() => IconButton(
    key: const ValueKey('bond-feedback-details'),
    tooltip: _text('bond_view_explanation'),
    onPressed: _openFeedback,
    icon: const Icon(Icons.info_outline),
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
  );

  Future<void> _openFeedback() async {
    if (_pickerOpen) return;
    if (_showTryAgain) _hintViewed = true;
    _cancelAnswerCheck();
    final session = ++_pickerSession;
    _pickerOpen = true;
    final title = _text('number_bond');
    final closeLabel = _text('bond_number_picker_close');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: (sheetContext) {
        if (!mounted || session != _pickerSession) {
          _dismissPicker(sheetContext);
          return const SizedBox.shrink();
        }
        _pickerContext = sheetContext;
        return SafeArea(
          child: Padding(
            key: const ValueKey('bond-feedback-sheet'),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('bond-feedback-close'),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(closeLabel),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: _showTryAgain
                        ? _buildRetryFeedback(
                            onClear: () {
                              Navigator.of(sheetContext).pop();
                              if (mounted && session == _pickerSession) {
                                _clearBond();
                              }
                            },
                          )
                        : _buildSolution(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || session != _pickerSession) return;
    _pickerOpen = false;
    _pickerContext = null;
    _scheduleAnswerCheck();
  }

  Widget _buildDiagram() => LayoutBuilder(
    builder: (context, constraints) {
      const circleSize = 56.0;
      const lineHeight = 32.0;
      const labelHeight = 20.0;
      final width = math.min(
        constraints.maxWidth,
        math.max(200.0, _parts.length * 64.0),
      );
      final slotWidth = math.max(circleSize + 4, width / _parts.length);
      final contentWidth = slotWidth * _parts.length;
      final offset = _branchScrollOffset.clamp(
        0.0,
        math.max(0.0, contentWidth - width),
      );
      final color = _isCorrectAnswer == true
          ? Colors.green
          : _isCorrectAnswer == false
          ? Colors.orange
          : Colors.blue;
      return Center(
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: _text('bond_whole_number'),
                value: '${widget.operand2}',
                excludeSemantics: true,
                child: SizedBox(
                  key: const ValueKey('bond-whole'),
                  width: circleSize,
                  height: circleSize,
                  child: _circle(
                    '${widget.operand2}',
                    Colors.purple,
                    size: circleSize,
                  ),
                ),
              ),
              ClipRect(
                child: CustomPaint(
                  key: const ValueKey('bond-branch-lines'),
                  size: Size(width, lineHeight),
                  painter: NumberBondLinePainter(
                    partCount: _parts.length,
                    partCenters: List.generate(
                      _parts.length,
                      (index) => slotWidth * (index + 0.5) - offset,
                    ),
                  ),
                ),
              ),
              NotificationListener<ScrollUpdateNotification>(
                onNotification: (notification) {
                  if (notification.metrics.axis == Axis.horizontal &&
                      _branchScrollOffset != notification.metrics.pixels) {
                    setState(
                      () => _branchScrollOffset = notification.metrics.pixels,
                    );
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  key: const ValueKey('bond-parts-row'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: contentWidth,
                    child: Row(
                      children: List.generate(
                        _parts.length,
                        (index) => SizedBox(
                          width: slotWidth,
                          child: _buildPart(
                            index,
                            color,
                            size: circleSize,
                            labelHeight: labelHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _numberChoice(
    int number, {
    required Key key,
    required bool selected,
    required VoidCallback? onTap,
    double size = 50,
  }) => Semantics(
    label: '$number',
    button: true,
    enabled: onTap != null,
    selected: selected,
    onTap: onTap,
    excludeSemantics: true,
    child: InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.blue[600] : Colors.blue[100],
          borderRadius: BorderRadius.circular(25),
        ),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$number',
              style: TextStyle(
                fontSize: 18,
                color: selected ? Colors.white : Colors.blue[800],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _circle(
    String value,
    Color color, {
    bool selected = false,
    double size = 56,
  }) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      shape: BoxShape.circle,
      border: Border.all(color: color, width: selected ? 3 : 1),
    ),
    child: FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Text(value, style: TextStyle(fontSize: 20, color: color)),
      ),
    ),
  );

  Widget _buildRetryFeedback({VoidCallback? onClear}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange[50],
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_text('oops_try_different')),
        const SizedBox(height: 8),
        Text(
          _text(
            'bond_retry_split',
            params: {
              'number': '${widget.operand2}',
              'parts': _lastValidation!.solutionParts.join(' + '),
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _text('more_chances_hero', params: {'count': '${3 - _attemptCount}'}),
        ),
        TextButton(
          onPressed: onClear ?? _clearBond,
          child: Text(_text('clear_try_again')),
        ),
      ],
    ),
  );

  Widget _buildSolution() {
    final result =
        _lastValidation ??
        AnswerValidator.validateParts(
          number1: widget.operand1,
          number2: widget.operand2,
          action: _action,
          userParts: const [],
        );
    var intermediate = widget.operand1;
    final steps = <String>[];
    for (final part in result.solutionParts) {
      final next = _action == 'subtraction'
          ? intermediate - part
          : intermediate + part;
      steps.add('$intermediate $_operator $part = $next');
      intermediate = next;
    }
    final methodKey = switch (result.method) {
      BondMethod.placeValue => 'bond_place_value_strategy',
      BondMethod.makeTen => 'make_ten_strategy',
      BondMethod.basic => 'basic_strategy',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _text('step_by_step_solution'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_text(methodKey)),
          const SizedBox(height: 8),
          Text(
            _text(
              'bond_breakdown',
              params: {
                'number': '${widget.operand2}',
                'parts': result.solutionParts.join(' + '),
              },
            ),
          ),
          const SizedBox(height: 8),
          for (final step in steps) Text(step),
        ],
      ),
    );
  }
}
