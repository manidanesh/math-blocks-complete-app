import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../screens/profile_creation_screen.dart';
import '../screens/mode_select_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/profile_history_screen.dart';
import '../screens/challenge_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/profile-creation',
    redirect: (context, state) {
      // If profile is loading, stay where we are
      if (profileAsync.isLoading) {
        return null;
      }
      
      // If no profile exists, go to profile creation
      if (profileAsync.value == null && state.fullPath != '/profile-creation') {
        return '/profile-creation';
      }
      
      // If profile exists and we're on profile creation, go to mode select
      if (profileAsync.value != null && state.fullPath == '/profile-creation') {
        return '/mode-select';
      }
      
      return null;
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
        path: '/profile-history',
        name: 'profile-history',
        builder: (context, state) => const ProfileHistoryScreen(),
      ),
      GoRoute(
        path: '/challenge',
        name: 'challenge',
        builder: (context, state) => const ChallengeScreen(),
      ),
    ],
  );
});
