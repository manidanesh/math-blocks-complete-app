import '../core/constants.dart';
import 'translation_service.dart';

/// Validation rule interface
abstract class ValidationRule<T> {
  final String message;
  
  ValidationRule(this.message);
  
  bool validate(T value);
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  
  ValidationResult({required this.isValid, this.errors = const []});
  
  factory ValidationResult.valid() => ValidationResult(isValid: true);
  factory ValidationResult.invalid(List<String> errors) => 
      ValidationResult(isValid: false, errors: errors);
  
  String get firstError => errors.isNotEmpty ? errors.first : '';
  bool get hasErrors => errors.isNotEmpty;
}

/// Common validation rules
class RequiredRule extends ValidationRule<String> {
  RequiredRule([String? message]) : super(message ?? 'This field is required');
  
  @override
  bool validate(String value) => value.trim().isNotEmpty;
}

class MinLengthRule extends ValidationRule<String> {
  final int minLength;
  
  MinLengthRule(this.minLength, [String? message]) 
      : super(message ?? 'Must be at least $minLength characters');
  
  @override
  bool validate(String value) => value.length >= minLength;
}

class MaxLengthRule extends ValidationRule<String> {
  final int maxLength;
  
  MaxLengthRule(this.maxLength, [String? message]) 
      : super(message ?? 'Must be no more than $maxLength characters');
  
  @override
  bool validate(String value) => value.length <= maxLength;
}

class RangeRule extends ValidationRule<num> {
  final num min;
  final num max;
  
  RangeRule(this.min, this.max, [String? message]) 
      : super(message ?? 'Must be between $min and $max');
  
  @override
  bool validate(num value) => value >= min && value <= max;
}

class EmailRule extends ValidationRule<String> {
  EmailRule([String? message]) : super(message ?? 'Invalid email format');
  
  @override
  bool validate(String value) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
  }
}

class NumericRule extends ValidationRule<String> {
  NumericRule([String? message]) : super(message ?? 'Must be a number');
  
  @override
  bool validate(String value) {
    return double.tryParse(value) != null;
  }
}

/// Custom validation rules for the app
class AgeRule extends ValidationRule<int> {
  AgeRule([String? message]) 
      : super(message ?? 'Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}');
  
  @override
  bool validate(int value) {
    return value >= AppConstants.minAge && value <= AppConstants.maxAge;
  }
}

class FavoriteNumbersRule extends ValidationRule<List<int>> {
  FavoriteNumbersRule([String? message]) 
      : super(message ?? 'Can select up to ${AppConstants.maxFavoriteNumbers} numbers');
  
  @override
  bool validate(List<int> value) {
    return value.length <= AppConstants.maxFavoriteNumbers &&
           value.every((num) => AppConstants.availableNumbers.contains(num));
  }
}

class LanguageRule extends ValidationRule<String> {
  LanguageRule([String? message]) : super(message ?? 'Invalid language');
  
  @override
  bool validate(String value) {
    return TranslationService.getAvailableLanguages().contains(value);
  }
}

/// Centralized validation service
class ValidationService {
  static final Map<String, List<ValidationRule>> _fieldRules = {};
  static String _currentLanguage = AppConstants.defaultLanguage;

  /// Set the current language for error messages
  static void setLanguage(String language) {
    _currentLanguage = language;
  }

  /// Add validation rules for a field
  static void addRules(String field, List<ValidationRule> rules) {
    _fieldRules[field] = rules;
  }

  /// Remove rules for a field
  static void removeRules(String field) {
    _fieldRules.remove(field);
  }

  /// Clear all rules
  static void clearAllRules() {
    _fieldRules.clear();
  }

  /// Validate a single field
  static ValidationResult validateField(String field, dynamic value) {
    final rules = _fieldRules[field];
    if (rules == null) return ValidationResult.valid();

    final errors = <String>[];
    
    for (final rule in rules) {
      try {
        if (!rule.validate(value)) {
          errors.add(_translateMessage(rule.message));
        }
      } catch (e) {
        errors.add(_translateMessage('Invalid value'));
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }

  /// Validate multiple fields
  static Map<String, ValidationResult> validateFields(Map<String, dynamic> data) {
    final results = <String, ValidationResult>{};
    
    for (final entry in data.entries) {
      results[entry.key] = validateField(entry.key, entry.value);
    }
    
    return results;
  }

  /// Check if all validations pass
  static bool isValid(Map<String, ValidationResult> results) {
    return results.values.every((result) => result.isValid);
  }

  /// Get all error messages
  static List<String> getAllErrors(Map<String, ValidationResult> results) {
    return results.values
        .where((result) => !result.isValid)
        .expand((result) => result.errors)
        .toList();
  }

  /// Validate profile creation data
  static Map<String, ValidationResult> validateProfileCreation(Map<String, dynamic> data) {
    return validateFields({
      'name': data['name'],
      'age': data['age'],
      'language': data['language'],
      'favoriteNumbers': data['favoriteNumbers'] ?? <int>[],
    });
  }

  /// Validate profile update data
  static Map<String, ValidationResult> validateProfileUpdate(Map<String, dynamic> data) {
    final validationData = <String, dynamic>{};
    
    // Only validate provided fields
    if (data.containsKey('name')) validationData['name'] = data['name'];
    if (data.containsKey('age')) validationData['age'] = data['age'];
    if (data.containsKey('language')) validationData['language'] = data['language'];
    if (data.containsKey('favoriteNumbers')) validationData['favoriteNumbers'] = data['favoriteNumbers'];
    
    return validateFields(validationData);
  }

  /// Setup default validation rules for the app
  static void setupDefaultRules() {
    // Profile name validation
    addRules('name', [
      RequiredRule(_translateMessage('Name is required')),
      MinLengthRule(AppConstants.minNameLength, 
          _translateMessage('Name must be at least ${AppConstants.minNameLength} character')),
      MaxLengthRule(AppConstants.maxNameLength, 
          _translateMessage('Name must be no more than ${AppConstants.maxNameLength} characters')),
    ]);

    // Age validation
    addRules('age', [
      AgeRule(_translateMessage('Age must be between ${AppConstants.minAge} and ${AppConstants.maxAge}')),
    ]);

    // Language validation
    addRules('language', [
      LanguageRule(_translateMessage('Please select a valid language')),
    ]);

    // Favorite numbers validation
    addRules('favoriteNumbers', [
      FavoriteNumbersRule(_translateMessage('Can select up to ${AppConstants.maxFavoriteNumbers} favorite numbers')),
    ]);
  }

  /// Create a validator for a specific type
  static Validator<T> createValidator<T>() {
    return Validator<T>();
  }

  static String _translateMessage(String message) {
    // For now, return the message as-is
    // In the future, we could integrate with TranslationService
    // to provide localized validation messages
    return message;
  }
}

/// Fluent validation builder
class Validator<T> {
  final List<ValidationRule<T>> _rules = [];

  Validator<T> required([String? message]) {
    if (T == String) {
      _rules.add(RequiredRule(message) as ValidationRule<T>);
    }
    return this;
  }

  Validator<T> minLength(int length, [String? message]) {
    if (T == String) {
      _rules.add(MinLengthRule(length, message) as ValidationRule<T>);
    }
    return this;
  }

  Validator<T> maxLength(int length, [String? message]) {
    if (T == String) {
      _rules.add(MaxLengthRule(length, message) as ValidationRule<T>);
    }
    return this;
  }

  Validator<T> range(num min, num max, [String? message]) {
    if (T == num || T == int || T == double) {
      _rules.add(RangeRule(min, max, message) as ValidationRule<T>);
    }
    return this;
  }

  Validator<T> email([String? message]) {
    if (T == String) {
      _rules.add(EmailRule(message) as ValidationRule<T>);
    }
    return this;
  }

  Validator<T> custom(bool Function(T) validator, String message) {
    _rules.add(_CustomRule<T>(validator, message));
    return this;
  }

  ValidationResult validate(T value) {
    final errors = <String>[];
    
    for (final rule in _rules) {
      if (!rule.validate(value)) {
        errors.add(rule.message);
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid() 
        : ValidationResult.invalid(errors);
  }
}

class _CustomRule<T> extends ValidationRule<T> {
  final bool Function(T) validator;
  
  _CustomRule(this.validator, String message) : super(message);
  
  @override
  bool validate(T value) => validator(value);
}

/// Extension for easy validation
extension ValidationExtension on String {
  ValidationResult validateAs(String field) {
    return ValidationService.validateField(field, this);
  }
}

extension IntValidationExtension on int {
  ValidationResult validateAs(String field) {
    return ValidationService.validateField(field, this);
  }
}

extension ListValidationExtension<T> on List<T> {
  ValidationResult validateAs(String field) {
    return ValidationService.validateField(field, this);
  }
}

