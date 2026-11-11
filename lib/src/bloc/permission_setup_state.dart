part of 'permission_setup_bloc.dart';

enum PermissionSetupStatus {
  /// Reading the current statuses.
  loading,

  /// Waiting for the user.
  ready,

  /// A system dialog is open.
  requesting,

  /// All required items satisfied and user pressed continue (or auto-complete).
  completed,

  /// User skipped.
  skipped,
}

class PermissionSetupState extends Equatable {
  const PermissionSetupState({
    this.status = PermissionSetupStatus.loading,
    this.entries = const [],
    this.openedSettings = false,
  });

  final PermissionSetupStatus status;
  final List<PermissionEntry> entries;

  /// True after we sent the user to Settings (used to refresh on return).
  final bool openedSettings;

  bool get isLoading => status == PermissionSetupStatus.loading;
  bool get isBusy => status == PermissionSetupStatus.requesting;
  bool get isEmpty => !isLoading && entries.isEmpty;

  int get total => entries.length;
  int get grantedCount => entries.where((e) => e.isSatisfied).length;
  double get progress => total == 0 ? 1 : grantedCount / total;

  List<PermissionEntry> get pending =>
      entries.where((e) => !e.isSatisfied).toList();
  List<PermissionEntry> get requiredEntries =>
      entries.where((e) => e.item.isRequired).toList();

  /// Every required permission is satisfied -> "Continue" can be enabled.
  bool get canContinue =>
      !isLoading && requiredEntries.every((e) => e.isSatisfied);
  bool get allGranted => !isLoading && entries.every((e) => e.isSatisfied);

  /// Required items that can never be fixed from inside the app.
  List<PermissionEntry> get blockedRequired => requiredEntries
      .where((e) => e.grant == PermissionGrant.restricted)
      .toList();

  PermissionEntry? entryOf(PermissionKind kind) {
    for (final e in entries) {
      if (e.item.kind == kind) return e;
    }
    return null;
  }

  /// Dependencies (e.g. background location needs location) not yet satisfied.
  bool isLocked(PermissionEntry entry) {
    for (final dep in entry.item.kind.dependsOn) {
      final d = entryOf(dep);
      if (d != null && !d.isSatisfied) return true;
    }
    return false;
  }

  PermissionSetupState copyWith({
    PermissionSetupStatus? status,
    List<PermissionEntry>? entries,
    bool? openedSettings,
  }) => PermissionSetupState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    openedSettings: openedSettings ?? this.openedSettings,
  );

  @override
  List<Object?> get props => [status, entries, openedSettings];
}
