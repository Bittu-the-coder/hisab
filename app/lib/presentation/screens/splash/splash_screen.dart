import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_providers.dart';
import '../../widgets/hisab_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideUp;
  final _animationDone = Completer<void>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (!_animationDone.isCompleted) _animationDone.complete();
      }
    });
    _controller.forward();
    _checkAuth();
  }

  @override
  void dispose() {
    if (!_animationDone.isCompleted) _animationDone.complete();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
    if (!mounted) return;
    if (!seenOnboarding) {
      await _animationDone.future;
      if (!mounted) return;
      context.go('/onboarding');
      return;
    }

    final storage = ref.read(localStorageProvider);
    final cachedUser = await storage.getCachedUser();
    if (!mounted) return;

    await _animationDone.future;
    if (!mounted) return;

    if (cachedUser != null) {
      final auth = ref.read(authProvider.notifier);
      auth.tryAutoLogin();
      context.go('/home/dashboard');
      return;
    }

    final token = await storage.getAccessToken();
    if (!mounted) return;

    if (token != null) {
      final auth = ref.read(authProvider.notifier);
      await auth.tryAutoLogin();
      if (!mounted) return;
      final user = ref.read(authProvider);
      context.go(user.valueOrNull != null ? '/home/dashboard' : '/login');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SlideTransition(
          position: _slideUp,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HisabLogo(size: 80),
                const SizedBox(height: 20),
                Text('हिसाब', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  'Know where your money goes.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}
