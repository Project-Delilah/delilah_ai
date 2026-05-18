import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:better_player_plus/better_player_plus.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/history_provider.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.softStone,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: TabBar(
                      controller: _tabController,
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
                  ),
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

class _GalleryGrid extends ConsumerWidget {
  final List<GalleryImage> images;
  final MediaType? filter;

  const _GalleryGrid({required this.images, this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtered = filter == null ? images : images.where((i) => i.type == filter).toList();

    if (filtered.isEmpty) {
      return Center(
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
              Icon(
                filter == MediaType.video ? Icons.videocam_outlined : Icons.photo_library_outlined, 
                color: AppColors.mutedSlate, 
                size: 64,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                filter == MediaType.video ? 'No videos yet' : 
                filter == MediaType.image ? 'No images yet' : 'Gallery is empty',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                filter == null ? 'Generate images or videos to see them here' :
                filter == MediaType.video ? 'Create videos to see them here' : 'Generate or try on images to see them here',
                style: AppTextStyles.bodySmall, 
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return CustomScrollView(
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
                final item = filtered[index];
                return _GalleryTile(item: item);
              },
              childCount: filtered.length,
            ),
          ),
        ),
      ],
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
            if (item.isImage)
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
              )
            else
              Stack(
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
                  Container(color: AppColors.cohereBlack.withValues(alpha: 0.3)),
                  const Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: AppColors.canvasWhite,
                      size: 48,
                    ),
                  ),
                ],
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
            if (item.isVideo)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.cohereBlack.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: AppColors.canvasWhite, size: 12),
                      SizedBox(width: 2),
                      Text('VIDEO', style: TextStyle(color: AppColors.canvasWhite, fontSize: 9, fontWeight: FontWeight.w600)),
                    ],
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
      builder: (ctx) => _MediaDetailSheet(item: item, ref: ref),
    );
  }
}

class _MediaDetailSheet extends StatefulWidget {
  final GalleryImage item;
  final WidgetRef ref;

  const _MediaDetailSheet({required this.item, required this.ref});

  @override
  State<_MediaDetailSheet> createState() => _MediaDetailSheetState();
}

class _MediaDetailSheetState extends State<_MediaDetailSheet> {
  late final WidgetRef _ref;
  BetterPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _ref = widget.ref;
    if (widget.item.isVideo) {
      _initVideo();
    }
  }

  void _initVideo() {
    _videoController = BetterPlayerController(
      const BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
      ),
      betterPlayerDataSource: BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        widget.item.url,
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

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
                  if (widget.item.prompt != null) ...[
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
                          Row(
                            children: [
                              Icon(
                                widget.item.isVideo ? Icons.videocam : Icons.auto_awesome,
                                size: 16,
                                color: AppColors.mutedSlate,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                widget.item.isVideo ? 'Video Prompt' : 'Prompt',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(widget.item.prompt!, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: SizedBox(
                      width: double.infinity,
                      height: widget.item.isVideo ? 250 : null,
                      child: widget.item.isVideo
                          ? _videoController != null
                              ? BetterPlayer(controller: _videoController!)
                              : const Center(child: CircularProgressIndicator())
                          : CachedNetworkImage(
                              imageUrl: widget.item.url,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          onPressed: () async {
                            try {
                              final isVideo = widget.item.isVideo;
                              final response = await http.get(Uri.parse(widget.item.url));
                              final tempDir = await getTemporaryDirectory();
                              final ext = isVideo ? 'mp4' : 'jpg';
                              final tempFile = File('${tempDir.path}/delilah_${DateTime.now().millisecondsSinceEpoch}.$ext');
                              await tempFile.writeAsBytes(response.bodyBytes);
                              
                              if (isVideo) {
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
                          },
                          label: 'Save',
                          icon: Icons.save_alt,
                          isPrimary: false,
                        ),
                      ),
                      if (!widget.item.isVideo) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: GlassButton(
                            onPressed: () async {
                              final success = await WallpaperEngine.applyFromUrl(widget.item.url);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success ? 'Wallpaper set!' : 'Failed to set wallpaper'),
                                    backgroundColor: success ? AppColors.deepEnterpriseGreen : AppColors.errorRed,
                                  ),
                                );
                              }
                            },
                            label: 'Wallpaper',
                            icon: Icons.wallpaper,
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      GlassButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text('Delete ${widget.item.isVideo ? 'Video' : 'Image'}'),
                              content: Text('Are you sure you want to delete this ${widget.item.isVideo ? 'video' : 'image'}?'),
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
                          if (confirm == true && widget.item.publicId != null) {
                            final success = await _ref.read(galleryNotifierProvider.notifier).deleteImage(widget.item.publicId!);
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
    );
  }
}