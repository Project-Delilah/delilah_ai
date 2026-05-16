import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final _imageUrlController = TextEditingController();
  final _contextController = TextEditingController(text: 'Place this product neatly on a premium, minimalist glass tabletop with soft cinematic light.');

  @override
  void dispose() {
    _imageUrlController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productMakeoverNotifierProvider);
    final notifier = ref.read(productMakeoverNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product Makeover', style: AppTextStyles.headlineLarge),
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
                      Text('Product Image URL', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _imageUrlController, hint: 'https://...', icon: Icons.image),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Background Context', style: AppTextStyles.bodyLarge),
                      const SizedBox(height: AppSpacing.md),
                      GlassInput(controller: _contextController, hint: 'Place this product on...', icon: Icons.landscape),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          onPressed: state.isLoading ? null : () {
                            final url = _imageUrlController.text.trim();
                            final ctx = _contextController.text.trim();
                            if (url.isEmpty || ctx.isEmpty) return;
                            notifier.setProductImageUrl(url);
                            notifier.makeover(ctx);
                          },
                          label: state.isLoading ? 'Processing...' : 'Apply Makeover',
                          icon: Icons.store,
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