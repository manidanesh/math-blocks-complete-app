import 'package:flutter/foundation.dart';
import '../services/error_handler_service.dart';
import '../services/translation_service.dart';

/// Base view model class implementing common MVVM patterns
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool _isDisposed = false;
  AppError? _error;
  String _language = 'en';

  /// Current loading state
  bool get isLoading => _isLoading;

  /// Current error state
  AppError? get error => _error;

  /// Current language
  String get language => _language;

  /// Whether the view model has been disposed
  bool get isDisposed => _isDisposed;

  /// Set loading state
  void setLoading(bool loading) {
    if (_isDisposed) return;
    
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Set error state
  void setError(AppError? error) {
    if (_isDisposed) return;
    
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// Clear error state
  void clearError() {
    setError(null);
  }

  /// Set language
  void setLanguage(String language) {
    if (_isDisposed) return;
    
    if (_language != language) {
      _language = language;
      notifyListeners();
    }
  }

  /// Get translated text
  String getText(String key, [Map<String, dynamic>? params]) {
    if (params != null) {
      return TranslationService.getTextWithParams(key, params, _language);
    }
    return TranslationService.getText(key, _language);
  }

  /// Execute an async operation with loading and error handling
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
    String? customErrorMessage,
    ErrorType? errorType,
  }) async {
    if (_isDisposed) return null;

    try {
      if (showLoading) {
        setLoading(true);
        clearError();
      }

      final result = await operation();
      
      if (!_isDisposed && showLoading) {
        setLoading(false);
      }
      
      return result;
    } catch (error, stackTrace) {
      if (!_isDisposed) {
        setLoading(false);
        
        final appError = ErrorHandlerService.handleError(
          error,
          type: errorType,
          customMessage: customErrorMessage,
          stackTrace: stackTrace,
          language: _language,
        );
        
        setError(appError);
      }
      
      return null;
    }
  }

  /// Execute an async operation without error handling (errors bubble up)
  Future<T> executeAsyncRaw<T>(
    Future<T> Function() operation, {
    bool showLoading = true,
  }) async {
    if (_isDisposed) throw Exception('ViewModel disposed');

    try {
      if (showLoading) {
        setLoading(true);
        clearError();
      }

      final result = await operation();
      
      if (!_isDisposed && showLoading) {
        setLoading(false);
      }
      
      return result;
    } finally {
      if (!_isDisposed && showLoading) {
        setLoading(false);
      }
    }
  }

  /// Retry the last failed operation
  Future<void> retry() async {
    clearError();
    await onRetry();
  }

  /// Override this method to implement retry logic
  Future<void> onRetry() async {
    // Default implementation does nothing
    // Subclasses should override this
  }

  /// Initialize the view model
  Future<void> initialize() async {
    // Override in subclasses if needed
  }

  /// Dispose resources
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Check if the view model is in a valid state for operations
  bool get canExecute => !_isDisposed && !_isLoading;

  /// Validate input data
  bool validateInput(Map<String, dynamic> data) {
    // Override in subclasses for specific validation
    return true;
  }

  /// Handle validation errors
  void handleValidationError(String field, String message) {
    final error = AppError(
      message: message,
      type: ErrorType.validation,
      details: 'Field: $field',
    );
    setError(error);
  }

  /// Reset the view model to its initial state
  void reset() {
    clearError();
    setLoading(false);
    // Override in subclasses to reset specific state
  }
}

/// Mixin for view models that need periodic updates
mixin PeriodicUpdateMixin on BaseViewModel {
  bool _isPeriodicUpdateActive = false;
  Duration _updateInterval = const Duration(seconds: 30);

  bool get isPeriodicUpdateActive => _isPeriodicUpdateActive;
  Duration get updateInterval => _updateInterval;

  void setUpdateInterval(Duration interval) {
    _updateInterval = interval;
  }

  void startPeriodicUpdate() {
    if (_isPeriodicUpdateActive || isDisposed) return;
    
    _isPeriodicUpdateActive = true;
    _scheduleNextUpdate();
  }

  void stopPeriodicUpdate() {
    _isPeriodicUpdateActive = false;
  }

  void _scheduleNextUpdate() {
    if (!_isPeriodicUpdateActive || isDisposed) return;
    
    Future.delayed(_updateInterval, () {
      if (_isPeriodicUpdateActive && !isDisposed) {
        onPeriodicUpdate();
        _scheduleNextUpdate();
      }
    });
  }

  /// Override this method to implement periodic update logic
  Future<void> onPeriodicUpdate() async {
    // Default implementation does nothing
  }

  @override
  void dispose() {
    stopPeriodicUpdate();
    super.dispose();
  }
}

/// Mixin for view models that handle collections/lists
mixin CollectionMixin<T> on BaseViewModel {
  List<T> _items = [];
  String _searchQuery = '';
  bool _hasMore = true;
  int _currentPage = 0;

  List<T> get items => _items;
  String get searchQuery => _searchQuery;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.length;

  void setItems(List<T> items) {
    if (isDisposed) return;
    
    _items = List.from(items);
    notifyListeners();
  }

  void addItems(List<T> items) {
    if (isDisposed) return;
    
    _items.addAll(items);
    notifyListeners();
  }

  void addItem(T item) {
    if (isDisposed) return;
    
    _items.add(item);
    notifyListeners();
  }

  void removeItem(T item) {
    if (isDisposed) return;
    
    _items.remove(item);
    notifyListeners();
  }

  void updateItem(T oldItem, T newItem) {
    if (isDisposed) return;
    
    final index = _items.indexOf(oldItem);
    if (index >= 0) {
      _items[index] = newItem;
      notifyListeners();
    }
  }

  void clearItems() {
    if (isDisposed) return;
    
    _items.clear();
    _currentPage = 0;
    _hasMore = true;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (isDisposed) return;
    
    if (_searchQuery != query) {
      _searchQuery = query;
      _currentPage = 0;
      _hasMore = true;
      notifyListeners();
    }
  }

  void setHasMore(bool hasMore) {
    if (isDisposed) return;
    
    if (_hasMore != hasMore) {
      _hasMore = hasMore;
      notifyListeners();
    }
  }

  void incrementPage() {
    _currentPage++;
  }

  @override
  void reset() {
    super.reset();
    clearItems();
    setSearchQuery('');
  }
}

