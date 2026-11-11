part of 'permission_setup_bloc.dart';

sealed class PermissionSetupEvent extends Equatable {
  const PermissionSetupEvent();
  @override
  List<Object?> get props => [];
}

/// Check the current status of every item (also fired on app resume).
class PermissionSetupStarted extends PermissionSetupEvent {
  const PermissionSetupStarted();
}

class PermissionSetupRefreshed extends PermissionSetupEvent {
  const PermissionSetupRefreshed();
}

/// Ask for one permission.
class PermissionRequested extends PermissionSetupEvent {
  const PermissionRequested(this.kind);
  final PermissionKind kind;
  @override
  List<Object?> get props => [kind];
}

/// Ask for every permission that is not yet granted, one after another.
class PermissionAllRequested extends PermissionSetupEvent {
  const PermissionAllRequested();
}

class PermissionSettingsOpened extends PermissionSetupEvent {
  const PermissionSettingsOpened();
}

/// User leaves without finishing.
class PermissionSetupSkipped extends PermissionSetupEvent {
  const PermissionSetupSkipped();
}

/// User pressed "Continue".
class PermissionSetupContinued extends PermissionSetupEvent {
  const PermissionSetupContinued();
}
