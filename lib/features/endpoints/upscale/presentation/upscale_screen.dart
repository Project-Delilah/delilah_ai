import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/upscale_provider.dart';

class UpscaleScreen extends ConsumerStatefulWidget {
  const UpscaleScreen({super.key});

  @override
  ConsumerState<UpscaleScreen> createState() => _UpscaleScreenState();
}

class _UpscaleScreenState extends ConsumerState<UpscaleScreen> {
  final _imageUrlController = TextEditingController();
  final _focusController = TextEditingController(text: 'Enhance resolution, sharp focus, and remove digital compression noise.');

  @override
  void dispose() {
    _imageUrlController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(upscaleNotifierProvider);
    final notifier = ref.read(upscaleNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upscale Image', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              if (state.resultUrl != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(imageUrl: state.resultUrl!, fit: BoxFit.cover, width: double.infinity),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(child: GlassButton(onPressed: () => WallpaperEngine.applyFromUrl(state.resultUrl!), label: 'Set Wallpaper', icon: Icons.wallpaper)),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton(onPressed: () => notifier.reset(), label: 'New', icon: Icons.add, isPrimary: false),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.softStone, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Image URL', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _imageUrlController, hint: 'https://...', icon: Icons.image),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Enhancement Focus', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _focusController, hint: 'Enhance resolution...', icon: Icons.tune),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          onPressed: state.isLoading ? null : () {
                            final url = _imageUrlController.text.trim();
                            final focus = _focusController.text.trim();
                            if (url.isEmpty || focus.isEmpty) return;
                            notifier.setImageUrl(url);
                            notifier.upscale(focus);
                          },
                          label: state.isLoading ? 'Processing...' : 'Upscale',
                          icon: Icons.zoom_in,
                        ),
                      ),
                      if (state.error != null) ...[const SizedBox(height: AppSpacing.md), Text(state.error!, style: TextStyle(color: AppColors.errorRed))],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}