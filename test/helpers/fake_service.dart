import 'package:play_permission_setup/play_permission_setup.dart';

/// Scriptable fake: each kind has a current grant and a queue of request
/// outcomes. Records every request.
class FakeService implements PermissionService {
  FakeService({Map<PermissionKind, PermissionGrant>? initial})
    : grants = {...?initial};

  final Map<PermissionKind, PermissionGrant> grants;
  final Map<PermissionKind, List<PermissionGrant>> outcomes = {};
  final List<PermissionKind> requested = [];
  final Set<PermissionKind> serviceOff = {};
  Object? throwOnCheck;
  Object? throwOnRequest;
  int settingsOpened = 0;
  bool settingsResult = true;
  Duration requestDelay = Duration.zero;

  @override
  Future<PermissionCheck> check(PermissionKind kind) async {
    if (throwOnCheck != null) throw throwOnCheck!;
    return PermissionCheck(
      grants[kind] ?? PermissionGrant.denied,
      serviceEnabled: !serviceOff.contains(kind),
    );
  }

  @override
  Future<PermissionCheck> request(PermissionKind kind) async {
    requested.add(kind);
    if (requestDelay > Duration.zero) await Future<void>.delayed(requestDelay);
    if (throwOnRequest != null) throw throwOnRequest!;
    final q = outcomes[kind];
    if (q != null && q.isNotEmpty) grants[kind] = q.removeAt(0);
    return PermissionCheck(
      grants[kind] ?? PermissionGrant.denied,
      serviceEnabled: !serviceOff.contains(kind),
    );
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return settingsResult;
  }
}
