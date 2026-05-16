import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass_input.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/utils/wallpaper_engine.dart';
import '../providers/product_makeover_provider.dart';

class ProductMakeoverScreen extends ConsumerStatefulWidget {
  const ProductMakeoverScreen({super.key});

  @override
  ConsumerState<ProductMakeoverScreen> createState() => _ProductMakeoverScreenState();
}

class _ProductMakeoverScreenState extends ConsumerState<ProductMakeoverScreen> {
  final _contextController = TextEditingController(text: 'Place this product neatly on a premium, minimalist glass tabletop with soft cinematic light.');

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (image == null) return;
    final extension = image.path.split('.').last.toLowerCase();
    if (['gif', 'mp4', 'mov', 'avi', 'webm'].contains(extension)) return;
    final file = File(image.path);
    await ref.read(productMakeoverNotifierProvider.notifier).setImage(file);
  }

  Future<void> _saveImage(BuildContext context, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final tempFile = await File('/tmp/delilah_${DateTime.now().millisecondsSinceEpoch}.jpg').writeAsBytes(response.bodyBytes);
      await Gal.putImage(tempFile.path);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to gallery!'), backgroundColor: AppColors.deepEnterpriseGreen));
    } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'))); }
  }

  void _showFullscreen(BuildContext context, String url) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(backgroundColor: Colors.black, body: Stack(children: [Center(child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain)), Positioned(top: MediaQuery.of(context).padding.top + 8, left: 8, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)))]))));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productMakeoverNotifierProvider);
    final notifier = ref.read(productMakeoverNotifierProvider.notifier);

    return Scaffold(backgroundColor: AppColors.canvasWhite, body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Product Makeover', style: AppTextStyles.headlineLarge),
      const SizedBox(height: AppSpacing.lg),
      if (state.resultUrl != null) ...[
        GestureDetector(onTap: () => _showFullscreen(context, state.resultUrl!), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)), clipBehavior: Clip.antiAlias, child: CachedNetworkImage(imageUrl: state.resultUrl!, fit: BoxFit.cover, width: double.infinity))),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          Expanded(child: GlassButton(onPressed: () => _saveImage(context, state.resultUrl!), label: 'Save', icon: Icons.save_alt)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: GlassButton(onPressed: () => WallpaperEngine.applyFromUrl(state.resultUrl!), label: 'Wallpaper', icon: Icons.wallpaper)),
          const SizedBox(width: AppSpacing.sm),
          GlassButton(onPressed: () => notifier.reset(), label: 'New', icon: Icons.add, isPrimary: false),
        ]),
      ] else ...[
        _ImagePickerCard(imageFile: state.imageFile, imageUrl: state.imageUrl, isUploading: state.isUploading, onPick: state.isUploading || state.isProcessing ? null : _pickImage),
        const SizedBox(height: AppSpacing.lg),
        Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: AppColors.softStone, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Background Context', style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          GlassInput(controller: _contextController, hint: 'Place this product on...', icon: Icons.landscape),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(width: double.infinity, child: GlassButton(onPressed: (state.imageUrl != null && !state.isUploading && !state.isProcessing) ? () => notifier.makeover(_contextController.text.trim()) : null, label: state.isProcessing ? 'Processing...' : 'Apply Makeover', icon: Icons.store)),
          if (state.error != null) ...[const SizedBox(height: AppSpacing.md), Text(state.error!, style: TextStyle(color: AppColors.errorRed))],
        ])),
      ],
    ]))));
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
    return GestureDetector(onTap: onPick, child: Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: AppColors.softStone, borderRadius: BorderRadius.circular(AppRadius.lg), border: Border.all(color: AppColors.hairline)),
      child: imageUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: Stack(fit: StackFit.expand, children: [CachedNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover), if (isUploading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator()))])) : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 48, color: AppColors.mutedSlate), const SizedBox(height: AppSpacing.sm), Text('Tap to select image', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mutedSlate))])));
  }
}