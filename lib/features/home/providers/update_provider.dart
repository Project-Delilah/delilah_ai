import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ota_update_service.dart';

class UpdateState {
  final UpdateInfo? updateInfo;
  final bool isChecking;
  final bool hasChecked;

  const UpdateState({
    this.updateInfo,
    this.isChecking = false,
    this.hasChecked = false,
  });

  UpdateState copyWith({
    UpdateInfo? updateInfo,
    bool? isChecking,
    bool? hasChecked,
  }) {
    return UpdateState(
      updateInfo: updateInfo ?? this.updateInfo,
      isChecking: isChecking ?? this.isChecking,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }
}

class UpdateNotifier extends Notifier<UpdateState> {
  @override
  UpdateState build() => const UpdateState();

  Future<void> checkForUpdate() async {
    if (state.isChecking || state.hasChecked) return;

    state = state.copyWith(isChecking: true);

    final updateInfo = await otaUpdateService.checkForUpdate();

    state = UpdateState(
      updateInfo: updateInfo,
      isChecking: false,
      hasChecked: true,
    );
  }

  void clearUpdate() {
    state = state.copyWith(updateInfo: null, hasChecked: false);
  }
}

final updateNotifierProvider = NotifierProvider<UpdateNotifier, UpdateState>(() => UpdateNotifier());