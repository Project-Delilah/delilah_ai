import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/async_value_widget.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/image_edit_provider.dart';

class ImageEditScreen extends ConsumerStatefulWidget {
  const ImageEditScreen({super.key});

  @override
  ConsumerState<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends ConsumerState<ImageEditScreen> {
  final _imageUrlController = TextEditingController();
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _imageUrlController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(imageEditNotifierProvider);
    final notifier = ref.read(imageEditNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Image', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              if (editState.resultUrl != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: editState.resultUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (_, __) => Container(
                      height: 200,
                      color: AppColors.softStone,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => WallpaperEngine.applyFromUrl(editState.resultUrl!),
                        label: 'Set Wallpaper',
                        icon: Icons.wallpaper,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton(
                      onPressed: () => notifier.reset(),
                      label: 'New',
                      icon: Icons.add,
                      isPrimary: false,
                    ),
                  ],
                ),
              ] else ...[
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
                      Text('Image URL', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(
                        controller: _imageUrlController,
                        hint: 'https://...',
                        icon: Icons.image,
                      ),
                      if (editState.imageUrl != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: editState.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text('Edit Instructions', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(
                        controller: _promptController,
                        hint: 'Convert to sepia, add vintage filter...',
                        icon: Icons.edit_note,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          onPressed: editState.isLoading
                              ? null
                              : () {
                                  final url = _imageUrlController.text.trim();
                                  final prompt = _promptController.text.trim();
                                  if (url.isEmpty || prompt.isEmpty) return;
                                  notifier.pickImage(url);
                                  notifier.editImage(prompt);
                                },
                          label: editState.isLoading ? 'Processing...' : 'Apply Edit',
                          icon: Icons.auto_fix_high,
                        ),
                      ),
                      if (editState.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          editState.error!,
                          style: TextStyle(color: AppColors.errorRed),
                        ),
                      ],
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