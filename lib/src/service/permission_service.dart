import '../core/permission_kind.dart';
import '../models/permission_grant.dart';

class PermissionCheck {
  const PermissionCheck(this.grant, {this.serviceEnabled = true});
  final PermissionGrant grant;

  /// `false` when e.g. GPS is switched off although permission is granted.
  final bool serviceEnabled;
}

/// Abstraction over the platform so you can plug in your own implementation
/// (or a fake in tests).
abstract class PermissionService {
  Future<PermissionCheck> check(PermissionKind kind);
  Future<PermissionCheck> request(PermissionKind kind);

  /// Opens the OS settings page of this app. Returns false if it failed.
  Future<bool> openSettings();
}
