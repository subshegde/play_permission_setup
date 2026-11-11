import '../bloc/permission_setup_bloc.dart';
import '../core/permission_kind.dart';

/// Everything a custom UI can do, without knowing about events.
class PermissionSetupActions {
  const PermissionSetupActions(this.bloc);
  final PermissionSetupBloc bloc;

  void request(PermissionKind kind) => bloc.add(PermissionRequested(kind));
  void requestAll() => bloc.add(const PermissionAllRequested());
  void openSettings() => bloc.add(const PermissionSettingsOpened());
  void refresh() => bloc.add(const PermissionSetupRefreshed());
  void skip() => bloc.add(const PermissionSetupSkipped());
  void finish() => bloc.add(const PermissionSetupContinued());
}
