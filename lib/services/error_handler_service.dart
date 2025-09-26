import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'translation_service.dart';
import '../core/constants.dart';

enum ErrorType {
  network,
  storage,
  validation,
  authentication,
  unknown,
}

class AppError {
  final String message;
  final ErrorType type;
  final String? details;
  final DateTime timestamp;
  final StackTrace? stackTrace;

  AppError({
    required this.message,
    required this.type,
    this.details,
    StackTrace? stackTrace,
  }) : timestamp = DateTime.now(),
        stackTrace = stackTrace;

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, details: $details, timestamp: $timestamp)';
  }
}

/// Centralized error handling service
class ErrorHandlerService {
  static final List<AppError> _errorLog = [];
  static const int maxLogSize = 100;

  /// Handle and log an error
  static AppError handleError(
    dynamic error, {
    ErrorType? type,
    String? customMessage,
    StackTrace? stackTrace,
    String language = 'en',
  }) {
    final errorType = type ?? _determineErrorType(error);
    final message = customMessage ?? _getErrorMessage(error, errorType, language);
    
    final appError = AppError(
      message: message,
      type: errorType,
      details: error.toString(),
      stackTrace: stackTrace,
    );

    _logError(appError);
    return appError;
  }

  /// Show error dialog to user
  static void showErrorDialog(
    BuildContext context,
    AppError error, {
    String? title,
    VoidCallback? onRetry,
    String language = 'en',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.error,
              color: AppConstants.errorRed,
              size: AppConstants.iconSizeMedium,
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Text(
              title ?? TranslationService.getText('error', language),
              style: AppTheme.headingMedium.copyWith(
                color: AppConstants.errorRed,
              ),
            ),
          ],
        ),
        content: Text(
          error.message,
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getText('ok', language)),
          ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: AppTheme.primaryButtonStyle,
              child: Text(TranslationService.getText('retry', language)),
            ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    String language = 'en',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.white,
              size: AppConstants.iconSizeSmall,
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Expanded(
              child: Text(
                error.message,
                style: AppTheme.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.errorRed,
        action: onRetry != null
            ? SnackBarAction(
                label: TranslationService.getText('retry', language),
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Get error logs (for debugging)
  static List<AppError> getErrorLogs() {
    return List.unmodifiable(_errorLog);
  }

  /// Clear error logs
  static void clearErrorLogs() {
    _errorLog.clear();
  }

  /// Get error statistics
  static Map<ErrorType, int> getErrorStatistics() {
    final stats = <ErrorType, int>{};
    for (final error in _errorLog) {
      stats[error.type] = (stats[error.type] ?? 0) + 1;
    }
    return stats;
  }

  static ErrorType _determineErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || 
        errorString.contains('connection') || 
        errorString.contains('timeout')) {
      return ErrorType.network;
    }
    
    if (errorString.contains('storage') || 
        errorString.contains('database') || 
        errorString.contains('file')) {
      return ErrorType.storage;
    }
    
    if (errorString.contains('validation') || 
        errorString.contains('invalid') || 
        errorString.contains('format')) {
      return ErrorType.validation;
    }
    
    if (errorString.contains('unauthorized') || 
        errorString.contains('permission') || 
        errorString.contains('auth')) {
      return ErrorType.authentication;
    }
    
    return ErrorType.unknown;
  }

  static String _getErrorMessage(dynamic error, ErrorType type, String language) {
    switch (type) {
      case ErrorType.network:
        return TranslationService.getText('network_error', language);
      case ErrorType.storage:
        return TranslationService.getText('storage_error', language);
      case ErrorType.validation:
        return TranslationService.getText('validation_error', language);
      case ErrorType.authentication:
        return TranslationService.getText('auth_error', language);
      case ErrorType.unknown:
        return TranslationService.getText('unknown_error', language);
    }
  }

  static void _logError(AppError error) {
    // Add to internal log
    _errorLog.add(error);
    
    // Keep log size manageable
    if (_errorLog.length > maxLogSize) {
      _errorLog.removeAt(0);
    }
    
    // Log to console in debug mode
    if (kDebugMode) {
      debugPrint('🔴 Error logged: $error');
      if (error.stackTrace != null) {
        debugPrint('Stack trace: ${error.stackTrace}');
      }
    }
    
    // TODO: In production, send critical errors to crash reporting service
    // Example: Firebase Crashlytics, Sentry, etc.
  }
}

/// Extension to add error handling to common operations
extension FutureErrorHandling<T> on Future<T> {
  /// Add automatic error handling to futures
  Future<T> handleErrors({
    ErrorType? type,
    String? customMessage,
    String language = 'en',
  }) async {
    try {
      return await this;
    } catch (error, stackTrace) {
      final appError = ErrorHandlerService.handleError(
        error,
        type: type,
        customMessage: customMessage,
        stackTrace: stackTrace,
        language: language,
      );
      throw appError;
    }
  }
}

/// Widget wrapper for automatic error handling
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError error)? errorBuilder;
  final void Function(AppError error)? onError;
  final String language;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
    this.language = 'en',
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(error!);
      }
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: AppConstants.iconSizeXXLarge,
              color: AppConstants.errorRed,
            ),
            const SizedBox(height: AppConstants.spacingMedium),
            Text(
              error!.message,
              style: AppTheme.bodyLarge.copyWith(color: AppConstants.errorRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            ElevatedButton(
              onPressed: () => setState(() => error = null),
              style: AppTheme.primaryButtonStyle,
              child: Text(TranslationService.getText('retry', widget.language)),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }

  void handleError(dynamic error, StackTrace stackTrace) {
    final appError = ErrorHandlerService.handleError(
      error,
      stackTrace: stackTrace,
      language: widget.language,
    );
    
    setState(() {
      this.error = appError;
    });
    
    widget.onError?.call(appError);
  }
}

