import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/kid_profile.dart';
import '../providers/profile_provider.dart';
import '../services/language_service.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  String _getText(String key, String language) {
    final translations = {
      'en': {
        'welcome': 'Welcome',
        'profile_history': 'Profile History',
        'age': 'Age',
        'language': 'Language',
        'stars': 'stars',
        'problems': 'problems',
        'intelligent_challenge': 'Intelligent Math Challenge',
        'adapts_skill': 'Adapts to your skill level',
        'my_profile': 'My Profile',
        'error': 'Error',
        'no_profile': 'No profile found',
      },
      'es': {
        'welcome': 'Bienvenido',
        'profile_history': 'Historial del Perfil',
        'age': 'Edad',
        'language': 'Idioma',
        'stars': 'estrellas',
        'problems': 'problemas',
        'intelligent_challenge': 'Desafío Matemático Inteligente',
        'adapts_skill': 'Se adapta a tu nivel de habilidad',
        'my_profile': 'Mi Perfil',
        'error': 'Error',
        'no_profile': 'No se encontró perfil',
      },
      'fr': {
        'welcome': 'Bienvenue',
        'profile_history': 'Historique du Profil',
        'age': 'Âge',
        'language': 'Langue',
        'stars': 'étoiles',
        'problems': 'problèmes',
        'intelligent_challenge': 'Défi Mathématique Intelligent',
        'adapts_skill': 'S\'adapte à votre niveau de compétence',
        'my_profile': 'Mon Profil',
        'error': 'Erreur',
        'no_profile': 'Aucun profil trouvé',
      },
    };
    
    return translations[language]?[key] ?? translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('No profile found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${_getText('welcome', profile.language)} ${profile.name}!'),
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false, // Remove back button
            actions: const [], // Explicitly remove any actions/icons
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3498DB),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text('🐱', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('${_getText('age', profile.language)}: ${profile.age} • ${_getText('language', profile.language)}: ${LanguageService.getFlag(profile.language)} ${LanguageService.getLanguageName(profile.language)}'),
                              Text('⭐ ${profile.totalStars} ${_getText('stars', profile.language)} • 📚 ${profile.totalProblemsCompleted} ${_getText('problems', profile.language)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Intelligent Math Challenge mode button
                SizedBox(
                  width: double.infinity,
                  height: 88,
                  child: ElevatedButton(
                    onPressed: () => context.go('/challenge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 22),
                        const SizedBox(height: 3),
                        Text(
                          _getText('intelligent_challenge', profile.language),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getText('adapts_skill', profile.language),
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Profile button (unified)
                SizedBox(
                  width: double.infinity,
                  height: 70,
                  child: ElevatedButton(
                    onPressed: () => context.go('/profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 26),
                        const SizedBox(height: 2),
                        Text(
                          _getText('my_profile', profile.language),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }

}
