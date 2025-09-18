import 'package:flutter/material.dart';

/// Language configuration with flag and translations
class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final Map<String, String> translations;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.translations,
  });
}

/// Service for managing app translations and language support
class LanguageService {
  static const Map<String, AppLanguage> _languages = {
    'en': AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      translations: {
        // Navigation
        'welcome': 'Welcome',
        'back_to_home': 'Back to Home',
        'continue_challenge': 'Continue Challenge',
        'math_challenge': 'Math Challenge',
        'profile_history': 'Profile & History',
        
        // Profile Creation
        'create_profile': 'Create Your Profile',
        'enter_name': 'Enter your name',
        'select_age': 'How old are you?',
        'select_language': 'Choose your language',
        'start_learning': 'Start Learning!',
        'name_hint': 'What should we call you?',
        
        // Challenge Screen
        'level_challenge': 'Level {level} Challenge',
        'solve_problem': 'Solve this problem:',
        'choose_answer': 'Choose your answer:',
        'submit_answer': 'Submit Answer',
        'select_answer_first': 'Select an answer first',
        'next_challenge': 'Next Challenge',
        'get_hint': 'Get a hint',
        'interactive_number_bond': 'Interactive Number Bond',
        
        // Number Bond
        'make_ten_strategy': 'Make Ten Strategy',
        'crossing_strategy': 'Crossing Strategy',
        'counting_strategy': 'Counting Strategy',
        'number_bond': 'Number Bond',
        'sum': 'Sum',
        'first_number': 'First\nNumber',
        'second_number': 'Second\nNumber',
        'clear_try_again': 'Clear and try again',
        'available_numbers': 'Available Numbers (tap to add to circle):',
        'build_number_bond': 'Select numbers\nto build the\nnumber bond',
        
        // Feedback Messages
        'excellent_work': 'Excellent work! 🌟',
        'perfect_got_it': 'Perfect! You got it! 🎉',
        'amazing_keep_up': 'Amazing! Keep it up! ⭐',
        'fantastic_job': 'Fantastic job! 🏆',
        'math_star': 'You\'re a math star! ✨',
        'not_quite_right': 'Not quite right. Try again! 💪',
        'close_try_again': 'Close! Give it another try! 🤔',
        'think_try_more': 'Think about it and try once more! 💭',
        'you_can_do_it': 'You can do it! Try again! 🎯',
        'step_by_step_solution': 'Step-by-Step Solution',
        'great_number_bond': '🎉 Great! You built the number bond correctly!',
        
        // Profile History
        'performance_summary': 'Performance Summary',
        'total_problems': 'Total Problems',
        'accuracy': 'Accuracy',
        'current_streak': 'Current Streak',
        'average_time': 'Average Time',
        'language_settings': 'Language Settings',
        'change_language': 'Change your preferred language:',
        'language_changed': 'Language changed to',
        'failure_history': 'Failure Transaction History',
        'no_failures': 'No failures yet!',
        'keep_great_work': 'Keep up the great work!',
        'correct_answer': 'Correct Answer:',
        'your_answer': 'Your Answer:',
        'time_spent': 'Time Spent:',
        'seconds': 'seconds',
        'hint_used': 'Hint was used',
        'explanation': 'Explanation:',
        'clear_all_data': 'Clear All Data',
        'clear_data_confirm': 'Clear All Data?',
        'clear_data_warning': 'This will permanently delete all your progress, including:\n• All problem attempts\n• Performance history\n• Failure transactions\n\nThis action cannot be undone.',
        'cancel': 'Cancel',
        'clear_data': 'Clear Data',
        'data_cleared': 'All data cleared successfully',
        
        // Hints
        'make_ten_hint': 'Try making 10 first! What number goes with {number} to make 10?',
        'crossing_hint': 'Break down the bigger number! Think about tens and ones.',
        'basic_hint': 'Count up from the bigger number!',
        'general_hint': 'Use your favorite strategy: counting, making 10, or breaking numbers apart!',
        
        // Errors
        'error_loading_profile': 'Error loading profile:',
        'no_profile_found': 'No profile found',
        'create_profile_button': 'Create Profile',
        'back_to_profile': 'Back to Profile Creation',
      },
    ),
    
    'es': AppLanguage(
      code: 'es',
      name: 'Spanish',
      nativeName: 'Español',
      flag: '🇪🇸',
      translations: {
        // Navigation
        'welcome': 'Bienvenido',
        'back_to_home': 'Volver al Inicio',
        'continue_challenge': 'Continuar Desafío',
        'math_challenge': 'Desafío Matemático',
        'profile_history': 'Perfil e Historial',
        
        // Profile Creation
        'create_profile': 'Crea tu Perfil',
        'enter_name': 'Escribe tu nombre',
        'select_age': '¿Cuántos años tienes?',
        'select_language': 'Elige tu idioma',
        'start_learning': '¡Empezar a Aprender!',
        'name_hint': '¿Cómo te llamamos?',
        
        // Challenge Screen
        'level_challenge': 'Desafío Nivel {level}',
        'solve_problem': 'Resuelve este problema:',
        'choose_answer': 'Elige tu respuesta:',
        'submit_answer': 'Enviar Respuesta',
        'select_answer_first': 'Selecciona una respuesta primero',
        'next_challenge': 'Siguiente Desafío',
        'get_hint': 'Obtener pista',
        'interactive_number_bond': 'Enlace Numérico Interactivo',
        
        // Number Bond
        'make_ten_strategy': 'Estrategia Hacer Diez',
        'crossing_strategy': 'Estrategia de Cruce',
        'counting_strategy': 'Estrategia de Conteo',
        'number_bond': 'Enlace Numérico',
        'sum': 'Suma',
        'first_number': 'Primer\nNúmero',
        'second_number': 'Segundo\nNúmero',
        'clear_try_again': 'Limpiar e intentar de nuevo',
        'available_numbers': 'Números Disponibles (toca para agregar al círculo):',
        'build_number_bond': 'Selecciona números\npara construir el\nenlace numérico',
        
        // Feedback Messages
        'excellent_work': '¡Excelente trabajo! 🌟',
        'perfect_got_it': '¡Perfecto! ¡Lo lograste! 🎉',
        'amazing_keep_up': '¡Increíble! ¡Sigue así! ⭐',
        'fantastic_job': '¡Trabajo fantástico! 🏆',
        'math_star': '¡Eres una estrella de matemáticas! ✨',
        'not_quite_right': 'No del todo correcto. ¡Inténtalo de nuevo! 💪',
        'close_try_again': '¡Cerca! ¡Inténtalo otra vez! 🤔',
        'think_try_more': '¡Piénsalo e inténtalo una vez más! 💭',
        'you_can_do_it': '¡Puedes hacerlo! ¡Inténtalo de nuevo! 🎯',
        'step_by_step_solution': 'Solución Paso a Paso',
        'great_number_bond': '¡🎉 Genial! ¡Construiste el enlace numérico correctamente!',
        
        // Profile History
        'performance_summary': 'Resumen de Rendimiento',
        'total_problems': 'Problemas Totales',
        'accuracy': 'Precisión',
        'current_streak': 'Racha Actual',
        'average_time': 'Tiempo Promedio',
        'language_settings': 'Configuración de Idioma',
        'change_language': 'Cambia tu idioma preferido:',
        'language_changed': 'Idioma cambiado a',
        'failure_history': 'Historial de Errores',
        'no_failures': '¡Aún no hay errores!',
        'keep_great_work': '¡Sigue con el gran trabajo!',
        'correct_answer': 'Respuesta Correcta:',
        'your_answer': 'Tu Respuesta:',
        'time_spent': 'Tiempo Empleado:',
        'seconds': 'segundos',
        'hint_used': 'Se usó una pista',
        'explanation': 'Explicación:',
        'clear_all_data': 'Limpiar Todos los Datos',
        'clear_data_confirm': '¿Limpiar Todos los Datos?',
        'clear_data_warning': 'Esto eliminará permanentemente todo tu progreso, incluyendo:\n• Todos los intentos de problemas\n• Historial de rendimiento\n• Transacciones de errores\n\nEsta acción no se puede deshacer.',
        'cancel': 'Cancelar',
        'clear_data': 'Limpiar Datos',
        'data_cleared': 'Todos los datos eliminados exitosamente',
        
        // Hints
        'make_ten_hint': '¡Intenta hacer 10 primero! ¿Qué número va con {number} para hacer 10?',
        'crossing_hint': '¡Descompón el número más grande! Piensa en decenas y unidades.',
        'basic_hint': '¡Cuenta desde el número más grande!',
        'general_hint': 'Usa tu estrategia favorita: contar, hacer 10, o separar números!',
        
        // Errors
        'error_loading_profile': 'Error cargando perfil:',
        'no_profile_found': 'No se encontró perfil',
        'create_profile_button': 'Crear Perfil',
        'back_to_profile': 'Volver a Creación de Perfil',
      },
    ),
    
    'fr': AppLanguage(
      code: 'fr',
      name: 'French',
      nativeName: 'Français',
      flag: '🇫🇷',
      translations: {
        // Navigation
        'welcome': 'Bienvenue',
        'back_to_home': 'Retour à l\'Accueil',
        'continue_challenge': 'Continuer le Défi',
        'math_challenge': 'Défi Mathématique',
        'profile_history': 'Profil et Historique',
        
        // Profile Creation
        'create_profile': 'Créer Votre Profil',
        'enter_name': 'Entrez votre nom',
        'select_age': 'Quel âge avez-vous?',
        'select_language': 'Choisissez votre langue',
        'start_learning': 'Commencer à Apprendre!',
        'name_hint': 'Comment devons-nous vous appeler?',
        
        // Challenge Screen
        'level_challenge': 'Défi Niveau {level}',
        'solve_problem': 'Résolvez ce problème:',
        'choose_answer': 'Choisissez votre réponse:',
        'submit_answer': 'Soumettre la Réponse',
        'select_answer_first': 'Sélectionnez d\'abord une réponse',
        'next_challenge': 'Défi Suivant',
        'get_hint': 'Obtenir un indice',
        'interactive_number_bond': 'Lien Numérique Interactif',
        
        // Number Bond
        'make_ten_strategy': 'Stratégie Faire Dix',
        'crossing_strategy': 'Stratégie de Croisement',
        'counting_strategy': 'Stratégie de Comptage',
        'number_bond': 'Lien Numérique',
        'sum': 'Somme',
        'first_number': 'Premier\nNombre',
        'second_number': 'Deuxième\nNombre',
        'clear_try_again': 'Effacer et réessayer',
        'available_numbers': 'Nombres Disponibles (appuyez pour ajouter au cercle):',
        'build_number_bond': 'Sélectionnez des nombres\npour construire le\nlien numérique',
        
        // Feedback Messages
        'excellent_work': 'Excellent travail! 🌟',
        'perfect_got_it': 'Parfait! Vous l\'avez eu! 🎉',
        'amazing_keep_up': 'Incroyable! Continuez! ⭐',
        'fantastic_job': 'Travail fantastique! 🏆',
        'math_star': 'Vous êtes une star des maths! ✨',
        'not_quite_right': 'Pas tout à fait correct. Réessayez! 💪',
        'close_try_again': 'Proche! Essayez encore! 🤔',
        'think_try_more': 'Réfléchissez et essayez encore une fois! 💭',
        'you_can_do_it': 'Vous pouvez le faire! Réessayez! 🎯',
        'step_by_step_solution': 'Solution Étape par Étape',
        'great_number_bond': '🎉 Génial! Vous avez construit le lien numérique correctement!',
        
        // Profile History
        'performance_summary': 'Résumé des Performances',
        'total_problems': 'Problèmes Totaux',
        'accuracy': 'Précision',
        'current_streak': 'Série Actuelle',
        'average_time': 'Temps Moyen',
        'language_settings': 'Paramètres de Langue',
        'change_language': 'Changez votre langue préférée:',
        'language_changed': 'Langue changée en',
        'failure_history': 'Historique des Échecs',
        'no_failures': 'Aucun échec pour l\'instant!',
        'keep_great_work': 'Continuez ce excellent travail!',
        'correct_answer': 'Réponse Correcte:',
        'your_answer': 'Votre Réponse:',
        'time_spent': 'Temps Passé:',
        'seconds': 'secondes',
        'hint_used': 'Indice utilisé',
        'explanation': 'Explication:',
        'clear_all_data': 'Effacer Toutes les Données',
        'clear_data_confirm': 'Effacer Toutes les Données?',
        'clear_data_warning': 'Cela supprimera définitivement tous vos progrès, y compris:\n• Toutes les tentatives de problèmes\n• Historique des performances\n• Transactions d\'échecs\n\nCette action ne peut pas être annulée.',
        'cancel': 'Annuler',
        'clear_data': 'Effacer les Données',
        'data_cleared': 'Toutes les données effacées avec succès',
        
        // Hints
        'make_ten_hint': 'Essayez de faire 10 d\'abord! Quel nombre va avec {number} pour faire 10?',
        'crossing_hint': 'Décomposez le plus grand nombre! Pensez aux dizaines et aux unités.',
        'basic_hint': 'Comptez à partir du plus grand nombre!',
        'general_hint': 'Utilisez votre stratégie préférée: compter, faire 10, ou séparer les nombres!',
        
        // Errors
        'error_loading_profile': 'Erreur lors du chargement du profil:',
        'no_profile_found': 'Aucun profil trouvé',
        'create_profile_button': 'Créer un Profil',
        'back_to_profile': 'Retour à la Création de Profil',
      },
    ),
  };

  /// Get translation for a key in the specified language
  static String translate(String key, String languageCode, {Map<String, String>? params}) {
    final language = _languages[languageCode] ?? _languages['en']!;
    String translation = language.translations[key] ?? key;
    
    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }
    
    return translation;
  }

  /// Get language info by code
  static AppLanguage? getLanguage(String code) {
    return _languages[code];
  }

  /// Get all available languages
  static List<AppLanguage> get availableLanguages => _languages.values.toList();

  /// Get language flag
  static String getFlag(String languageCode) {
    return _languages[languageCode]?.flag ?? '🇺🇸';
  }

  /// Get language native name
  static String getLanguageName(String languageCode) {
    return _languages[languageCode]?.nativeName ?? 'English';
  }

  /// Check if language is supported
  static bool isSupported(String languageCode) {
    return _languages.containsKey(languageCode);
  }

  /// Get supported language codes
  static List<String> get supportedLanguages => _languages.keys.toList();
}

/// Extension to make translation easier in widgets
extension TranslationExtension on String {
  String tr(String languageCode, {Map<String, String>? params}) {
    return LanguageService.translate(this, languageCode, params: params);
  }
}

