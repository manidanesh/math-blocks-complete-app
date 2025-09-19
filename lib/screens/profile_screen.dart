import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/kid_profile.dart';
import '../models/problem_attempt.dart';
import '../models/adaptive_challenge.dart';
import '../providers/profile_provider.dart';
import '../services/problem_attempt_service.dart';
import '../services/adaptive_problem_service.dart';
import '../widgets/favorite_numbers_selector.dart';
import '../widgets/language_selector.dart';
import '../widgets/adaptive_challenge_display.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  List<ProblemAttempt> _failedAttempts = [];
  List<int> _tempFavoriteNumbers = [];
  bool _isLoading = true;
  bool _isEditing = false;
  String _tempLanguage = '';
  String _tempPreferredOperation = 'both';
  PerformanceMetrics? _performanceMetrics;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileAsync = ref.read(profileProvider);
      if (profileAsync.value != null) {
        await _loadPerformanceData(profileAsync.value!.id);
        await _loadAdaptiveMetrics(profileAsync.value!.id);
        setState(() {
          _tempFavoriteNumbers = List.from(profileAsync.value!.favoriteNumbers);
          _tempLanguage = profileAsync.value!.language;
          _tempPreferredOperation = profileAsync.value!.preferredOperation;
        });
      }
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPerformanceData(String profileId) async {
    try {
      final attempts = await ProblemAttemptService.getAttemptsForChild(profileId);
      _failedAttempts = await ProblemAttemptService.getUniqueFailedAttempts(profileId);
      
      final correctAttempts = attempts.where((a) => a.isCorrect).length;
      final totalAttempts = attempts.length;
      final accuracy = totalAttempts > 0 ? correctAttempts / totalAttempts : 0.0;
      
      // Debug information
      print('🔍 Profile Data Debug:');
      print('  Total attempts: $totalAttempts');
      print('  Failed attempts: ${_failedAttempts.length}');
      print('  Correct attempts: $correctAttempts');
      print('  Calculated accuracy: ${(accuracy * 100).toInt()}%');
      
      // Update profile stats to match actual data
      final currentProfile = ref.read(profileProvider).value;
      if (currentProfile != null) {
        // Check if profile stats need updating
        if (currentProfile.totalProblemsCompleted != totalAttempts || 
            (currentProfile.overallAccuracy - accuracy).abs() > 0.01) {
          
          print('🔄 Updating profile stats to match actual data');
          final updatedProfile = currentProfile.copyWith(
            totalProblemsCompleted: totalAttempts,
            totalStars: correctAttempts, // 1 star per correct problem
            overallAccuracy: accuracy,
            lastPlayed: DateTime.now(),
          );
          
          await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
        }
      }
    } catch (e) {
      print('Error loading performance data: $e');
    }
  }

  Future<void> _loadAdaptiveMetrics(String profileId) async {
    try {
      final metrics = await AdaptiveProblemService.getPerformanceMetrics(profileId);
      setState(() {
        _performanceMetrics = metrics;
      });
    } catch (e) {
      print('Error loading adaptive metrics: $e');
    }
  }


  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      // Reset to original values
      final profile = ref.read(profileProvider).value;
      _tempFavoriteNumbers = List.from(profile?.favoriteNumbers ?? []);
    });
  }


  Future<void> _saveChanges() async {
    final profile = ref.read(profileProvider).value;
    if (profile == null) return;

    final updatedProfile = profile.copyWith(
      favoriteNumbers: _tempFavoriteNumbers,
    );

    await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
    
    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Favorite numbers updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).value;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: Text('No profile found')),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${profile.name}\'s Profile'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mode-select'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Age: ${profile.age}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Language: ${profile.language.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _getText('stars'),
                            profile.totalStars.toString(),
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _getText('problems'),
                            profile.totalProblemsCompleted.toString(),
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _getText('accuracy'),
                            '${(profile.overallAccuracy * 100).toInt()}%',
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Language Settings Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        _getText('language_settings'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    LanguageSelector(
                      selectedLanguageCode: _tempLanguage,
                      onLanguageSelected: (languageCode) async {
                        setState(() {
                          _tempLanguage = languageCode;
                        });
                        // Save immediately when language is selected
                        final profile = ref.read(profileProvider).value;
                        if (profile != null) {
                          final updatedProfile = profile.copyWith(language: languageCode);
                          await ref.read(profileProvider.notifier).updateProfile(updatedProfile);
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Language updated successfully!'),
                                backgroundColor: Colors.green,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Performance Overview (Adaptive Challenge Metrics)
            if (_performanceMetrics != null) ...[
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getText('adaptive_performance'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PerformanceMetricsDisplay(metrics: _performanceMetrics!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Failed Challenges Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('try_again'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_failedAttempts.isNotEmpty) ...[
                      Text(
                        _getText('review_challenges'),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Show last 5 failed attempts
                      ...(_failedAttempts.take(5).map((attempt) => _buildFailedChallengeItem(attempt)).toList()),
                      
                      if (_failedAttempts.length > 5) ...[
                        const SizedBox(height: 8),
                        Text(
                          '... and ${_failedAttempts.length - 5} more failed challenges',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.green[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No failed challenges yet!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getText('no_failed_attempts'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Favorite Numbers Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getText('favorite_numbers'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!_isEditing)
                          TextButton.icon(
                            onPressed: _startEditing,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(_getText('edit')),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isEditing) ...[
                      FavoriteNumbersSelector(
                        initialFavorites: _tempFavoriteNumbers,
                        onChanged: (numbers) {
                          setState(() {
                            _tempFavoriteNumbers = numbers;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _cancelEditing,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      if (profile.favoriteNumbers.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.favoriteNumbers.map((number) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.blue[300]!),
                              ),
                              child: Text(
                                number.toString(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getText('favorite_numbers_description'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No favorite numbers set yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getText('tap_edit_to_choose'),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Reset Progress Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetProgressDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(_getResetButtonText()),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Back to Home Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/mode-select'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.home),
                label: Text(_getText('back_to_home')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFailedChallengeItem(ProblemAttempt attempt) {
    final timeAgo = DateTime.now().difference(attempt.timestamp);
    String timeString;
    
    if (timeAgo.inDays > 0) {
      final unit = timeAgo.inDays == 1 ? _getText('day') : _getText('days');
      timeString = _tempLanguage == 'es' || _tempLanguage == 'fr' 
          ? '${_getText('time_ago')} ${timeAgo.inDays} $unit'
          : '${timeAgo.inDays} $unit ${_getText('time_ago')}';
    } else if (timeAgo.inHours > 0) {
      final unit = timeAgo.inHours == 1 ? _getText('hour') : _getText('hours');
      timeString = _tempLanguage == 'es' || _tempLanguage == 'fr' 
          ? '${_getText('time_ago')} ${timeAgo.inHours} $unit'
          : '${timeAgo.inHours} $unit ${_getText('time_ago')}';
    } else if (timeAgo.inMinutes > 0) {
      final unit = timeAgo.inMinutes == 1 ? _getText('minute') : _getText('minutes');
      timeString = _tempLanguage == 'es' || _tempLanguage == 'fr' 
          ? '${_getText('time_ago')} ${timeAgo.inMinutes} $unit'
          : '${timeAgo.inMinutes} $unit ${_getText('time_ago')}';
    } else {
      timeString = _getText('just_now');
    }

    return GestureDetector(
      onTap: () {
        // Navigate to challenge screen with this specific problem for explanation
        context.go('/challenge', extra: {
          'problem': {
            'operand1': attempt.operand1,
            'operand2': attempt.operand2,
            'operator': attempt.operator,
            'correctAnswer': attempt.correctAnswer,
            'strategy': attempt.strategy,
          },
          'showExplanation': true,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.close,
              color: Colors.red[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attempt.problemText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_getText('your_answer')} ${attempt.userAnswer ?? _getText('no_answer')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Translation methods for all profile screen text
  String _getText(String key) {
    final translations = {
      'en': {
        'profile_title': 'Profile',
        'language_settings': '🌍 Language Settings',
        'language_instruction': 'Select your preferred language:',
        'stars': '⭐ Stars',
        'problems': '🎯 Problems',
        'accuracy': '📊 Accuracy',
        'adaptive_performance': '🎯 Adaptive Challenge Performance',
        'try_again': '🤔 You want to try one more time?',
        'no_failed_attempts': 'Great job! 🎉 No failed attempts yet.',
        'back_to_home': 'Back to Home',
        'reset_progress': 'Reset Progress',
        'reset_dialog_title': 'Reset Progress',
        'reset_dialog_content': 'Are you sure you want to reset all progress?',
        'reset_dialog_delete': 'This will permanently delete:',
        'reset_item_history': '• All challenge history',
        'reset_item_stats': '• Performance statistics',
        'reset_item_stars': '• Stars and completed problems',
        'reset_item_attempts': '• Failed attempts records',
        'reset_dialog_note': 'Your profile information (name, age, language) will be kept.',
        'cancel': 'Cancel',
        'resetting': 'Resetting progress...',
        'reset_success': '✅ Progress reset successfully! Starting fresh!',
        'your_answer': 'Your answer:',
        'no_answer': 'No answer',
        'time_ago': 'ago',
        'just_now': 'just now',
        'minutes_ago': 'minutes ago',
        'hours_ago': 'hours ago',
        'days_ago': 'days ago',
        'review_challenges': 'Review these challenges to improve your skills:',
        'minute': 'minute',
        'minutes': 'minutes',
        'hour': 'hour',
        'hours': 'hours',
        'day': 'day',
        'days': 'days',
        'favorite_numbers': '⭐ Favorite Numbers',
        'edit': 'Edit',
        'favorite_numbers_description': 'These numbers will appear more often in your math problems! 🎯',
        'tap_edit_to_choose': 'Tap Edit to choose your favorite numbers!',
      },
      'es': {
        'profile_title': 'Perfil',
        'language_settings': '🌍 Configuración de Idioma',
        'language_instruction': 'Selecciona tu idioma preferido:',
        'stars': '⭐ Estrellas',
        'problems': '🎯 Problemas',
        'accuracy': '📊 Precisión',
        'adaptive_performance': '🎯 Rendimiento de Desafío Adaptativo',
        'try_again': '🤔 ¿Quieres intentarlo una vez más?',
        'no_failed_attempts': '¡Buen trabajo! 🎉 Aún no hay intentos fallidos.',
        'back_to_home': 'Volver al Inicio',
        'reset_progress': 'Reiniciar Progreso',
        'reset_dialog_title': 'Reiniciar Progreso',
        'reset_dialog_content': '¿Estás seguro de que quieres reiniciar todo el progreso?',
        'reset_dialog_delete': 'Esto eliminará permanentemente:',
        'reset_item_history': '• Todo el historial de desafíos',
        'reset_item_stats': '• Estadísticas de rendimiento',
        'reset_item_stars': '• Estrellas y problemas completados',
        'reset_item_attempts': '• Registros de intentos fallidos',
        'reset_dialog_note': 'Tu información de perfil (nombre, edad, idioma) se mantendrá.',
        'cancel': 'Cancelar',
        'resetting': 'Reiniciando progreso...',
        'reset_success': '✅ ¡Progreso reiniciado exitosamente! ¡Empezando de nuevo!',
        'your_answer': 'Tu respuesta:',
        'no_answer': 'Sin respuesta',
        'time_ago': 'hace',
        'just_now': 'ahora mismo',
        'minutes_ago': 'minutos',
        'hours_ago': 'horas',
        'days_ago': 'días',
        'review_challenges': 'Revisa estos desafíos para mejorar tus habilidades:',
        'minute': 'minuto',
        'minutes': 'minutos',
        'hour': 'hora',
        'hours': 'horas',
        'day': 'día',
        'days': 'días',
        'favorite_numbers': '⭐ Números Favoritos',
        'edit': 'Editar',
        'favorite_numbers_description': '¡Estos números aparecerán más a menudo en tus problemas de matemáticas! 🎯',
        'tap_edit_to_choose': '¡Toca Editar para elegir tus números favoritos!',
      },
      'fr': {
        'profile_title': 'Profil',
        'language_settings': '🌍 Paramètres de Langue',
        'language_instruction': 'Sélectionnez votre langue préférée:',
        'stars': '⭐ Étoiles',
        'problems': '🎯 Problèmes',
        'accuracy': '📊 Précision',
        'adaptive_performance': '🎯 Performance de Défi Adaptatif',
        'try_again': '🤔 Voulez-vous essayer encore une fois?',
        'no_failed_attempts': 'Excellent travail! 🎉 Aucune tentative échouée pour le moment.',
        'back_to_home': 'Retour à l\'Accueil',
        'reset_progress': 'Réinitialiser le Progrès',
        'reset_dialog_title': 'Réinitialiser le Progrès',
        'reset_dialog_content': 'Êtes-vous sûr de vouloir réinitialiser tous les progrès?',
        'reset_dialog_delete': 'Ceci supprimera définitivement:',
        'reset_item_history': '• Tout l\'historique des défis',
        'reset_item_stats': '• Statistiques de performance',
        'reset_item_stars': '• Étoiles et problèmes complétés',
        'reset_item_attempts': '• Enregistrements des tentatives échouées',
        'reset_dialog_note': 'Vos informations de profil (nom, âge, langue) seront conservées.',
        'cancel': 'Annuler',
        'resetting': 'Réinitialisation du progrès...',
        'reset_success': '✅ Progrès réinitialisé avec succès! Nouveau départ!',
        'your_answer': 'Votre réponse:',
        'no_answer': 'Aucune réponse',
        'time_ago': 'il y a',
        'just_now': 'à l\'instant',
        'minutes_ago': 'minutes',
        'hours_ago': 'heures',
        'days_ago': 'jours',
        'review_challenges': 'Révisez ces défis pour améliorer vos compétences:',
        'minute': 'minute',
        'minutes': 'minutes',
        'hour': 'heure',
        'hours': 'heures',
        'day': 'jour',
        'days': 'jours',
        'favorite_numbers': '⭐ Nombres Favoris',
        'edit': 'Modifier',
        'favorite_numbers_description': 'Ces nombres apparaîtront plus souvent dans vos problèmes de mathématiques! 🎯',
        'tap_edit_to_choose': 'Appuyez sur Modifier pour choisir vos nombres favoris!',
      },
    };
    
    return translations[_tempLanguage]?[key] ?? translations['en']![key]!;
  }

  String _getResetButtonText() {
    return _getText('reset_progress');
  }


  void _showResetProgressDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 12),
              Text(_getText('reset_dialog_title')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getText('reset_dialog_content'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(_getText('reset_dialog_delete')),
              const SizedBox(height: 8),
              Text(_getText('reset_item_history')),
              Text(_getText('reset_item_stats')),
              Text(_getText('reset_item_stars')),
              Text(_getText('reset_item_attempts')),
              const SizedBox(height: 12),
              Text(
                _getText('reset_dialog_note'),
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(_getText('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetProgress(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: Text(_getResetButtonText()),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetProgress(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(_getText('resetting')),
            ],
          ),
        ),
      );

      // Reset the progress
      await ref.read(profileProvider.notifier).resetProgress();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 12),
                Text(_getText('reset_success')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Refresh the page data
      setState(() {
        _isLoading = true;
      });
      await _loadProfileData();
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.of(context).pop();
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error resetting progress: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
