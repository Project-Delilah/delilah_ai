import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/image_gen_provider.dart';

class ImageGenScreen extends ConsumerStatefulWidget {
  const ImageGenScreen({super.key});

  @override
  ConsumerState<ImageGenScreen> createState() => _ImageGenScreenState();
}

class _ImageGenScreenState extends ConsumerState<ImageGenScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(imageGenNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generate Image', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.softStone,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Describe your image', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: AppSpacing.md),
                    GlassInput(controller: _promptController, hint: 'A futuristic city with neon lights at sunset...', icon: Icons.edit_note),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: () {
                          final prompt = _promptController.text.trim();
                          if (prompt.isEmpty) return;
                          ref.read(imageGenNotifierProvider.notifier).generate(prompt);
                        },
                        label: 'Generate',
                        icon: Icons.play_arrow,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Result', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              AsyncValueWidget<String?>(asyncValue: imageState, builder: (url) => _buildResult(url)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(String? imageUrl) {
    if (imageUrl == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.image_outlined, color: AppColors.mutedSlate, size: 48),
              const SizedBox(height: AppSpacing.sm),
              Text('Your generated image will appear here', style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              height: 300,
              color: AppColors.softStone,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 300,
              color: AppColors.softStone,
              child: const Icon(Icons.error, color: AppColors.errorRed),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            onPressed: () async {
              final success = await WallpaperEngine.applyFromUrl(imageUrl);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Wallpaper set successfully!' : 'Failed to set wallpaper'),
                    backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
                  ),
                );
              }
            },
            label: 'Set as Wallpaper',
            icon: Icons.wallpaper,
            isPrimary: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => ref.read(imageGenNotifierProvider.notifier).reset(),
          child: Text('Generate Another', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.actionBlue)),
        ),
      ],
    );
  }
}