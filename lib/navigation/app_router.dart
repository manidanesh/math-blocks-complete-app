import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';
import '../screens/profile_creation_screen.dart';
import '../screens/mode_select_screen.dart';
import '../screens/practice_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/adaptive_challenge_screen.dart';

// Create a router that only redirects for initial navigation
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/profile-creation',
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
        builder: (context, state) => const AdaptiveChallengeScreen(),
      ),
    ],
  );
});
