import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/endpoints/image_generation/presentation/image_gen_screen.dart';
import '../features/endpoints/virtual_tryon/presentation/tryon_screen.dart';
import '../features/history/presentation/history_screen.dart';
import 'theme/theme_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authState is AuthAuthenticated;
      final onAuth = state.uri.path == '/login' || state.uri.path == '/register';
      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) return '/generate';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/generate', builder: (_, __) => const ImageGenScreen()),
          GoRoute(path: '/tryon', builder: (_, __) => const TryonScreen()),
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ],
      ),
    ],
  );
});

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvasWhite,
          border: Border(top: BorderSide(color: AppColors.hairline, width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.auto_awesome, label: 'Generate', isSelected: _isSelected(context, '/generate'), onTap: () => context.go('/generate')),
                _NavItem(icon: Icons.checkroom, label: 'Try-On', isSelected: _isSelected(context, '/tryon'), onTap: () => context.go('/tryon')),
                _NavItem(icon: Icons.history, label: 'History', isSelected: _isSelected(context, '/history'), onTap: () => context.go('/history')),
                _NavItem(icon: Icons.logout, label: 'Logout', isSelected: false, onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(authNotifierProvider.notifier).signOut();
                            context.go('/login');
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSelected(BuildContext context, String path) => GoRouterState.of(context).uri.path == path;
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.cohereBlack : AppColors.mutedSlate;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}