import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/profile_provider.dart';

class ProfileHistoryScreen extends ConsumerWidget {
  const ProfileHistoryScreen({super.key});

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
          title: Text('${profile?.name ?? "Unknown"}\'s Profile'),
          backgroundColor: const Color(0xFF9B59B6),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.purple),
              SizedBox(height: 16),
              Text(
                'Profile History Coming Soon!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('This will show:'),
              Text('• Failed problem transactions'),
              Text('• Detailed explanations for each failure'),
              Text('• Performance analytics'),
              Text('• Progress over time'),
            ],
          ),
        ),
      ),
    );
  }
}
