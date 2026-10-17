import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../services/problem_generator.dart';

import '../screens/profile_creation_screen.dart';
import '../screens/mode_select_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/adaptive_challenge_screen.dart';

class _ProfileRouterRefresh extends ChangeNotifier {
  void refresh() => notifyListeners();
}

// Keep the router stable while refreshing redirects when the profile changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _ProfileRouterRefresh();
  ref.listen(profileProvider, (_, _) => refresh.refresh());
  final router = GoRouter(
    initialLocation: '/profile-creation',
    refreshListenable: refresh,
    redirect: (context, state) {
      final profile = ref.read(profileProvider);
      if (profile.isLoading) return null;
      if (profile.hasError) {
        return state.matchedLocation == '/mode-select' ? null : '/mode-select';
      }
      if (profile.value == null) {
        return state.matchedLocation == '/profile-creation'
            ? null
            : '/profile-creation';
      }
      return state.matchedLocation == '/profile-creation'
          ? '/mode-select'
          : null;
    },
    routes: [
      GoRoute(
        path: '/profile-creation',
        name: 'profile-creation',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      GoRoute(
        path: '/mode-select',
        name: 'mode-select',
        builder: (context, state) => const ModeSelectScreen(),
      ),
      GoRoute(
        path: '/practice',
        name: 'practice',
        builder: (context, state) => const PracticeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/challenge',
        name: 'challenge',
        builder: (context, state) {
          final extra = state.extra;
          final problem = extra is Map ? extra['problem'] : null;
          if (problem is! Map ||
              problem['operand1'] is! int ||
              problem['operand2'] is! int ||
              (problem['operator'] != '+' && problem['operator'] != '-')) {
            return const AdaptiveChallengeScreen();
          }
          final first = problem['operand1'] as int;
          final second = problem['operand2'] as int;
          final operation = problem['operator'] as String;
          final strategy = ProblemStrategy.values.firstWhere(
            (value) => value.name == problem['strategy'],
            orElse: () => ProblemStrategy.crossing,
          );
          return AdaptiveChallengeScreen(
            initialProblem: MathProblem(
              operand1: first,
              operand2: second,
              operator: operation,
              correctAnswer: operation == '+' ? first + second : first - second,
              problemText: '$first $operation $second',
              options: const [],
              strategy: strategy,
              level: problem['level'] is int ? problem['level'] as int : 1,
              explanation: '',
            ),
            initialShowSolution:
                extra is Map && extra['showExplanation'] == true,
          );
        },
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
