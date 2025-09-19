import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../services/language_service.dart';

class ModeSelectScreen extends ConsumerWidget {
  const ModeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('No profile found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('${'welcome'.tr(profile.language)} ${profile.name}!'),
            backgroundColor: const Color(0xFF3498DB),
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false, // Remove back button
            actions: [
              // Language flag
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    LanguageService.getFlag(profile.language),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => context.go('/profile-history'),
                tooltip: 'profile_history'.tr(profile.language),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3498DB),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text('🐱', style: TextStyle(fontSize: 30)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Age: ${profile.age} • Language: ${LanguageService.getFlag(profile.language)} ${LanguageService.getLanguageName(profile.language)}'),
                              Text('⭐ ${profile.totalStars} stars • 📚 ${profile.totalProblemsCompleted} problems'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Adaptive Challenge mode button
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => context.go('/adaptive-challenge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B59B6),
                      foregroundColor: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 32),
                        const SizedBox(height: 4),
                        const Text(
                          'Adaptive Challenge', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Regular Challenge mode button
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => context.go('/challenge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ECC71),
                      foregroundColor: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.psychology, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          'math_challenge'.tr(profile.language), 
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Profile button (unified)
                SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: ElevatedButton(
                    onPressed: () => context.go('/profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3498DB),
                      foregroundColor: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 32),
                        const SizedBox(height: 4),
                        Text(
                          'My Profile',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        );
      },
    );
  }
}
