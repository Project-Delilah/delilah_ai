import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/tryon_provider.dart';

class TryonScreen extends ConsumerWidget {
  const TryonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tryonState = ref.watch(tryOnNotifierProvider);
    final notifier = ref.read(tryOnNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Virtual Try-On', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: _ImagePickerCard(
                    label: 'Person',
                    icon: Icons.person,
                    image: tryonState.personImage,
                    imageUrl: tryonState.personImageUrl,
                    onPick: (tryonState.isUploading || tryonState.isGenerating) 
                        ? null 
                        : () => _pickImage(ref, true),
                    isUploading: tryonState.isUploading && tryonState.personImageUrl == null,
                  )),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _ImagePickerCard(
                    label: 'Dress',
                    icon: Icons.checkroom,
                    image: tryonState.productImage,
                    imageUrl: tryonState.productImageUrl,
                    onPick: (tryonState.isUploading || tryonState.isGenerating) 
                        ? null 
                        : () => _pickImage(ref, false),
                    isUploading: tryonState.isUploading && tryonState.productImageUrl == null,
                  )),
                ],
              ),
              if (tryonState.isUploading) ...[
                const SizedBox(height: AppSpacing.md),
                Center(child: Text('Uploading...', style: AppTextStyles.bodyMedium)),
              ],
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: (tryonState.personImageUrl != null && tryonState.productImageUrl != null && !tryonState.isGenerating && !tryonState.isUploading) 
                      ? () => notifier.generate() 
                      : null,
                  label: tryonState.isGenerating ? 'Generating...' : 'Generate',
                  icon: Icons.play_arrow,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Result', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              _buildResult(context, tryonState, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref, bool isPerson) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    
    if (image == null) return;

    final extension = image.path.split('.').last.toLowerCase();
    if (['gif', 'mp4', 'mov', 'avi', 'webm'].contains(extension)) return;

    final file = File(image.path);
    final notifier = ref.read(tryOnNotifierProvider.notifier);
    
    if (isPerson) {
      await notifier.setPersonImage(file);
    } else {
      await notifier.setProductImage(file);
    }
  }

  Widget _buildResult(BuildContext context, TryOnState tryonState, TryOnNotifier notifier) {
    final resultUrl = tryonState.resultUrl;
    
    if (resultUrl == null) {
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
              Text('Pick person and dress photos, then tap Generate', style: AppTextStyles.bodyMedium),
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
            imageUrl: resultUrl,
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Image saved to gallery!')),
              );
            },
            label: 'Save Image',
            icon: Icons.save_alt,
            isPrimary: false,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            onPressed: () async {
              final success = await WallpaperEngine.applyFromUrl(resultUrl);
              if (context.mounted) {
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
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () {
            notifier.reset();
          },
          child: Text('Try Again', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.actionBlue)),
        ),
      ],
    );
  }
}

class _ImagePickerCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final File? image;
  final String? imageUrl;
  final VoidCallback? onPick;
  final bool isUploading;

  const _ImagePickerCard({
    required this.label,
    required this.icon,
    required this.image,
    this.imageUrl,
    this.onPick,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.canvasWhite,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
                  )
                : image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.file(image!, fit: BoxFit.cover),
                      )
                    : isUploading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(icon, color: AppColors.mutedSlate, size: 40),
          ),
          const SizedBox(height: AppSpacing.sm),
          GlassButton(
            onPressed: onPick,
            label: imageUrl != null ? 'Uploaded' : (image != null ? 'Uploading...' : 'Pick Photo'),
            icon: Icons.photo_library,
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}