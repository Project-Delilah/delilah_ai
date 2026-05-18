import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/video_player_widget.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/history_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galleryState = ref.watch(galleryNotifierProvider);

    if (!_hasInitialized && galleryState.hasValue && galleryState.value!.isEmpty) {
      _hasInitialized = true;
      Future.microtask(() => ref.read(galleryNotifierProvider.notifier).fetchGallery());
    }

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
                  const SizedBox(height: AppSpacing.sm),
                  _TabBarWidget(tabController: _tabController),
                ],
              ),
            ),
            Expanded(
              child: galleryState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorWidget(
                  onRetry: () => ref.read(galleryNotifierProvider.notifier).fetchGallery(),
                ),
                data: (images) => TabBarView(
                  controller: _tabController,
                  children: [
                    _GalleryGrid(images: images, filter: null),
                    _GalleryGrid(images: images, filter: MediaType.image),
                    _GalleryGrid(images: images, filter: MediaType.video),
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

class _TabBarWidget extends StatelessWidget {
  final TabController tabController;

  const _TabBarWidget({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: TabBar(
        controller: tabController,
        labelColor: AppColors.cohereBlack,
        unselectedLabelColor: AppColors.mutedSlate,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Images'),
          Tab(text: 'Videos'),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
            const SizedBox(height: AppSpacing.md),
            Text('Failed to load gallery', style: AppTextStyles.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            GlassButton(
              onPressed: onRetry,
              label: 'Retry',
              icon: Icons.refresh,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final MediaType? filter;

  const _EmptyWidget({this.filter});

  @override
  Widget build(BuildContext context) {
    final isVideo = filter == MediaType.video;
    final isImage = filter == MediaType.image;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVideo ? Icons.videocam_outlined : Icons.photo_library_outlined,
              color: AppColors.mutedSlate,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isVideo ? 'No videos yet' : isImage ? 'No images yet' : 'Gallery is empty',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              isVideo
                  ? 'Create videos to see them here'
                  : isImage
                      ? 'Generate or try on images to see them here'
                      : 'Generate images or videos to see them here',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  final List<GalleryImage> images;
  final MediaType? filter;

  const _GalleryGrid({required this.images, this.filter});

  @override
  Widget build(BuildContext context) {
    final filtered = filter == null ? images : images.where((i) => i.type == filter).toList();

    if (filtered.isEmpty) {
      return _EmptyWidget(filter: filter);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
        childAspectRatio: 0.6,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _GalleryTile(item: item);
      },
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
      child: AspectRatio(
        aspectRatio: item.isVideo ? item.aspectRatio.value : 1.0,
        child: _MediaCard(item: item),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MediaDetailSheet(item: item, ref: ref),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final GalleryImage item;

  const _MediaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.isVideo)
            VideoThumbnail(
              videoUrl: item.url,
              aspectRatio: item.aspectRatio,
            )
          else
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
    );
  }
}

class _MediaDetailSheet extends ConsumerStatefulWidget {
  final GalleryImage item;
  final WidgetRef ref;

  const _MediaDetailSheet({required this.item, required this.ref});

  @override
  ConsumerState<_MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends ConsumerState<_MediaDetailSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.canvasWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _SheetHandle(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.item.prompt != null) ...[
                    _PromptCard(item: widget.item),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (widget.item.isVideo)
                    VideoPlayerWidget(
                      videoUrl: widget.item.url,
                      autoPlay: true,
                      aspectRatio: widget.item.aspectRatio,
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: CachedNetworkImage(
                        imageUrl: widget.item.url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  _ActionButtons(item: widget.item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final GalleryImage item;

  const _PromptCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.isVideo ? Icons.videocam : Icons.auto_awesome,
                size: 16,
                color: AppColors.mutedSlate,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item.isVideo ? 'Video Prompt' : 'Prompt',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.prompt!, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  final GalleryImage item;

  const _ActionButtons({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _SaveButton(item: item),
        ),
        if (!item.isVideo) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: _WallpaperButton(item: item)),
        ],
        const SizedBox(width: AppSpacing.sm),
        _DeleteButton(item: item),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  final GalleryImage item;

  const _SaveButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: () => _save(context),
      label: 'Save',
      icon: Icons.save_alt,
      isPrimary: false,
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(item.url));
      final tempDir = await getTemporaryDirectory();
      final ext = item.isVideo ? 'mp4' : 'jpg';
      final tempFile = File('${tempDir.path}/delilah_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await tempFile.writeAsBytes(response.bodyBytes);

      if (item.isVideo) {
        await Gal.putVideo(tempFile.path);
      } else {
        await Gal.putImage(tempFile.path);
      }
      await tempFile.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to gallery!'),
            backgroundColor: AppColors.deepEnterpriseGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }
}

class _WallpaperButton extends StatelessWidget {
  final GalleryImage item;

  const _WallpaperButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      onPressed: () => _setWallpaper(context),
      label: 'Wallpaper',
      icon: Icons.wallpaper,
    );
  }

  Future<void> _setWallpaper(BuildContext context) async {
    final success = await WallpaperEngine.applyFromUrl(item.url);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Wallpaper set!' : 'Failed to set wallpaper'),
          backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
        ),
      );
    }
  }
}

class _DeleteButton extends ConsumerWidget {
  final GalleryImage item;

  const _DeleteButton({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassButton(
      onPressed: () => _confirmDelete(context, ref),
      label: 'Delete',
      icon: Icons.delete_outline,
      isPrimary: false,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Delete ${item.isVideo ? 'Video' : 'Image'}'),
        content: Text('Are you sure you want to delete this ${item.isVideo ? 'video' : 'image'}?'),
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
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Deleted' : 'Failed to delete'),
            backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
          ),
        );
      }
    }
  }
}