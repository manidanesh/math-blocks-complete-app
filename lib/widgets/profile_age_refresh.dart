import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/kid_profile.dart';
import '../providers/profile_provider.dart';

/// Refreshes visible ages after returning to the app and at local midnight.
class ProfileAgeRefresh extends ConsumerStatefulWidget {
  final Widget child;

  const ProfileAgeRefresh({super.key, required this.child});

  @override
  ConsumerState<ProfileAgeRefresh> createState() => _ProfileAgeRefreshState();
}

class _ProfileAgeRefreshState extends ConsumerState<ProfileAgeRefresh>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  ProviderSubscription<AsyncValue<KidProfile?>>? _profileSubscription;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isForeground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _profileSubscription = ref.listenManual(profileProvider, (previous, next) {
      _scheduleMidnight();
    }, fireImmediately: true);
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    if (!_isForeground ||
        ref.read(profileProvider).value?.hasBirthYear != true) {
      return;
    }
    final now = ref.read(profileNowProvider)();
    final tomorrow = now.isUtc
        ? DateTime.utc(now.year, now.month, now.day + 1)
        : DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(tomorrow.difference(now), () {
      if (!mounted) return;
      unawaited(ref.read(profileProvider.notifier).refreshAge());
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      unawaited(ref.read(profileProvider.notifier).refreshAge());
      _scheduleMidnight();
    } else {
      _midnightTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    _profileSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
