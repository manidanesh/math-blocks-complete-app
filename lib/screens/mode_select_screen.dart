import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/kid_profile.dart';
import '../providers/profile_provider.dart';
import '../services/language_service.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  String _getText(String key, String language) {
    const translations = {
      'en': {
        'welcome': 'Welcome',
        'age': 'Age',
        'language': 'Language',
        'stars': 'stars',
        'problems': 'problems',
        'intelligent_challenge': 'Intelligent Math Challenge',
        'adapts_skill': 'Adapts to your skill level',
        'my_profile': 'My Profile',
        'profile_error': 'Unable to load your profile.',
        'no_profile': 'Create a profile to start learning.',
        'create_profile': 'Create Profile',
        'try_again': 'Try again',
      },
      'es': {
        'welcome': 'Bienvenido',
        'age': 'Edad',
        'language': 'Idioma',
        'stars': 'estrellas',
        'problems': 'problemas',
        'intelligent_challenge': 'Desafío Matemático Inteligente',
        'adapts_skill': 'Se adapta a tu nivel de habilidad',
        'my_profile': 'Mi Perfil',
        'profile_error': 'No se pudo cargar tu perfil.',
        'no_profile': 'Crea un perfil para empezar a aprender.',
        'create_profile': 'Crear Perfil',
        'try_again': 'Inténtalo de nuevo',
      },
      'fr': {
        'welcome': 'Bienvenue',
        'age': 'Âge',
        'language': 'Langue',
        'stars': 'étoiles',
        'problems': 'problèmes',
        'intelligent_challenge': 'Défi Mathématique Intelligent',
        'adapts_skill': "S'adapte à votre niveau de compétence",
        'my_profile': 'Mon Profil',
        'profile_error': 'Impossible de charger ton profil.',
        'no_profile': 'Crée un profil pour commencer à apprendre.',
        'create_profile': 'Créer le Profil',
        'try_again': 'Réessayer',
      },
    };
    return translations[language]?[key] ?? translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final language =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => _buildRecovery(
        context,
        language,
        onRetry: () => ref.invalidate(profileProvider),
      ),
      data: (profile) => profile == null
          ? _buildRecovery(context, language)
          : _buildHome(context, profile),
    );
  }

  Widget _buildRecovery(
    BuildContext context,
    String language, {
    VoidCallback? onRetry,
  }) => Scaffold(
    appBar: AppBar(title: Text(_getText('welcome', language))),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getText(
                  onRetry == null ? 'no_profile' : 'profile_error',
                  language,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (onRetry == null)
                ElevatedButton(
                  key: const ValueKey('home-create-profile'),
                  onPressed: () => context.go('/profile-creation'),
                  child: Text(_getText('create_profile', language)),
                )
              else
                ElevatedButton(
                  key: const ValueKey('home-retry-profile'),
                  onPressed: onRetry,
                  child: Text(_getText('try_again', language)),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildHome(BuildContext context, KidProfile profile) => Scaffold(
    appBar: AppBar(
      title: Text(
        '${_getText('welcome', profile.language)} ${profile.name}!',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      backgroundColor: const Color(0xFF3498DB),
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
    ),
    body: SafeArea(
      top: false,
      child: SingleChildScrollView(
        key: const ValueKey('home-scroll'),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileSummary(profile),
                const SizedBox(height: 24),
                _buildModeButton(
                  key: const ValueKey('home-challenge'),
                  icon: Icons.auto_awesome,
                  label: _getText('intelligent_challenge', profile.language),
                  subtitle: _getText('adapts_skill', profile.language),
                  color: const Color(0xFF9B59B6),
                  onPressed: () => context.go('/challenge'),
                ),
                const SizedBox(height: 16),
                _buildModeButton(
                  key: const ValueKey('home-profile'),
                  icon: Icons.person,
                  label: _getText('my_profile', profile.language),
                  color: const Color(0xFF3498DB),
                  onPressed: () => context.go('/profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildProfileSummary(KidProfile profile) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFF3498DB),
            child: Text('🐱', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_getText('age', profile.language)}: ${profile.age} • '
                  '${_getText('language', profile.language)}: '
                  '${LanguageService.getFlag(profile.language)} '
                  '${LanguageService.getLanguageName(profile.language)}',
                ),
                Text(
                  '⭐ ${profile.totalStars} '
                  '${_getText('stars', profile.language)} • '
                  '📚 ${profile.totalProblemsCompleted} '
                  '${_getText('problems', profile.language)}',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildModeButton({
    required Key key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    String? subtitle,
  }) => ElevatedButton(
    key: key,
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13)),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
