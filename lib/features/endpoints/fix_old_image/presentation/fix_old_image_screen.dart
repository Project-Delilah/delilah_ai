import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
  final _instructionsController = TextEditingController(text: 'Remove dust scratches, fix tears, and balance faded colors naturally.');

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    final extension = image.path.split('.').last.toLowerCase();
    if (['gif', 'mp4', 'mov', 'avi', 'webm'].contains(extension)) return;
    final file = File(image.path);
    await ref.read(fixOldImageNotifierProvider.notifier).setImage(file);
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
                _ImagePickerCard(
                  imageFile: state.imageFile,
                  imageUrl: state.imageUrl,
                  isUploading: state.isUploading,
                  onPick: state.isUploading || state.isProcessing ? null : _pickImage,
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.softStone, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repair Instructions', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _instructionsController, hint: 'Remove dust, fix tears...', icon: Icons.build),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          onPressed: (state.imageUrl != null && !state.isUploading && !state.isProcessing)
                              ? () => notifier.fixImage(_instructionsController.text.trim())
                              : null,
                          label: state.isProcessing ? 'Processing...' : 'Restore Image',
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

class _ImagePickerCard extends StatelessWidget {
  final File? imageFile;
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback? onPick;

  const _ImagePickerCard({this.imageFile, this.imageUrl, this.isUploading = false, this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.hairline),
        ),
        child: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover),
                    if (isUploading)
                      Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator())),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 48, color: AppColors.mutedSlate),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Tap to select image', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedSlate)),
                ],
              ),
      ),
    );
  }
}