import 'package:flutter/material.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/services/ota_update_service.dart';
import '../../shared/widgets/glass_button.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onLater;
  final VoidCallback? onUpdate;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onLater,
    this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.canvasWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.system_update_alt,
              size: 64,
              color: AppColors.actionBlue,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Update Available',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Version ${widget.updateInfo.version} is now available',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.updateInfo.sizeFormatted,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.mutedSlate),
            ),
            if (widget.updateInfo.releaseNotes != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                height: 100,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.softStone,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    widget.updateInfo.releaseNotes!,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppColors.hairline,
                valueColor: const AlwaysStoppedAnimation(AppColors.actionBlue),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${(_downloadProgress * 100).toInt()}%',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              children: [
                if (!widget.updateInfo.isForced)
                  Expanded(
                    child: GlassButton(
                      onPressed: _isDownloading ? null : widget.onLater,
                      label: 'Later',
                      isPrimary: false,
                    ),
                  ),
                if (!widget.updateInfo.isForced) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: GlassButton(
                    onPressed: _isDownloading ? null : _handleUpdate,
                    label: _isDownloading ? 'Downloading...' : 'Update',
                    icon: Icons.download,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isDownloading = true);

    final path = await otaUpdateService.downloadUpdate(
      widget.updateInfo,
      onProgress: (received, total) {
        if (total > 0) {
          setState(() => _downloadProgress = received / total);
        }
      },
    );

    if (path != null && mounted) {
      final success = await otaUpdateService.installUpdate(path);
      if (success && mounted) {
        Navigator.pop(context);
      }
    } else if (mounted) {
      setState(() => _isDownloading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download failed. Please try again.')),
      );
    }
  }
}

class UpdateBadge extends StatelessWidget {
  final VoidCallback onTap;

  const UpdateBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.actionBlue,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              'Update',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}