import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/kid_profile.dart';
import '../providers/profile_provider.dart';
import '../widgets/language_selector.dart';
import '../widgets/age_selector.dart';
import '../widgets/favorite_numbers_selector.dart';

class ProfileCreationScreen extends ConsumerStatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  ConsumerState<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends ConsumerState<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  int? selectedAge;
  String selectedLanguageCode = 'en';
  List<int> favoriteNumbers = [];
  bool isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _canCreateProfile {
    return _nameController.text.trim().isNotEmpty &&
           selectedAge != null;
  }

  Future<void> _createProfile() async {
    if (!_canCreateProfile) return;

    setState(() {
      isLoading = true;
    });

    try {
      final profile = KidProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        age: selectedAge!,
        avatarId: 'default',
        language: selectedLanguageCode,
        isCurrent: true,
        createdAt: DateTime.now(),
        lastPlayed: DateTime.now(),
        favoriteNumbers: favoriteNumbers,
      );

      await ref.read(profileProvider.notifier).createProfile(profile);
      
      if (mounted) {
        context.go('/mode-select');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _getText(String key) {
    final translations = {
      'en': {
        'welcome_message': 'Welcome to Math Blocks!\nLet\'s create your profile!',
        'welcome_title': 'Welcome to Math Blocks!',
        'name_label': 'Name',
        'enter_name': 'Enter your name',
        'name_entered': 'Name entered',
        'age_label': 'Age',
        'age_selected': 'Age selected', 
        'language_label': 'Language',
        'language_selected': 'Language selected',
        'favorite_numbers': 'Favorite Numbers',
        'optional': '(Optional)',
        'select_favorites': 'Select your favorite numbers to use in problems',
        'favorite_numbers_subtitle': 'Choose your favorite numbers (0-9):',
        'favorite_numbers_instruction': 'Select up to {count} numbers you like!',
        'no_numbers_selected': 'No numbers selected yet',
        'numbers_selected': 'Selected {current} of {max} numbers',
        'perfect_selection': 'Perfect! You\'ve selected {count} favorite numbers',
        'create_profile_button': 'Create Profile',
        'creating_profile': 'Creating Profile...',
        'error_creating': 'Error creating profile',
      },
      'es': {
        'welcome_message': '¡Bienvenido a Math Blocks!\n¡Vamos a crear tu perfil!',
        'welcome_title': '¡Bienvenido a Math Blocks!',
        'name_label': 'Nombre',
        'enter_name': 'Escribe tu nombre',
        'name_entered': 'Nombre ingresado',
        'age_label': 'Edad',
        'age_selected': 'Edad seleccionada',
        'language_label': 'Idioma',
        'language_selected': 'Idioma seleccionado',
        'favorite_numbers': 'Números Favoritos',
        'optional': '(Opcional)',
        'select_favorites': 'Selecciona tus números favoritos para usar en problemas',
        'favorite_numbers_subtitle': 'Elige tus números favoritos (0-9):',
        'favorite_numbers_instruction': '¡Selecciona hasta {count} números que te gusten!',
        'no_numbers_selected': 'Aún no hay números seleccionados',
        'numbers_selected': 'Seleccionados {current} de {max} números',
        'perfect_selection': '¡Perfecto! Has seleccionado {count} números favoritos',
        'create_profile_button': 'Crear Perfil',
        'creating_profile': 'Creando Perfil...',
        'error_creating': 'Error al crear perfil',
      },
      'fr': {
        'welcome_message': 'Bienvenue à Math Blocks!\nCréons ton profil!',
        'welcome_title': 'Bienvenue à Math Blocks!',
        'name_label': 'Nom',
        'enter_name': 'Entrez votre nom',
        'name_entered': 'Nom saisi',
        'age_label': 'Âge',
        'age_selected': 'Âge sélectionné',
        'language_label': 'Langue',
        'language_selected': 'Langue sélectionnée',
        'favorite_numbers': 'Nombres Favoris',
        'optional': '(Optionnel)',
        'select_favorites': 'Sélectionnez vos nombres favoris à utiliser dans les problèmes',
        'favorite_numbers_subtitle': 'Choisissez vos numéros favoris (0-9):',
        'favorite_numbers_instruction': 'Sélectionnez jusqu\'à {count} numéros que vous aimez!',
        'no_numbers_selected': 'Aucun numéro sélectionné pour le moment',
        'numbers_selected': 'Sélectionnés {current} de {max} numéros',
        'perfect_selection': 'Parfait! Vous avez sélectionné {count} numéros favoris',
        'create_profile_button': 'Créer le Profil',
        'creating_profile': 'Création du Profil...',
        'error_creating': 'Erreur lors de la création du profil',
      },
    };
    
    return translations[selectedLanguageCode]?[key] ?? translations['en']![key]!;
  }

  String _getWelcomeMessage() {
    return _getText('welcome_message');
  }

  String _getCreateButtonText() {
    return _getText('create_profile_button');
  }

  String _getNameHint() {
    return _getText('enter_name');
  }

  @override
  Widget build(BuildContext context) {
    // Check if profile already exists and redirect to mode select
    ref.listen(profileProvider, (previous, next) {
      if (next.value != null && mounted) {
        context.go('/mode-select');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_getWelcomeMessage().split('\n')[0]),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message - made more compact
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getWelcomeMessage(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Name input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👤 ${_getText('name_label')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: _getNameHint(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        style: const TextStyle(fontSize: 18),
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Age selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎂 ${_getText('age_label')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgeSelector(
                        selectedAge: selectedAge,
                        language: selectedLanguageCode,
                        onAgeSelected: (age) {
                          setState(() {
                            selectedAge = age;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Language selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🌍 ${_getText('language_label')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LanguageSelector(
                        selectedLanguageCode: selectedLanguageCode,
                        onLanguageSelected: (languageCode) {
                          setState(() {
                            selectedLanguageCode = languageCode;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Favorite numbers selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⭐ ${_getText('favorite_numbers')}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FavoriteNumbersSelector(
                        initialFavorites: favoriteNumbers,
                        language: selectedLanguageCode,
                        onChanged: (numbers) {
                          setState(() {
                            favoriteNumbers = numbers;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Create profile button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _canCreateProfile && !isLoading ? _createProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canCreateProfile ? const Color(0xFF2ECC71) : Colors.grey,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_getCreateButtonText()),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Profile requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildRequirement(_getText('name_entered'), _nameController.text.trim().isNotEmpty),
                    _buildRequirement(_getText('age_selected'), selectedAge != null),
                    _buildRequirement(_getText('language_selected'), true), // Always true
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isComplete) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isComplete ? Colors.green : Colors.grey,
              fontWeight: isComplete ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
