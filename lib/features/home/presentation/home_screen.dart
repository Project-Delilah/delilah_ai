import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/glass_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        color: AppColors.actionBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Delilah', style: AppTextStyles.displayLarge.copyWith(color: AppColors.cohereBlack)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('AI Image Studio', style: AppTextStyles.titleMedium.copyWith(color: AppColors.mutedSlate)),
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
                    Text('AI-Powered Image Tools', style: AppTextStyles.titleLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Generate stunning images, try on virtual clothes, upscale photos, and more.', 
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
                icon: Icons.edit,
                title: 'Edit Image',
                description: 'Apply filters and modifications',
                onTap: () => context.go('/edit'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionCard(
                icon: Icons.photo_library,
                title: 'Gallery',
                description: 'View your generated images',
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
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColors.canvasWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: controller,
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
                Text('All AI Tools', style: AppTextStyles.titleMedium),
                const SizedBox(height: AppSpacing.lg),
                _ToolTile(icon: Icons.auto_awesome, label: 'Generate Image', onTap: () { Navigator.pop(ctx); context.go('/generate'); }),
                _ToolTile(icon: Icons.checkroom, label: 'Virtual Try-On', onTap: () { Navigator.pop(ctx); context.go('/tryon'); }),
                _ToolTile(icon: Icons.edit, label: 'Edit Image', onTap: () { Navigator.pop(ctx); context.go('/edit'); }),
                _ToolTile(icon: Icons.zoom_in, label: 'Upscale', onTap: () { Navigator.pop(ctx); context.go('/upscale'); }),
                _ToolTile(icon: Icons.store, label: 'Product Makeover', onTap: () { Navigator.pop(ctx); context.go('/product-makeover'); }),
                _ToolTile(icon: Icons.restore, label: 'Fix Old Image', onTap: () { Navigator.pop(ctx); context.go('/fixoldimage'); }),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
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

  const _QuickActionCard({required this.icon, required this.title, required this.description, required this.onTap});

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
                  Text(title, style: AppTextStyles.bodyLarge),
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