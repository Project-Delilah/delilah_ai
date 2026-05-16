import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/fix_old_image_provider.dart';

class FixOldImageScreen extends ConsumerStatefulWidget {
  const FixOldImageScreen({super.key});

  @override
  ConsumerState<FixOldImageScreen> createState() => _FixOldImageScreenState();
}

class _FixOldImageScreenState extends ConsumerState<FixOldImageScreen> {
  final _imageUrlController = TextEditingController();
  final _instructionsController = TextEditingController(text: 'Remove dust scratches, fix tears, and balance faded colors naturally.');

  @override
  void dispose() {
    _imageUrlController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fixOldImageNotifierProvider);
    final notifier = ref.read(fixOldImageNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Fix Old Image', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              if (state.resultUrl != null) ...[
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)),
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
                      Text('Repair Instructions', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _instructionsController, hint: 'Remove dust, fix tears...', icon: Icons.build),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          onPressed: state.isLoading ? null : () {
                            final url = _imageUrlController.text.trim();
                            final inst = _instructionsController.text.trim();
                            if (url.isEmpty || inst.isEmpty) return;
                            notifier.setImageUrl(url);
                            notifier.fixImage(inst);
                          },
                          label: state.isLoading ? 'Processing...' : 'Restore Image',
                          icon: Icons.restore,
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