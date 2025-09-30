import 'package:flutter/material.dart';

class AgeSelector extends StatelessWidget {
  final int? selectedAge;
  final Function(int) onAgeSelected;
  final String language;

  const AgeSelector({
    super.key,
    required this.selectedAge,
    required this.onAgeSelected,
    this.language = 'en',
  });

  String _getText(String key) {
    final translations = {
      'en': {'years': 'years'},
      'es': {'years': 'años'},
      'fr': {'years': 'ans'},
    };
    return translations[language]?[key] ?? translations['en']?[key] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [4, 5, 6, 7].map((age) {
        final isSelected = selectedAge == age;
        
        return GestureDetector(
          onTap: () => onAgeSelected(age),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3498DB) : Colors.white,
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: isSelected ? const Color(0xFF3498DB) : Colors.grey.shade300,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3498DB).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    age.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    _getText('years'),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

