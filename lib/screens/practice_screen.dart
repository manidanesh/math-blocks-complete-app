import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';

class PracticeScreen extends ConsumerWidget {
  const PracticeScreen({super.key});

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
      data: (profile) => Scaffold(
        appBar: AppBar(
          title: Text('Practice - ${profile?.name ?? "Unknown"}'),
          backgroundColor: const Color(0xFF3498DB),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.construction, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Practice Screen Coming Soon!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('This will have:'),
              Text('• Number bond visualization'),
              Text('• 3-attempt failure tracking'),
              Text('• Step-by-step explanations'),
              Text('• Adaptive learning engine'),
            ],
          ),
        ),
      ),
    );
  }
}
