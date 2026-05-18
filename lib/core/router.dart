import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/endpoints/image_generation/presentation/image_gen_screen.dart';
import '../features/endpoints/virtual_tryon/presentation/tryon_screen.dart';
import '../features/endpoints/image_edit/presentation/image_edit_screen.dart';
import '../features/endpoints/upscale/presentation/upscale_screen.dart';
import '../features/endpoints/product_makeover/presentation/product_makeover_screen.dart';
import '../features/endpoints/fix_old_image/presentation/fix_old_image_screen.dart';
import '../features/endpoints/video_generation/presentation/video_gen_screen.dart';
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
      if (loggedIn && onAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      ShellRoute(
        builder: (context, state, child) => PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            final currentPath = state.uri.path;
            if (currentPath == '/home') {
              return;
            }
            context.go('/home');
          },
          child: AppShell(child: child),
        ),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/generate', builder: (_, __) => const ImageGenScreen()),
          GoRoute(path: '/tryon', builder: (_, __) => const TryonScreen()),
          GoRoute(path: '/edit', builder: (_, __) => const ImageEditScreen()),
          GoRoute(path: '/upscale', builder: (_, __) => const UpscaleScreen()),
          GoRoute(path: '/product-makeover', builder: (_, __) => const ProductMakeoverScreen()),
          GoRoute(path: '/fixoldimage', builder: (_, __) => const FixOldImageScreen()),
          GoRoute(path: '/video-gen', builder: (_, __) => const VideoGenScreen()),
          GoRoute(path: '/history', builder: (_, __) => const GalleryScreen()),
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
                _NavItem(icon: Icons.home, label: 'Home', isSelected: _isSelected(context, '/home'), onTap: () => context.go('/home')),
                _NavItem(icon: Icons.more_horiz, label: 'Tools', isSelected: _isSelected(context, '/generate') || _isSelected(context, '/tryon') || _isSelected(context, '/edit') || _isSelected(context, '/upscale') || _isSelected(context, '/product-makeover') || _isSelected(context, '/fixoldimage') || _isSelected(context, '/video-gen'), onTap: () => _showToolsMenu(context)),
                _NavItem(icon: Icons.photo_library, label: 'Gallery', isSelected: _isSelected(context, '/history'), onTap: () => context.go('/history')),
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

  void _showToolsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('AI Tools', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            _ToolTile(icon: Icons.auto_awesome, label: 'Generate Image', onTap: () { Navigator.pop(ctx); context.go('/generate'); }),
            _ToolTile(icon: Icons.checkroom, label: 'Virtual Try-On', onTap: () { Navigator.pop(ctx); context.go('/tryon'); }),
            const Divider(height: AppSpacing.lg),
            _ToolTile(icon: Icons.videocam, label: 'Video Generation', onTap: () { Navigator.pop(ctx); context.go('/video-gen'); }),
            const Divider(height: AppSpacing.lg),
            _ToolTile(icon: Icons.edit, label: 'Edit Image', onTap: () { Navigator.pop(ctx); context.go('/edit'); }),
            _ToolTile(icon: Icons.zoom_in, label: 'Upscale', onTap: () { Navigator.pop(ctx); context.go('/upscale'); }),
            _ToolTile(icon: Icons.store, label: 'Product Makeover', onTap: () { Navigator.pop(ctx); context.go('/product-makeover'); }),
            _ToolTile(icon: Icons.restore, label: 'Fix Old Image', onTap: () { Navigator.pop(ctx); context.go('/fixoldimage'); }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cohereBlack),
      title: Text(label, style: AppTextStyles.bodyMedium),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
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