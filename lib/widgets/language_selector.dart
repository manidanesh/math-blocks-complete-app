import 'package:flutter/material.dart';

class Language {
  final String code;
  final String name;
  final String flag;

  const Language({
    required this.code,
    required this.name,
    required this.flag,
  });

  static const List<Language> availableLanguages = [
    Language(code: 'en', name: 'English', flag: '🇺🇸'),
    Language(code: 'es', name: 'Español', flag: '🇪🇸'),
    Language(code: 'fr', name: 'Français', flag: '🇫🇷'),
  ];
}

class LanguageSelector extends StatelessWidget {
  final String selectedLanguageCode;
  final Function(String) onLanguageSelected;

  const LanguageSelector({
    super.key,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language options
        Row(
          children: Language.availableLanguages.map((language) {
            final isSelected = selectedLanguageCode == language.code;
            
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => onLanguageSelected(language.code),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF3498DB)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF3498DB)
                            : Colors.grey.shade300,
                        width: 2,
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
                    child: Column(
                      children: [
                        Text(
                          language.flag,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          language.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? Colors.white
                                : const Color(0xFF2C3E50),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // Selected language info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF3498DB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                _getSelectedLanguage().flag,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSelectedLanguage().name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getWelcomeMessage(),
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF3498DB).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Language _getSelectedLanguage() {
    return Language.availableLanguages.firstWhere(
      (language) => language.code == selectedLanguageCode,
      orElse: () => Language.availableLanguages.first,
    );
  }

  String _getWelcomeMessage() {
    switch (selectedLanguageCode) {
      case 'es':
        return '¡Aprenderemos matemáticas juntos!';
      case 'fr':
        return 'Nous apprendrons les maths ensemble!';
      default:
        return 'We\'ll learn math together!';
    }
  }
}

