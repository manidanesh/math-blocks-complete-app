import 'package:flutter/material.dart';

class FavoriteNumbersSelector extends StatefulWidget {
  final List<int> initialFavorites;
  final Function(List<int>) onChanged;
  final int maxSelections;
  final String language;

  const FavoriteNumbersSelector({
    super.key,
    required this.initialFavorites,
    required this.onChanged,
    this.maxSelections = 3,
    this.language = 'en',
  });

  @override
  State<FavoriteNumbersSelector> createState() => _FavoriteNumbersSelectorState();
}

class _FavoriteNumbersSelectorState extends State<FavoriteNumbersSelector> {
  late List<int> _selectedNumbers;

  @override
  void initState() {
    super.initState();
    _selectedNumbers = List.from(widget.initialFavorites);
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'favorite_numbers_subtitle': 'Choose your favorite numbers (0-9):',
        'favorite_numbers_instruction': 'Select up to {count} numbers you like!',
        'no_numbers_selected': 'No numbers selected yet',
        'numbers_selected': 'Selected {current} of {max} numbers',
        'perfect_selection': 'Perfect! You\'ve selected {count} favorite numbers',
      },
      'es': {
        'favorite_numbers_subtitle': 'Elige tus números favoritos (0-9):',
        'favorite_numbers_instruction': '¡Selecciona hasta {count} números que te gusten!',
        'no_numbers_selected': 'Aún no hay números seleccionados',
        'numbers_selected': 'Seleccionados {current} de {max} números',
        'perfect_selection': '¡Perfecto! Has seleccionado {count} números favoritos',
      },
      'fr': {
        'favorite_numbers_subtitle': 'Choisissez vos numéros favoris (0-9):',
        'favorite_numbers_instruction': 'Sélectionnez jusqu\'à {count} numéros que vous aimez!',
        'no_numbers_selected': 'Aucun numéro sélectionné pour le moment',
        'numbers_selected': 'Sélectionnés {current} de {max} numéros',
        'perfect_selection': 'Parfait! Vous avez sélectionné {count} numéros favoris',
      }
    };
    
    return translations[widget.language]?[key] ?? translations['en']![key]!;
  }

  String _getTextWithPlaceholders(String key, Map<String, dynamic> placeholders) {
    String text = _getText(key);
    placeholders.forEach((placeholder, value) {
      text = text.replaceAll('{$placeholder}', value.toString());
    });
    return text;
  }

  void _toggleNumber(int number) {
    setState(() {
      if (_selectedNumbers.contains(number)) {
        _selectedNumbers.remove(number);
      } else if (_selectedNumbers.length < widget.maxSelections) {
        _selectedNumbers.add(number);
      }
    });
    widget.onChanged(_selectedNumbers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getText('favorite_numbers_subtitle'),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getTextWithPlaceholders('favorite_numbers_instruction', {'count': widget.maxSelections}),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Numbers grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 10, // 0-9
          itemBuilder: (context, index) {
            final number = index;
            final isSelected = _selectedNumbers.contains(number);
            final canSelect = _selectedNumbers.length < widget.maxSelections || isSelected;
            
            return GestureDetector(
              onTap: canSelect ? () => _toggleNumber(number) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[600] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 16),
        
        // Selection status
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _selectedNumbers.isEmpty 
                ? Colors.grey[50] 
                : _selectedNumbers.length == widget.maxSelections
                    ? Colors.green[50]
                    : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedNumbers.isEmpty 
                  ? Colors.grey[300]! 
                  : _selectedNumbers.length == widget.maxSelections
                      ? Colors.green[300]!
                      : Colors.blue[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _selectedNumbers.isEmpty 
                    ? Icons.info_outline
                    : _selectedNumbers.length == widget.maxSelections
                        ? Icons.check_circle
                        : Icons.favorite,
                color: _selectedNumbers.isEmpty 
                    ? Colors.grey[600]
                    : _selectedNumbers.length == widget.maxSelections
                        ? Colors.green[600]
                        : Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedNumbers.isEmpty
                      ? _getText('no_numbers_selected')
                      : _selectedNumbers.length == widget.maxSelections
                          ? _getTextWithPlaceholders('perfect_selection', {'count': _selectedNumbers.length})
                          : _getTextWithPlaceholders('numbers_selected', {'current': _selectedNumbers.length, 'max': widget.maxSelections}),
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedNumbers.isEmpty 
                        ? Colors.grey[600]
                        : _selectedNumbers.length == widget.maxSelections
                            ? Colors.green[600]
                            : Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
