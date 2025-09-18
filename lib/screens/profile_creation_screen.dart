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

  String _getWelcomeMessage() {
    switch (selectedLanguageCode) {
      case 'es':
        return '¡Bienvenido a Math Blocks!\n¡Vamos a crear tu perfil!';
      case 'fr':
        return 'Bienvenue à Math Blocks!\nCréons ton profil!';
      default:
        return 'Welcome to Math Blocks!\nLet\'s create your profile!';
    }
  }

  String _getCreateButtonText() {
    switch (selectedLanguageCode) {
      case 'es':
        return 'Crear Perfil';
      case 'fr':
        return 'Créer le Profil';
      default:
        return 'Create Profile';
    }
  }

  String _getNameHint() {
    switch (selectedLanguageCode) {
      case 'es':
        return 'Escribe tu nombre';
      case 'fr':
        return 'Écris ton nom';
      default:
        return 'Enter your name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getWelcomeMessage().split('\n')[0]),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome message
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getWelcomeMessage(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Name input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '👤 Your Name',
                        style: TextStyle(
                          fontSize: 18,
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
              
              const SizedBox(height: 24),
              
              // Age selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎂 Your Age',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AgeSelector(
                        selectedAge: selectedAge,
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
              
              const SizedBox(height: 24),
              
              // Language selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌍 Choose Your Language',
                        style: TextStyle(
                          fontSize: 18,
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
              
              const SizedBox(height: 24),
              
              // Favorite numbers selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⭐ Choose Your Favorite Numbers',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FavoriteNumbersSelector(
                        initialFavorites: favoriteNumbers,
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
              
              const SizedBox(height: 32),
              
              // Create profile button
              SizedBox(
                height: 60,
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
                    _buildRequirement('Name entered', _nameController.text.trim().isNotEmpty),
                    _buildRequirement('Age selected', selectedAge != null),
                    _buildRequirement('Language selected', true), // Always true
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
