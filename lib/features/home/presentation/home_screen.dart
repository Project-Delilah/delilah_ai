import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/glass_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: const Image(
                          image: AssetImage('assets/android-flutter-icon.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Delilah', style: AppTextStyles.displayLarge.copyWith(color: AppColors.cohereBlack)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('AI Media Studio', style: AppTextStyles.titleMedium.copyWith(color: AppColors.mutedSlate)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.actionBlue, AppColors.actionBlue.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield, color: Colors.white, size: 32),
                    const SizedBox(height: AppSpacing.md),
                    Text('AI-Powered Media Tools', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Generate stunning images, create videos from text or images, try on virtual clothes, and more.', 
                         style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Quick Start', style: AppTextStyles.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _QuickActionCard(
                icon: Icons.auto_awesome,
                title: 'Generate Image',
                description: 'Create images from text prompts',
                onTap: () => context.go('/generate'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionCard(
                icon: Icons.checkroom,
                title: 'Virtual Try-On',
                description: 'Try on clothes with your photo',
                onTap: () => context.go('/tryon'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionCard(
                icon: Icons.videocam,
                title: 'Video Generation',
                description: 'Create videos from text or images',
                onTap: () => context.go('/video-gen'),
                isNew: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                description: 'View your generated media',
                onTap: () => context.go('/history'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: GlassButton(
                  onPressed: () => _showAllTools(context),
                  label: 'View All Tools',
                  icon: Icons.apps,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Tools', style: AppTextStyles.titleMedium),
                    const SizedBox(height: AppSpacing.lg),
                    Text('IMAGE', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedSlate, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    _ToolTile(icon: Icons.auto_awesome, label: 'Generate Image', onTap: () { Navigator.pop(ctx); context.go('/generate'); }),
                    _ToolTile(icon: Icons.checkroom, label: 'Virtual Try-On', onTap: () { Navigator.pop(ctx); context.go('/tryon'); }),
                    const SizedBox(height: AppSpacing.md),
                    Text('VIDEO', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedSlate, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    _ToolTile(icon: Icons.videocam, label: 'Video Generation', onTap: () { Navigator.pop(ctx); context.go('/video-gen'); }),
                    const SizedBox(height: AppSpacing.md),
                    Text('EDITING', style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedSlate, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                    const SizedBox(height: AppSpacing.sm),
                    _ToolTile(icon: Icons.edit, label: 'Edit Image', onTap: () { Navigator.pop(ctx); context.go('/edit'); }),
                    _ToolTile(icon: Icons.zoom_in, label: 'Upscale', onTap: () { Navigator.pop(ctx); context.go('/upscale'); }),
                    _ToolTile(icon: Icons.store, label: 'Product Makeover', onTap: () { Navigator.pop(ctx); context.go('/product-makeover'); }),
                    _ToolTile(icon: Icons.restore, label: 'Fix Old Image', onTap: () { Navigator.pop(ctx); context.go('/fixoldimage'); }),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool isNew;

  const _QuickActionCard({
    required this.icon, 
    required this.title, 
    required this.description, 
    required this.onTap,
    this.isNew = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.canvasWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.actionBlue),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppTextStyles.bodyLarge),
                      if (isNew) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.actionBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'NEW',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedSlate)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedSlate),
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