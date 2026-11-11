import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/permission_kind.dart';
import '../service/permission_detector.dart';

/// State of a scan: still scanning, or finished with a [DetectionResult].
class PermissionDetectionState extends Equatable {
  const PermissionDetectionState.loading() : result = null;
  const PermissionDetectionState.ready(DetectionResult this.result);

  final DetectionResult? result;

  bool get isLoading => result == null;

  @override
  List<Object?> get props => [result];
}

/// Scans the running app once (and again on [rescan]) and publishes the
/// outcome. Closing it while a scan is running is safe.
class PermissionDetectionCubit extends Cubit<PermissionDetectionState> {
  PermissionDetectionCubit(this.config, {this.platform})
    : super(const PermissionDetectionState.loading()) {
    rescan();
  }

  /// How the list is built.
  final PermissionDetection config;

  /// Override the platform (tests).
  final PermissionPlatform? platform;

  /// Scans again; the state goes back to *loading* meanwhile.
  Future<void> rescan() async {
    if (!isClosed && !state.isLoading) {
      emit(const PermissionDetectionState.loading());
    }
    final result = await config.resolve(platform: platform);
    if (!isClosed) emit(PermissionDetectionState.ready(result));
  }
}
