import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/language_service.dart';

/// Collects a birth year without guessing a month or day.
class BirthYearSelector extends StatelessWidget {
  final int? selectedBirthYear;
  final ValueChanged<int> onBirthYearSelected;
  final String language;
  final int minAge;
  final int maxAge;
  final DateTime? currentDate;
  final bool enabled;
  final bool showAgeOptions;

  const BirthYearSelector({
    super.key,
    required this.selectedBirthYear,
    required this.onBirthYearSelected,
    this.language = 'en',
    this.minAge = AppConstants.minAge,
    this.maxAge = AppConstants.maxAge,
    this.currentDate,
    this.enabled = true,
    this.showAgeOptions = false,
  }) : assert(minAge >= 0),
       assert(maxAge >= minAge);

  String _text(String key, {Map<String, String>? params}) =>
      LanguageService.translate(key, language, params: params);

  @override
  Widget build(BuildContext context) {
    final year = (currentDate ?? DateTime.now()).year;
    final years = <int>{
      for (var age = minAge; age <= maxAge; age++)
        if (year - age > 0) year - age,
      // Keep a saved birth year visible as the child grows past the range.
      if (selectedBirthYear != null &&
          selectedBirthYear! > 0 &&
          selectedBirthYear! <= year)
        selectedBirthYear!,
    }.toList()..sort((a, b) => b.compareTo(a));
    final selectedYear = years.contains(selectedBirthYear)
        ? selectedBirthYear
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: _text(
              showAgeOptions ? 'profile_age' : 'birth_year_label',
            ),
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              key: const ValueKey('birth-year-dropdown'),
              value: selectedYear,
              isExpanded: true,
              hint: Text(
                _text(showAgeOptions ? 'select_age' : 'select_birth_year'),
              ),
              items: years
                  .map(
                    (birthYear) => DropdownMenuItem(
                      value: birthYear,
                      child: Text(
                        showAgeOptions ? '${year - birthYear}' : '$birthYear',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (birthYear) {
                      if (birthYear != null) onBirthYearSelected(birthYear);
                    }
                  : null,
            ),
          ),
        ),
        if (selectedYear != null) ...[
          const SizedBox(height: 8),
          Text(
            _text('age_this_year', params: {'age': '${year - selectedYear}'}),
            key: const ValueKey('birth-year-age-preview'),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _text('birth_year_age_explanation'),
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
