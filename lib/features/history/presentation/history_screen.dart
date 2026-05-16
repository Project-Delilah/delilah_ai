import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/history_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Gallery', style: AppTextStyles.headlineLarge),
                      IconButton(
                        onPressed: () => ref.read(galleryNotifierProvider.notifier).fetchGallery(),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Your generated images from Cloudinary', style: AppTextStyles.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: galleryState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
                      const SizedBox(height: AppSpacing.md),
                      Text('Failed to load gallery', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.md),
                      GlassButton(
                        onPressed: () => ref.read(galleryNotifierProvider.notifier).fetchGallery(),
                        label: 'Retry',
                        icon: Icons.refresh,
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
                data: (images) => images.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          margin: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.softStone,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, color: AppColors.mutedSlate, size: 64),
                              const SizedBox(height: AppSpacing.md),
                              Text('No images yet', style: AppTextStyles.titleMedium),
                              const SizedBox(height: AppSpacing.xs),
                              Text('Generate or try on images to see them here', style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(galleryNotifierProvider.notifier).fetchGallery(),
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: AppSpacing.sm,
                                  mainAxisSpacing: AppSpacing.sm,
                                  childAspectRatio: 0.75,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final item = images[index];
                                    return _GalleryTile(item: item);
                                  },
                                  childCount: images.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryTile extends ConsumerWidget {
  final GalleryImage item;

  const _GalleryTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDetailSheet(context, ref),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: AppColors.softStone,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.softStone,
                child: const Icon(Icons.error, color: AppColors.errorRed),
              ),
            ),
            if (item.prompt != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  color: AppColors.cohereBlack.withValues(alpha: 0.7),
                  child: Text(
                    item.prompt!,
                    style: const TextStyle(color: AppColors.canvasWhite, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.prompt != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.softStone,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Prompt', style: AppTextStyles.bodySmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text(item.prompt!, style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: CachedNetworkImage(
                        imageUrl: item.url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            onPressed: () async {
                              try {
                                final response = await http.get(Uri.parse(item.url));
                                final tempDir = await getTemporaryDirectory();
                                final tempFile = File('${tempDir.path}/delilah_${DateTime.now().millisecondsSinceEpoch}.jpg');
                                await tempFile.writeAsBytes(response.bodyBytes);
                                await Gal.putImage(tempFile.path);
                                await tempFile.delete();
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Saved to gallery!'),
                                      backgroundColor: AppColors.deepEnterpriseGreen,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('Save failed: $e')),
                                  );
                                }
                              }
                            },
                            label: 'Save',
                            icon: Icons.save_alt,
                            isPrimary: false,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GlassButton(
                            onPressed: () async {
                              final success = await WallpaperEngine.applyFromUrl(item.url);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Wallpaper set!' : 'Failed to set wallpaper'),
                                    backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
                                  ),
                                );
                              }
                            },
                            label: 'Set as Wallpaper',
                            icon: Icons.wallpaper,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        GlassButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: ctx,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Delete Image'),
                                content: const Text('Are you sure you want to delete this image?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx, true),
                                    child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && item.publicId != null) {
                              final success = await ref.read(galleryNotifierProvider.notifier).deleteImage(item.publicId!);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Image deleted' : 'Failed to delete'),
                                    backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          label: 'Delete',
                          icon: Icons.delete_outline,
                          isPrimary: false,
                        ),
                      ],
                    ),
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