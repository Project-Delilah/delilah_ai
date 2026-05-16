import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/theme_controller.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> asyncValue;
  final Widget Function(T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const AsyncValueWidget({
    super.key,
    required this.asyncValue,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return asyncValue.when(
      data: builder,
      loading: () => loadingWidget ?? _defaultLoading(),
      error: (error, _) => errorWidget ?? _defaultError(error),
    );
  }

  Widget _defaultLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.softStone,
      highlightColor: AppColors.canvasWhite,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.softStone,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  Widget _defaultError(Object error) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed, size: 48),
          const SizedBox(height: AppSpacing.sm),
          Text('Error: ${error.toString()}', style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}