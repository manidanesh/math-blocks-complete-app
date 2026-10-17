import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Keeps an unfinished challenge outcome available across navigation and restarts.
class PendingCompletionService {
  static const _keyPrefix = 'pending_challenge_completion_';
  static Future<void>? _pendingOperation;
  static final _completionQueues = <String, Future<void>>{};
  static final _generations = <String, int>{};

  static int currentGeneration(String childId) => _generations[childId] ?? 0;

  static Future<T> _completionLock<T>(
    String childId,
    Future<T> Function() operation,
  ) async {
    final previous = _completionQueues[childId];
    final completed = Completer<void>();
    _completionQueues[childId] = completed.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      if (identical(_completionQueues[childId], completed.future)) {
        _completionQueues.remove(childId);
      }
      completed.complete();
    }
  }

  /// A reset cancels older queued deliveries while allowing an active outcome
  /// to finish before its records are cleared.
  static Future<bool> runCompletion(
    String childId,
    Future<void> Function() operation, {
    int? expectedGeneration,
    String? expectedEventId,
  }) {
    final generation = expectedGeneration ?? currentGeneration(childId);
    return _completionLock(childId, () async {
      if (currentGeneration(childId) != generation) return false;
      if (expectedEventId != null &&
          (await load(childId))?['eventId'] != expectedEventId) {
        return false;
      }
      await operation();
      return true;
    });
  }

  static Future<T> runReset<T>(String childId, Future<T> Function() operation) {
    _generations[childId] = (_generations[childId] ?? 0) + 1;
    return _completionLock(childId, operation);
  }

  // Reads wait for writes as well, so a second screen never recovers an
  // unconfirmed SharedPreferences cache entry.
  static Future<T> _serialize<T>(Future<T> Function() operation) async {
    final previous = _pendingOperation;
    final completed = Completer<void>();
    _pendingOperation = completed.future;
    try {
      if (previous != null) await previous;
      return await operation();
    } finally {
      if (identical(_pendingOperation, completed.future)) {
        _pendingOperation = null;
      }
      completed.complete();
    }
  }

  static Map<String, dynamic> _decode(String raw, String childId) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['childId'] != childId ||
        data['eventId'] is! String ||
        (data['eventId'] as String).isEmpty) {
      throw const FormatException('Invalid pending challenge identity.');
    }
    return data;
  }

  static Future<Map<String, dynamic>?> load(String childId) =>
      _serialize(() async {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('$_keyPrefix$childId');
        return raw == null ? null : _decode(raw, childId);
      });

  static Future<void> save(String childId, Map<String, dynamic> data) =>
      _serialize(() async {
        final encoded = jsonEncode(data);
        _decode(encoded, childId);
        final prefs = await SharedPreferences.getInstance();
        await _write(
          prefs,
          () => prefs.setString('$_keyPrefix$childId', encoded),
        );
      });

  /// Matching identity protects a newer pending outcome from an older callback.
  /// Omitting the identity is reserved for a child's explicit progress reset.
  static Future<void> clear(String childId, {String? eventId}) => _serialize(
    () async {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$childId';
      if (eventId != null) {
        final raw = prefs.getString(key);
        if (raw == null || _decode(raw, childId)['eventId'] != eventId) return;
      }
      await _write(prefs, () => prefs.remove(key));
    },
  );

  static Future<void> _write(
    SharedPreferences prefs,
    Future<bool> Function() operation,
  ) async {
    try {
      if (!await operation()) {
        throw StateError('Could not save the pending challenge outcome.');
      }
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
  }
}
