import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text('History', style: AppTextStyles.headlineLarge),
            ),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.softStone,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined, color: AppColors.mutedSlate, size: 48),
                      const SizedBox(height: AppSpacing.sm),
                      Text('No history yet', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text('Your generated images will appear here', style: AppTextStyles.bodySmall),
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