import 'package:flutter/material.dart';

/// Application-wide constants to eliminate magic numbers and strings
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Colors
  static const Color primaryBlue = Color(0xFF3498DB);
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color successGreen = Colors.green;
  static const Color warningOrange = Colors.orange;
  static const Color errorRed = Colors.red;

  // Font Sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeXLarge = 24.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusCircular = 30.0;

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeXXLarge = 64.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Game Configuration
  static const int maxFavoriteNumbers = 5;
  static const int maxAttempts = 3;
  static const int minAge = 4;
  static const int maxAge = 12;
  static const List<int> availableNumbers = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

  // Level Configuration
  static const int maxLevel = 4;
  static const double levelProgressThreshold = 0.8; // 80% accuracy to advance

  // UI Dimensions
  static const double cardElevation = 4.0;
  static const double appBarHeight = 56.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Number Bond Configuration
  static const double circleRadius = 25.0;
  static const double circleDiameter = 50.0;
  static const double bondLineWidth = 3.0;

  // Storage Keys
  static const String profileStorageKey = 'user_profile';
  static const String attemptsStorageKey = 'problem_attempts';
  static const String challengesStorageKey = 'adaptive_challenges';
  static const String rewardsStorageKey = 'rewards';

  // Default Values
  static const String defaultLanguage = 'en';
  static const String defaultAvatarId = 'default';
  static const String defaultOperation = 'both';

  // Validation
  static const int minNameLength = 1;
  static const int maxNameLength = 50;

  // Performance Metrics
  static const int recentProblemsCount = 5;
  static const double minAccuracyForStar = 0.8;
}

/// Theme-related constants
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  static const TextStyle headingLarge = TextStyle(
    fontSize: AppConstants.fontSizeXLarge,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: AppConstants.fontSizeLarge,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: AppConstants.fontSizeSmall,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: AppConstants.fontSizeMedium,
    fontWeight: FontWeight.bold,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: AppConstants.cardElevation,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppConstants.primaryBlue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.spacingLarge,
      vertical: AppConstants.spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
    ),
    textStyle: buttonText,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppConstants.primaryPurple,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(
      horizontal: AppConstants.spacingLarge,
      vertical: AppConstants.spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
    ),
    textStyle: buttonText,
  );
}

/// Route constants
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  static const String home = '/';
  static const String profileCreation = '/create-profile';
  static const String modeSelect = '/mode-select';
  static const String profile = '/profile';
  static const String challenge = '/challenge';
  static const String practice = '/practice';
}

/// Error messages
class ErrorMessages {
  // Private constructor to prevent instantiation
  ErrorMessages._();

  static const String networkError = 'Network connection error';
  static const String storageError = 'Data storage error';
  static const String validationError = 'Validation error';
  static const String unknownError = 'An unknown error occurred';
  static const String profileNotFound = 'Profile not found';
  static const String invalidInput = 'Invalid input provided';
}

