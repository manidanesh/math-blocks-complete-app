import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/error_handler_service.dart';

/// Abstract base repository with common storage operations
abstract class BaseRepository<T> {
  final String storageKey;

  BaseRepository(this.storageKey);

  /// Serialize an object to JSON string
  String serialize(T item);

  /// Deserialize JSON string to object
  T deserialize(String json);

  /// Save a single item
  Future<void> save(T item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = serialize(item);
      await prefs.setString(storageKey, jsonString);
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Load a single item
  Future<T?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      
      if (jsonString == null) return null;
      
      return deserialize(jsonString);
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Save a list of items
  Future<void> saveList(List<T> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => serialize(item)).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(storageKey, jsonString);
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Load a list of items
  Future<List<T>> loadList() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(storageKey);
      
      if (jsonString == null) return [];
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => deserialize(json)).toList();
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Delete stored data
  Future<void> delete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(storageKey);
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if data exists
  Future<bool> exists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(storageKey);
    } catch (error, stackTrace) {
      throw ErrorHandlerService.handleError(
        error,
        type: ErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clear all data (useful for reset functionality)
  Future<void> clear() async {
    await delete();
  }
}

/// Generic repository for items with IDs
abstract class EntityRepository<T extends Entity> extends BaseRepository<T> {
  EntityRepository(super.storageKey);

  /// Find item by ID
  Future<T?> findById(String id) async {
    final items = await loadList();
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Save or update an item in the list
  Future<void> saveItem(T item) async {
    final items = await loadList();
    final existingIndex = items.indexWhere((existing) => existing.id == item.id);
    
    if (existingIndex >= 0) {
      items[existingIndex] = item;
    } else {
      items.add(item);
    }
    
    await saveList(items);
  }

  /// Delete an item by ID
  Future<bool> deleteById(String id) async {
    final items = await loadList();
    final originalLength = items.length;
    items.removeWhere((item) => item.id == id);
    
    if (items.length < originalLength) {
      await saveList(items);
      return true;
    }
    
    return false;
  }

  /// Get all items
  Future<List<T>> getAll() async {
    return await loadList();
  }

  /// Update an item
  Future<bool> update(T item) async {
    final items = await loadList();
    final index = items.indexWhere((existing) => existing.id == item.id);
    
    if (index >= 0) {
      items[index] = item;
      await saveList(items);
      return true;
    }
    
    return false;
  }

  /// Count total items
  Future<int> count() async {
    final items = await loadList();
    return items.length;
  }
}

/// Base entity interface
abstract class Entity {
  String get id;
}

/// Repository result wrapper
class RepositoryResult<T> {
  final T? data;
  final bool success;
  final String? error;

  RepositoryResult.success(this.data) 
      : success = true, 
        error = null;

  RepositoryResult.error(this.error) 
      : success = false, 
        data = null;

  bool get hasData => data != null;
  bool get hasError => error != null;
}

