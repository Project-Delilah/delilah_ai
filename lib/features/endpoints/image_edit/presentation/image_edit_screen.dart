import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/image_edit_provider.dart';

class ImageEditScreen extends ConsumerStatefulWidget {
  const ImageEditScreen({super.key});

  @override
  ConsumerState<ImageEditScreen> createState() => _ImageEditScreenState();
}

class _ImageEditScreenState extends ConsumerState<ImageEditScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    final extension = image.path.split('.').last.toLowerCase();
    if (['gif', 'mp4', 'mov', 'avi', 'webm'].contains(extension)) return;
    final file = File(image.path);
    await ref.read(imageEditNotifierProvider.notifier).setImage(file);
  }

  Future<void> _saveImage(BuildContext context, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/delilah_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(response.bodyBytes);
      await Gal.putImage(tempFile.path);
      await tempFile.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery!'), backgroundColor: AppColors.deepEnterpriseGreen),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                GestureDetector(
                  onTap: () => _showFullscreen(context, editState.resultUrl!),
                  child: Container(
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
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        onPressed: () => _saveImage(context, editState.resultUrl!),
                        label: 'Save',
                        icon: Icons.save_alt,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: GlassButton(
                        onPressed: () => WallpaperEngine.applyFromUrl(editState.resultUrl!),
                        label: 'Wallpaper',
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
                _ImagePickerCard(
                  imageFile: editState.imageFile,
                  imageUrl: editState.imageUrl,
                  isUploading: editState.isUploading,
                  onPick: editState.isUploading || editState.isProcessing ? null : _pickImage,
                ),
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
                          onPressed: (editState.imageUrl != null && !editState.isUploading && !editState.isProcessing)
                              ? () {
                                  final prompt = _promptController.text.trim();
                                  if (prompt.isEmpty) return;
                                  notifier.editImage(prompt);
                                }
                              : null,
                          label: editState.isProcessing ? 'Processing...' : 'Apply Edit',
                          icon: Icons.auto_fix_high,
                        ),
                      ),
                      if (editState.error != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(editState.error!, style: TextStyle(color: AppColors.errorRed)),
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
                      Container(
                        color: Colors.black54,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
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