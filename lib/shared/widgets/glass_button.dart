import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final bool isPrimary;

  const GlassButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isPrimary ? AppColors.canvasWhite : AppColors.cohereBlack;
    return Container(
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.cohereBlack : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: isPrimary ? null : Border.all(color: AppColors.cohereBlack, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: textColor, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.button.copyWith(color: textColor, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}