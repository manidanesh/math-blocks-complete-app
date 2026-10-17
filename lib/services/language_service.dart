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
        'birth_year_label': 'Birth year',
        'select_birth_year': 'Select birth year',
        'age_this_year': 'Age this year: {age}',
        'birth_year_age_explanation':
            'Age updates automatically each January 1.',
        'birth_year_selected': 'Birth year selected',
        'birth_year_settings': 'Birth Year',
        'add_birth_year_hint': 'Add a birth year to keep age up to date.',
        'birth_year_updated': 'Birth year updated.',
        'error_updating_birth_year':
            'Could not update birth year. Please try again.',
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
        'get_hint': 'Get Hint',
        'try_again': 'Try Again',
        'bond_empty_part': 'Not chosen',
        'bond_whole_number': 'Whole number',
        'profile_age': 'Age',
        'profile_language': 'Language',
        'challenge_save_error':
            'Your result could not be saved. Please try again.',
        'challenge_retry_save': 'Retry saving',
        'challenge_saving_result': 'Saving result...',
        'interactive_number_bond': 'Interactive Number Bond',

        // Number Bond
        'make_ten_strategy': 'Make Ten Strategy',
        'crossing_strategy': 'Crossing Strategy',
        'basic_strategy': 'Basic Strategy',
        'counting_strategy': 'Counting Strategy',
        'number_bond': 'Number Bond',
        'sum': 'Sum',
        'first_number': 'First\nNumber',
        'second_number': 'Second\nNumber',
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
        'clear_data_warning':
            'This will permanently delete all your progress, including:\n• All problem attempts\n• Performance history\n• Failure transactions\n\nThis action cannot be undone.',
        'cancel': 'Cancel',
        'clear_data': 'Clear Data',
        'data_cleared': 'All data cleared successfully',

        // Performance Metrics
        'performance_overview': 'Performance Overview',
        'recent_accuracy': 'Recent Accuracy',
        'consecutive_incorrect': 'Consecutive Incorrect',
        'level_performance': 'Level Performance:',
        'level': 'Level',

        // Adaptive Challenge
        'adaptive_challenge': 'Adaptive Challenge',
        'ones_explorer': 'Ones Explorer',
        'tens_builder': 'Tens Builder',
        'hundreds_hero': 'Hundreds Hero',
        'thousands_champion': 'Thousands Champion',
        'progress_to_next_level': 'Progress to next level',
        'stars_to_go': 'stars to go',
        'review': 'REVIEW',

        // Interactive Number Bond
        'tap_numbers_instruction': 'Tap numbers to fill the circles:',

        // Failed Challenges
        'no_failed_challenges': 'No failed challenges yet!',
        'and_more_failed': 'and {count} more failed challenges',

        // Hints
        'make_ten_hint':
            'Try making 10 first! What number goes with {number} to make 10?',
        'crossing_hint':
            'Break down the bigger number! Think about tens and ones.',
        'basic_hint': 'Count up from the bigger number!',
        'general_hint':
            'Use your favorite strategy: counting, making 10, or breaking numbers apart!',

        // Success Messages
        'excellent_celebration': '🎉 Excellent!',
        'number_bond_solved': 'You solved the number bond correctly!',
        'star_reward': '+1 Star',
        'current_stars': '⭐ {stars}',
        'current_badges': '🏅 {badges}',

        // Interactive Number Bond Messages
        'oops_try_different': 'Oops! Let\'s try a different way!',
        'more_chances_hero': '{count} more chances to be a Math Hero!',
        'magic_trick_for': 'Magic Trick for {operand1} {operator} {operand2}:',
        'clear_try_again': 'Clear & Try Again!',
        'bond_check_answer': 'Check Answer',
        'bond_auto_check_instruction':
            'Answers are checked automatically when every part is filled.',
        'bond_number_picker_title': 'Choose a number for Part {number}',
        'bond_number_picker_close': 'Close',
        'bond_compact_instruction': 'Tap a circle or choose a number below.',
        'bond_compact_retry': '{count} tries left. Tap info for help.',
        'bond_previous_numbers': 'Previous numbers',
        'bond_next_numbers': 'More numbers',
        'bond_number_page': 'Number page {current} of {total}',
        'bond_view_explanation': 'View explanation',
        'bond_part_label': 'Part {number}',
        'bond_clear': 'Clear and try again',
        'bond_choose_parts':
            'Split {number} into parts. Tap numbers below or tap a circle to choose.',
        'bond_breakdown': 'Break {number} into {parts}',
        'bond_retry_split': 'Try splitting {number} into {parts}.',
        'bond_place_value_strategy': 'Tens and Hundreds Strategy',

        // Number Bond Format
        'subtraction_format': 'Subtraction:',
        'addition_format': 'Addition:',
        'congratulations_level_up':
            'Congratulations {name}!\nYou reached {level} level!',
        'level_up': 'LEVEL UP!',
        'continue': 'Continue',

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
        'birth_year_label': 'Año de nacimiento',
        'select_birth_year': 'Selecciona tu año de nacimiento',
        'age_this_year': 'Edad este año: {age}',
        'birth_year_age_explanation':
            'La edad se actualiza automáticamente cada 1 de enero.',
        'birth_year_selected': 'Año de nacimiento seleccionado',
        'birth_year_settings': 'Año de nacimiento',
        'add_birth_year_hint':
            'Añade tu año de nacimiento para mantener tu edad actualizada.',
        'birth_year_updated': 'Año de nacimiento actualizado.',
        'error_updating_birth_year':
            'No se pudo actualizar el año de nacimiento. Inténtalo de nuevo.',
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
        'get_hint': 'Pista',
        'try_again': 'Intentar de Nuevo',
        'bond_empty_part': 'Sin elegir',
        'bond_whole_number': 'Número completo',
        'profile_age': 'Edad',
        'profile_language': 'Idioma',
        'challenge_save_error':
            'No se pudo guardar el resultado. Inténtalo de nuevo.',
        'challenge_retry_save': 'Reintentar guardar',
        'challenge_saving_result': 'Guardando resultado...',
        'interactive_number_bond': 'Enlace Numérico Interactivo',

        // Number Bond
        'make_ten_strategy': 'Estrategia Hacer Diez',
        'crossing_strategy': 'Estrategia de Cruce',
        'basic_strategy': 'Estrategia Básica',
        'counting_strategy': 'Estrategia de Conteo',
        'number_bond': 'Enlace Numérico',
        'sum': 'Suma',
        'first_number': 'Primer\nNúmero',
        'second_number': 'Segundo\nNúmero',
        'available_numbers':
            'Números Disponibles (toca para agregar al círculo):',
        'build_number_bond':
            'Selecciona números\npara construir el\nenlace numérico',

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
        'great_number_bond':
            '¡🎉 Genial! ¡Construiste el enlace numérico correctamente!',

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
        'clear_data_warning':
            'Esto eliminará permanentemente todo tu progreso, incluyendo:\n• Todos los intentos de problemas\n• Historial de rendimiento\n• Transacciones de errores\n\nEsta acción no se puede deshacer.',
        'cancel': 'Cancelar',
        'clear_data': 'Limpiar Datos',
        'data_cleared': 'Todos los datos eliminados exitosamente',

        // Performance Metrics
        'performance_overview': 'Resumen de Rendimiento',
        'recent_accuracy': 'Precisión Reciente',
        'consecutive_incorrect': 'Incorrectos Consecutivos',
        'level_performance': 'Rendimiento por Nivel:',
        'level': 'Nivel',

        // Adaptive Challenge
        'adaptive_challenge': 'Desafío Adaptativo',
        'ones_explorer': 'Explorador de Unidades',
        'tens_builder': 'Constructor de Decenas',
        'hundreds_hero': 'Héroe de Centenas',
        'thousands_champion': 'Campeón de Miles',
        'progress_to_next_level': 'Progreso al siguiente nivel',
        'stars_to_go': 'estrellas para continuar',
        'review': 'REPASO',

        // Interactive Number Bond
        'tap_numbers_instruction': 'Toca números para llenar los círculos:',

        // Failed Challenges
        'no_failed_challenges': '¡Aún no hay desafíos fallidos!',
        'and_more_failed': 'y {count} desafíos fallidos más',

        // Hints
        'make_ten_hint':
            '¡Intenta hacer 10 primero! ¿Qué número va con {number} para hacer 10?',
        'crossing_hint':
            '¡Descompón el número más grande! Piensa en decenas y unidades.',
        'basic_hint': '¡Cuenta desde el número más grande!',
        'general_hint':
            'Usa tu estrategia favorita: contar, hacer 10, o separar números!',

        // Success Messages
        'excellent_celebration': '¡🎉 Excelente!',
        'number_bond_solved': '¡Resolviste el enlace numérico correctamente!',
        'star_reward': '+1 Estrella',
        'current_stars': '⭐ {stars}',
        'current_badges': '🏅 {badges}',

        // Interactive Number Bond Messages
        'oops_try_different': '¡Ups! ¡Intentemos de otra manera!',
        'more_chances_hero':
            '¡{count} oportunidades más para ser un Héroe Matemático!',
        'magic_trick_for':
            'Truco Mágico para {operand1} {operator} {operand2}:',
        'clear_try_again': '¡Limpiar e Intentar de Nuevo!',
        'bond_check_answer': 'Comprobar respuesta',
        'bond_auto_check_instruction':
            'La respuesta se comprueba automáticamente cuando todas las partes están completas.',
        'bond_number_picker_title': 'Elige un número para la parte {number}',
        'bond_number_picker_close': 'Cerrar',
        'bond_compact_instruction': 'Toca un círculo o elige un número abajo.',
        'bond_compact_retry': 'Quedan {count} intentos. Toca info para ayuda.',
        'bond_previous_numbers': 'Números anteriores',
        'bond_next_numbers': 'Más números',
        'bond_number_page': 'Página de números {current} de {total}',
        'bond_view_explanation': 'Ver explicación',
        'bond_part_label': 'Parte {number}',
        'bond_clear': 'Limpiar e intentar de nuevo',
        'bond_choose_parts':
            'Divide {number} en partes. Toca los números de abajo o un círculo para elegir.',
        'bond_breakdown': 'Divide {number} en {parts}',
        'bond_retry_split': 'Intenta dividir {number} en {parts}.',
        'bond_place_value_strategy': 'Estrategia de decenas y centenas',

        // Number Bond Format
        'subtraction_format': 'Resta:',
        'addition_format': 'Suma:',
        'congratulations_level_up':
            '¡Felicitaciones {name}!\n¡Has alcanzado el nivel {level}!',
        'level_up': '¡SUBISTE DE NIVEL!',
        'continue': 'Continuar',

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
        'birth_year_label': 'Année de naissance',
        'select_birth_year': 'Choisissez votre année de naissance',
        'age_this_year': 'Âge cette année : {age}',
        'birth_year_age_explanation':
            'L’âge se met à jour automatiquement chaque 1er janvier.',
        'birth_year_selected': 'Année de naissance sélectionnée',
        'birth_year_settings': 'Année de naissance',
        'add_birth_year_hint':
            'Ajoutez une année de naissance pour actualiser l’âge automatiquement.',
        'birth_year_updated': 'Année de naissance mise à jour.',
        'error_updating_birth_year':
            'Impossible de modifier l’année de naissance. Réessayez.',
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
        'get_hint': 'Indice',
        'try_again': 'Réessayer',
        'bond_empty_part': 'Non choisi',
        'bond_whole_number': 'Nombre entier',
        'profile_age': 'Âge',
        'profile_language': 'Langue',
        'challenge_save_error':
            'Le résultat n’a pas pu être enregistré. Réessaie.',
        'challenge_retry_save': 'Réessayer la sauvegarde',
        'challenge_saving_result': 'Enregistrement du résultat...',
        'interactive_number_bond': 'Lien Numérique Interactif',

        // Number Bond
        'make_ten_strategy': 'Stratégie Faire Dix',
        'crossing_strategy': 'Stratégie de Croisement',
        'basic_strategy': 'Stratégie de Base',
        'counting_strategy': 'Stratégie de Comptage',
        'number_bond': 'Lien Numérique',
        'sum': 'Somme',
        'first_number': 'Premier\nNombre',
        'second_number': 'Deuxième\nNombre',
        'available_numbers':
            'Nombres Disponibles (appuyez pour ajouter au cercle):',
        'build_number_bond':
            'Sélectionnez des nombres\npour construire le\nlien numérique',

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
        'great_number_bond':
            '🎉 Génial! Vous avez construit le lien numérique correctement!',

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
        'clear_data_warning':
            'Cela supprimera définitivement tous vos progrès, y compris:\n• Toutes les tentatives de problèmes\n• Historique des performances\n• Transactions d\'échecs\n\nCette action ne peut pas être annulée.',
        'cancel': 'Annuler',
        'clear_data': 'Effacer les Données',
        'data_cleared': 'Toutes les données effacées avec succès',

        // Performance Metrics
        'performance_overview': 'Aperçu des Performances',
        'recent_accuracy': 'Précision Récente',
        'consecutive_incorrect': 'Incorrects Consécutifs',
        'level_performance': 'Performance par Niveau:',
        'level': 'Niveau',

        // Adaptive Challenge
        'adaptive_challenge': 'Défi Adaptatif',
        'ones_explorer': 'Explorateur d\'Unités',
        'tens_builder': 'Constructeur de Dizaines',
        'hundreds_hero': 'Héros des Centaines',
        'thousands_champion': 'Champion des Milliers',
        'progress_to_next_level': 'Progrès vers le niveau suivant',
        'stars_to_go': 'étoiles à parcourir',
        'review': 'RÉVISION',

        // Interactive Number Bond
        'tap_numbers_instruction':
            'Appuyez sur les nombres pour remplir les cercles:',

        // Failed Challenges
        'no_failed_challenges': 'Aucun défi échoué pour le moment !',
        'and_more_failed': 'et {count} défis échoués de plus',

        // Hints
        'make_ten_hint':
            'Essayez de faire 10 d\'abord! Quel nombre va avec {number} pour faire 10?',
        'crossing_hint':
            'Décomposez le plus grand nombre! Pensez aux dizaines et aux unités.',
        'basic_hint': 'Comptez à partir du plus grand nombre!',
        'general_hint':
            'Utilisez votre stratégie préférée: compter, faire 10, ou séparer les nombres!',

        // Success Messages
        'excellent_celebration': '🎉 Excellent!',
        'number_bond_solved':
            'Vous avez résolu le lien numérique correctement!',
        'star_reward': '+1 Étoile',
        'current_stars': '⭐ {stars}',
        'current_badges': '🏅 {badges}',

        // Interactive Number Bond Messages
        'oops_try_different': 'Oups! Essayons d\'une autre façon!',
        'more_chances_hero':
            '{count} chances de plus d\'être un Héros Mathématique!',
        'magic_trick_for':
            'Astuce Magique pour {operand1} {operator} {operand2}:',
        'clear_try_again': 'Effacer et Réessayer!',
        'bond_check_answer': 'Vérifier la réponse',
        'bond_auto_check_instruction':
            'La réponse est vérifiée automatiquement quand toutes les parties sont remplies.',
        'bond_number_picker_title': 'Choisis un nombre pour la partie {number}',
        'bond_number_picker_close': 'Fermer',
        'bond_compact_instruction': 'Touche un cercle ou choisis un nombre.',
        'bond_compact_retry':
            '{count} essais restants. Touche info pour de l’aide.',
        'bond_previous_numbers': 'Nombres précédents',
        'bond_next_numbers': 'Plus de nombres',
        'bond_number_page': 'Page de nombres {current} sur {total}',
        'bond_view_explanation': 'Voir l’explication',
        'bond_part_label': 'Partie {number}',
        'bond_clear': 'Effacer et réessayer',
        'bond_choose_parts':
            'Décompose {number} en parties. Choisis un nombre en bas ou en touchant un cercle.',
        'bond_breakdown': 'Décompose {number} en {parts}',
        'bond_retry_split': 'Essaie de décomposer {number} en {parts}.',
        'bond_place_value_strategy': 'Stratégie des dizaines et des centaines',

        // Number Bond Format
        'subtraction_format': 'Soustraction:',
        'addition_format': 'Addition:',
        'congratulations_level_up':
            'Félicitations {name}!\nVous avez atteint le niveau {level}!',
        'level_up': 'NIVEAU SUPÉRIEUR!',
        'continue': 'Continuer',

        // Errors
        'error_loading_profile': 'Erreur lors du chargement du profil:',
        'no_profile_found': 'Aucun profil trouvé',
        'create_profile_button': 'Créer un Profil',
        'back_to_profile': 'Retour à la Création de Profil',
      },
    ),
  };

  /// Get translation for a key in the specified language
  /// Follows the recommendation: English as source of truth with proper fallback
  static String translate(
    String key,
    String languageCode, {
    Map<String, String>? params,
  }) {
    // First try the requested language
    String translation = _languages[languageCode]?.translations[key] ?? '';

    // If not found, fallback to English (source of truth)
    if (translation.isEmpty) {
      translation = _languages['en']?.translations[key] ?? key;
    }

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
