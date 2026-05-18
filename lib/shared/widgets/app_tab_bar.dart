import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

class AppTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> tabs;
  final bool showBorder;

  const AppTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: showBorder ? Border.all(color: AppColors.hairline) : null,
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: controller,
        labelColor: AppColors.cohereBlack,
        unselectedLabelColor: AppColors.mutedSlate,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        labelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.cohereBlack,
        ),
        unselectedLabelStyle: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w400,
          color: AppColors.mutedSlate,
        ),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

class AppTabs extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softStone,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.canvasWhite : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppColors.cohereBlack : AppColors.mutedSlate,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}