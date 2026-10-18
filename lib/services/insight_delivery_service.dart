import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_log.dart';
import 'insights_engine.dart';

/// Retains analytics until delivery succeeds, independently of earned rewards.
class InsightDeliveryService {
  static Future<void>? _pending;
  static String _key(String childId) => 'pending_insight_events_$childId';

  static Future<void> _serialize(Future<void> Function() operation) {
    final previous = _pending;
    final next = previous == null
        ? Future<void>.sync(operation)
        : previous.then(
            (_) => operation(),
            onError: (Object _, StackTrace _) => operation(),
          );
    late final Future<void> queued;
    queued = next.whenComplete(() {
      if (identical(_pending, queued)) _pending = null;
    });
    _pending = queued;
    return queued;
  }

  static List<Map<String, dynamic>> _read(
    SharedPreferences prefs,
    String childId,
  ) {
    final raw = prefs.getString(_key(childId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((event) => Map<String, dynamic>.from(event as Map))
        .toList();
  }

  static Future<void> _save(
    SharedPreferences prefs,
    String childId,
    List<Map<String, dynamic>> events,
  ) async {
    try {
      final saved = events.isEmpty
          ? await prefs.remove(_key(childId))
          : await prefs.setString(_key(childId), jsonEncode(events));
      if (!saved) {
        throw StateError('Could not save pending learning analytics.');
      }
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
  }

  static Future<void> enqueue(String childId, Map<String, dynamic> event) =>
      _serialize(() async {
        final prefs = await SharedPreferences.getInstance();
        final events = _read(prefs, childId);
        if (events.any((saved) => saved['eventId'] == event['eventId'])) return;
        events.add(Map<String, dynamic>.from(event));
        await _save(prefs, childId, events);
      });

  /// Failed delivery stays queued; starting another challenge retries it.
  static Future<void> flush(String childId) => _serialize(() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = _read(prefs, childId);
      while (events.isNotEmpty) {
        final event = events.first;
        await InsightsEngine.logProblem(
          childId: childId,
          eventId: event['eventId'] as String,
          problemType: event['problemType'] as String,
          numbersUsed: (event['numbersUsed'] as List).cast<int>(),
          correct: event['correct'] as bool,
          timeTaken: event['timeTaken'] as num,
          hintUsed: event['hintUsed'] as bool,
          level: event['level'] as String,
          strategy: event['strategy'] as String,
          timestamp: DateTime.parse(event['timestamp'] as String),
        );
        events.removeAt(0);
        await _save(prefs, childId, events);
      }
    } catch (error) {
      debugLog('Learning analytics remain queued: $error');
    }
  });

  static Future<void> clear(String childId) => _serialize(() async {
    final prefs = await SharedPreferences.getInstance();
    await _save(prefs, childId, []);
  });
}
