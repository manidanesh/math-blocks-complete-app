import 'package:flutter/foundation.dart';

/// Centralized translation service to eliminate duplication across the app
class TranslationService {
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Common terms
      'welcome': 'Welcome',
      'error': 'Error',
      'loading': 'Loading...',
      'cancel': 'Cancel',
      'save': 'Save',
      'edit': 'Edit',
      'delete': 'Delete',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'back': 'Back',
      'next': 'Next',
      'retry': 'Retry',
      'close': 'Close',
      'success': 'Success',
      
      // Profile related
      'profile_history': 'Profile History',
      'age': 'Age',
      'language': 'Language',
      'name': 'Name',
      'enter_name': 'Enter your name',
      'my_profile': 'My Profile',
      'create_profile': 'Create Profile',
      'creating_profile': 'Creating Profile...',
      'edit_profile': 'Edit Profile',
      'save_changes': 'Save Changes',
      'back_to_home': 'Back to Home',
      
      // Numbers and stats
      'stars': 'stars',
      'problems': 'problems',
      'accuracy': 'Accuracy',
      'level': 'Level',
      'performance_overview': 'Performance Overview',
      'accuracy_last_5': 'Recent Accuracy',
      'average_time': 'Average Time',
      'consecutive_incorrect': 'Consecutive Incorrect',
      'level_performance': 'Level Performance:',
      
      // Game elements
      'intelligent_challenge': 'Intelligent Math Challenge',
      'adapts_skill': 'Adapts to your skill level',
      'favorite_numbers': 'Favorite Numbers',
      'optional': '(Optional)',
      'select_favorites': 'Select your favorite numbers to use in problems',
      
      // Welcome messages
      'welcome_message': 'Welcome to Math Blocks!\nLet\'s create your profile!',
      'welcome_title': 'Welcome to Math Blocks!',
      
      // Age and language
      'age_label': 'Age',
      'age_selected': 'Age selected',
      'language_label': 'Language',
      'language_selected': 'Language selected',
      
      // Favorite numbers
      'favorite_numbers_subtitle': 'Choose your favorite numbers (0-9):',
      'favorite_numbers_instruction': 'Select up to {count} numbers you like!',
      'no_numbers_selected': 'No numbers selected yet',
      'numbers_selected': 'Selected {current} of {max} numbers',
      'perfect_selection': 'Perfect! You\'ve selected {count} favorite numbers',
      
      // Reset functionality
      'reset_progress': 'Reset Progress',
      'reset_dialog_title': 'Reset All Progress',
      'reset_dialog_content': 'This will permanently delete all your progress, stars, and challenge history. This action cannot be undone.',
      'reset_confirm': 'Reset Everything',
      'reset_success': 'Progress has been reset successfully!',
      
      // Operations
      'operation_type': 'Operation Type',
      'addition': 'Addition',
      'subtraction': 'Subtraction',
      'both': 'Both',
      
      // Error messages
      'no_profile': 'No profile found',
      'error_creating': 'Error creating profile',
      'error_loading': 'Error loading data',
      'network_error': 'Network connection error',
      'storage_error': 'Data storage error',
      'validation_error': 'Validation error',
      'auth_error': 'Authentication error',
      'unknown_error': 'An unknown error occurred',
    },
    'es': {
      // Common terms
      'welcome': 'Bienvenido',
      'error': 'Error',
      'loading': 'Cargando...',
      'cancel': 'Cancelar',
      'save': 'Guardar',
      'edit': 'Editar',
      'delete': 'Eliminar',
      'yes': 'Sí',
      'no': 'No',
      'ok': 'OK',
      'back': 'Atrás',
      'next': 'Siguiente',
      'retry': 'Reintentar',
      'close': 'Cerrar',
      'success': 'Éxito',
      
      // Profile related
      'profile_history': 'Historial del Perfil',
      'age': 'Edad',
      'language': 'Idioma',
      'name': 'Nombre',
      'enter_name': 'Escribe tu nombre',
      'my_profile': 'Mi Perfil',
      'create_profile': 'Crear Perfil',
      'creating_profile': 'Creando Perfil...',
      'edit_profile': 'Editar Perfil',
      'save_changes': 'Guardar Cambios',
      'back_to_home': 'Volver al Inicio',
      
      // Numbers and stats
      'stars': 'estrellas',
      'problems': 'problemas',
      'accuracy': 'Precisión',
      'level': 'Nivel',
      'performance_overview': 'Resumen de Rendimiento',
      'accuracy_last_5': 'Precisión Reciente',
      'average_time': 'Tiempo Promedio',
      'consecutive_incorrect': 'Incorrectos Consecutivos',
      'level_performance': 'Rendimiento por Nivel:',
      
      // Game elements
      'intelligent_challenge': 'Desafío Matemático Inteligente',
      'adapts_skill': 'Se adapta a tu nivel de habilidad',
      'favorite_numbers': 'Números Favoritos',
      'optional': '(Opcional)',
      'select_favorites': 'Selecciona tus números favoritos para usar en problemas',
      
      // Welcome messages
      'welcome_message': '¡Bienvenido a Math Blocks!\n¡Vamos a crear tu perfil!',
      'welcome_title': '¡Bienvenido a Math Blocks!',
      
      // Age and language
      'age_label': 'Edad',
      'age_selected': 'Edad seleccionada',
      'language_label': 'Idioma',
      'language_selected': 'Idioma seleccionado',
      
      // Favorite numbers
      'favorite_numbers_subtitle': 'Elige tus números favoritos (0-9):',
      'favorite_numbers_instruction': '¡Selecciona hasta {count} números que te gusten!',
      'no_numbers_selected': 'Aún no se han seleccionado números',
      'numbers_selected': 'Seleccionados {current} de {max} números',
      'perfect_selection': '¡Perfecto! Has seleccionado {count} números favoritos',
      
      // Reset functionality
      'reset_progress': 'Reiniciar Progreso',
      'reset_dialog_title': 'Reiniciar Todo el Progreso',
      'reset_dialog_content': 'Esto eliminará permanentemente todo tu progreso, estrellas e historial de desafíos. Esta acción no se puede deshacer.',
      'reset_confirm': 'Reiniciar Todo',
      'reset_success': '¡El progreso se ha reiniciado exitosamente!',
      
      // Operations
      'operation_type': 'Tipo de Operación',
      'addition': 'Suma',
      'subtraction': 'Resta',
      'both': 'Ambos',
      
      // Error messages
      'no_profile': 'No se encontró perfil',
      'error_creating': 'Error al crear perfil',
      'error_loading': 'Error al cargar datos',
      'network_error': 'Error de conexión de red',
      'storage_error': 'Error de almacenamiento de datos',
      'validation_error': 'Error de validación',
      'auth_error': 'Error de autenticación',
      'unknown_error': 'Se produjo un error desconocido',
    },
    'fr': {
      // Common terms
      'welcome': 'Bienvenue',
      'error': 'Erreur',
      'loading': 'Chargement...',
      'cancel': 'Annuler',
      'save': 'Sauvegarder',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'yes': 'Oui',
      'no': 'Non',
      'ok': 'OK',
      'back': 'Retour',
      'next': 'Suivant',
      'retry': 'Réessayer',
      'close': 'Fermer',
      'success': 'Succès',
      
      // Profile related
      'profile_history': 'Historique du Profil',
      'age': 'Âge',
      'language': 'Langue',
      'name': 'Nom',
      'enter_name': 'Entrez votre nom',
      'my_profile': 'Mon Profil',
      'create_profile': 'Créer un Profil',
      'creating_profile': 'Création du Profil...',
      'edit_profile': 'Modifier le Profil',
      'save_changes': 'Sauvegarder les Modifications',
      'back_to_home': 'Retour à l\'Accueil',
      
      // Numbers and stats
      'stars': 'étoiles',
      'problems': 'problèmes',
      'accuracy': 'Précision',
      'level': 'Niveau',
      'performance_overview': 'Aperçu des Performances',
      'accuracy_last_5': 'Précision Récente',
      'average_time': 'Temps Moyen',
      'consecutive_incorrect': 'Incorrects Consécutifs',
      'level_performance': 'Performance par Niveau:',
      
      // Game elements
      'intelligent_challenge': 'Défi Mathématique Intelligent',
      'adapts_skill': 'S\'adapte à votre niveau de compétence',
      'favorite_numbers': 'Nombres Favoris',
      'optional': '(Optionnel)',
      'select_favorites': 'Sélectionnez vos nombres favoris à utiliser dans les problèmes',
      
      // Welcome messages
      'welcome_message': 'Bienvenue dans Math Blocks!\nCréons votre profil!',
      'welcome_title': 'Bienvenue dans Math Blocks!',
      
      // Age and language
      'age_label': 'Âge',
      'age_selected': 'Âge sélectionné',
      'language_label': 'Langue',
      'language_selected': 'Langue sélectionnée',
      
      // Favorite numbers
      'favorite_numbers_subtitle': 'Choisissez vos nombres favoris (0-9):',
      'favorite_numbers_instruction': 'Sélectionnez jusqu\'à {count} nombres que vous aimez!',
      'no_numbers_selected': 'Aucun nombre sélectionné pour le moment',
      'numbers_selected': 'Sélectionné {current} sur {max} nombres',
      'perfect_selection': 'Parfait! Vous avez sélectionné {count} nombres favoris',
      
      // Reset functionality
      'reset_progress': 'Réinitialiser le Progrès',
      'reset_dialog_title': 'Réinitialiser Tout le Progrès',
      'reset_dialog_content': 'Cela supprimera définitivement tout votre progrès, étoiles et historique des défis. Cette action ne peut pas être annulée.',
      'reset_confirm': 'Tout Réinitialiser',
      'reset_success': 'Le progrès a été réinitialisé avec succès!',
      
      // Operations
      'operation_type': 'Type d\'Opération',
      'addition': 'Addition',
      'subtraction': 'Soustraction',
      'both': 'Les Deux',
      
      // Error messages
      'no_profile': 'Aucun profil trouvé',
      'error_creating': 'Erreur lors de la création du profil',
      'error_loading': 'Erreur lors du chargement des données',
      'network_error': 'Erreur de connexion réseau',
      'storage_error': 'Erreur de stockage des données',
      'validation_error': 'Erreur de validation',
      'auth_error': 'Erreur d\'authentification',
      'unknown_error': 'Une erreur inconnue s\'est produite',
    },
  };

  /// Get translated text for the given key and language
  static String getText(String key, [String language = 'en']) {
    return _translations[language]?[key] ?? 
           _translations['en']?[key] ?? 
           key;
  }

  /// Get translated text with parameter substitution
  static String getTextWithParams(String key, Map<String, dynamic> params, [String language = 'en']) {
    String text = getText(key, language);
    
    params.forEach((paramKey, value) {
      text = text.replaceAll('{$paramKey}', value.toString());
    });
    
    return text;
  }

  /// Get all available languages
  static List<String> getAvailableLanguages() {
    return _translations.keys.toList();
  }

  /// Check if a translation exists for the given key and language
  static bool hasTranslation(String key, [String language = 'en']) {
    return _translations[language]?.containsKey(key) ?? false;
  }

  /// Add or update a translation (useful for dynamic content)
  static void addTranslation(String language, String key, String value) {
    if (kDebugMode) {
      // Only allow dynamic translations in debug mode for safety
      _translations[language] = _translations[language] ?? {};
      _translations[language]![key] = value;
    }
  }
}
