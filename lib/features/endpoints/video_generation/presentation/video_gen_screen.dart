import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/video_player_widget.dart';
import '../data/video_gen_repository.dart';
import '../providers/video_gen_provider.dart';

enum VideoAspectRatio { ratio16x9, ratio9x16 }

class VideoGenScreen extends ConsumerStatefulWidget {
  const VideoGenScreen({super.key});

  @override
  ConsumerState<VideoGenScreen> createState() => _VideoGenScreenState();
}

class _VideoGenScreenState extends ConsumerState<VideoGenScreen> with SingleTickerProviderStateMixin {
  final _promptController = TextEditingController();
  late TabController _tabController;
  VideoAspectRatio _aspectRatio = VideoAspectRatio.ratio9x16;
  Resolution _resolution = Resolution.res720p;
  int _durationSeconds = 8;
  bool _useImage = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _useImage = _tabController.index == 1;
      });
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoGenNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: state.resultUrl != null
            ? _buildResultScreen(state)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Video Generation', style: AppTextStyles.headlineLarge),
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.softStone,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppColors.cohereBlack,
                        unselectedLabelColor: AppColors.mutedSlate,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Text to Video'),
                          Tab(text: 'Image to Video'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildOptions(),
                    const SizedBox(height: AppSpacing.lg),
                    GlassInput(
                      controller: _promptController,
                      hint: _useImage 
                          ? 'Describe the motion and action...'
                          : 'A person walking through a futuristic city...',
                      icon: Icons.edit_note,
                    ),
                    if (_useImage) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildImagePicker(state),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _buildDurationSelector(),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        onPressed: _canGenerate(state) ? () => _generate(state) : null,
                        label: state.isGenerating ? state.statusMessage ?? 'Generating...' : 'Generate Video',
                        icon: Icons.play_arrow,
                      ),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          state.error!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.errorRed),
                        ),
                      ),
                    ],
                    if (state.isGenerating) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _buildProgressIndicator(state),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aspect Ratio', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _OptionChip(
              label: '9:16 (Portrait)',
              isSelected: _aspectRatio == VideoAspectRatio.ratio9x16,
              onTap: () => setState(() => _aspectRatio = VideoAspectRatio.ratio9x16),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OptionChip(
              label: '16:9 (Landscape)',
              isSelected: _aspectRatio == VideoAspectRatio.ratio16x9,
              onTap: () => setState(() => _aspectRatio = VideoAspectRatio.ratio16x9),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Quality', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _OptionChip(
              label: '720p',
              isSelected: _resolution == Resolution.res720p,
              onTap: () => setState(() => _resolution = Resolution.res720p),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OptionChip(
              label: '1080p',
              isSelected: _resolution == Resolution.res1080p,
              onTap: () => setState(() => _resolution = Resolution.res1080p),
            ),
            const SizedBox(width: AppSpacing.sm),
            _OptionChip(
              label: '4K',
              isSelected: _resolution == Resolution.res4k,
              onTap: () => setState(() => _resolution = Resolution.res4k),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Duration: ${_durationSeconds}s', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Slider(
          value: _durationSeconds.toDouble(),
          min: 4,
          max: 8,
          divisions: 1,
          label: '${_durationSeconds}s',
          activeColor: AppColors.cohereBlack,
          inactiveColor: AppColors.hairline,
          onChanged: (value) => setState(() => _durationSeconds = value.round()),
        ),
      ],
    );
  }

  Widget _buildImagePicker(VideoGenState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reference Image', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (state.selectedImage != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: state.selectedImageUrl != null
                      ? Image.network(
                          state.selectedImageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          state.selectedImage!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => ref.read(videoGenNotifierProvider.notifier).clearImage(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.cohereBlack.withAlpha(179),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: AppColors.canvasWhite, size: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.canvasWhite,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Icon(Icons.image, color: AppColors.mutedSlate, size: 40),
            ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              onPressed: state.isUploading ? null : _pickImage,
              label: state.isUploading 
                  ? 'Uploading...' 
                  : (state.selectedImageUrl != null ? 'Image Ready' : 'Pick Image'),
              icon: Icons.photo_library,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    
    if (image == null) return;
    
    final extension = image.path.split('.').last.toLowerCase();
    if (['gif', 'mp4', 'mov', 'avi', 'webm'].contains(extension)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image file')),
        );
      }
      return;
    }

    await ref.read(videoGenNotifierProvider.notifier).setImage(File(image.path));
  }

  Widget _buildProgressIndicator(VideoGenState state) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(height: AppSpacing.md),
          Text(
            state.statusMessage ?? 'Processing...',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  bool _canGenerate(VideoGenState state) {
    if (state.isGenerating || state.isUploading) return false;
    if (_promptController.text.trim().isEmpty) return false;
    if (_useImage && state.selectedImageUrl == null) return false;
    return true;
  }

  VeoAspectRatio _getVeoAspectRatio() {
    return _aspectRatio == VideoAspectRatio.ratio16x9 ? VeoAspectRatio.ratio16x9 : VeoAspectRatio.ratio9x16;
  }

  void _generate(VideoGenState state) {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    if (_useImage) {
      ref.read(videoGenNotifierProvider.notifier).generateImageToVideo(
        prompt: prompt,
        aspectRatio: _getVeoAspectRatio(),
        resolution: _resolution,
        durationSeconds: _durationSeconds,
      );
    } else {
      ref.read(videoGenNotifierProvider.notifier).generateTextToVideo(
        prompt: prompt,
        aspectRatio: _getVeoAspectRatio(),
        resolution: _resolution,
        durationSeconds: _durationSeconds,
      );
    }
  }

  Widget _buildResultScreen(VideoGenState state) {
    final isPortrait = _aspectRatio == VideoAspectRatio.ratio9x16;
    
    return Scaffold(
      backgroundColor: AppColors.cohereBlack,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => ref.read(videoGenNotifierProvider.notifier).reset(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.canvasWhite),
                  ),
                  Text(
                    'Generated Video',
                    style: AppTextStyles.titleMedium.copyWith(color: AppColors.canvasWhite),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  height: isPortrait 
                      ? MediaQuery.of(context).size.height * 0.65 
                      : MediaQuery.of(context).size.height * 0.5,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: VideoPlayerWidget(
                      videoUrl: state.resultUrl!,
                      autoPlay: true,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      onPressed: () async {
                        try {
                          await Gal.putVideo(state.resultUrl!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Video saved to gallery!'),
                                backgroundColor: AppColors.deepEnterpriseGreen,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save: $e'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        }
                      },
                      label: 'Save to Device',
                      icon: Icons.save_alt,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      onPressed: () => ref.read(videoGenNotifierProvider.notifier).reset(),
                      label: 'Generate Another',
                      icon: Icons.refresh,
                      isPrimary: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cohereBlack : AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isSelected ? AppColors.cohereBlack : AppColors.hairline),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isSelected ? AppColors.canvasWhite : AppColors.cohereBlack,
          ),
        ),
      ),
    );
  }
}