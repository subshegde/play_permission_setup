import 'package:equatable/equatable.dart';

import 'permission_grant.dart';
import 'permission_item.dart';

/// Runtime state of one [PermissionItem].
class PermissionEntry extends Equatable {
  const PermissionEntry({
    required this.item,
    this.grant = PermissionGrant.unknown,
    this.attempts = 0,
    this.serviceDisabled = false,
    this.isRequesting = false,
    this.error,
  });

  final PermissionItem item;
  final PermissionGrant grant;

  /// How many times we asked in this session.
  final int attempts;

  /// Permission is granted but the device service (GPS) is switched off.
  final bool serviceDisabled;
  final bool isRequesting;
  final String? error;

  bool get isSatisfied => grant.isSatisfied;
  bool get isChecked => grant != PermissionGrant.unknown;

  /// Android quirk: after 2 refusals the dialog stops appearing even though the
  /// plugin still reports `denied`, so we offer Settings as well.
  bool get shouldOpenSettings =>
      grant.needsSettings ||
      (grant == PermissionGrant.denied && attempts >= 2) ||
      (grant == PermissionGrant.limited) ||
      serviceDisabled;

  PermissionEntry copyWith({
    PermissionGrant? grant,
    int? attempts,
    bool? serviceDisabled,
    bool? isRequesting,
    String? error,
    bool clearError = false,
  }) => PermissionEntry(
    item: item,
    grant: grant ?? this.grant,
    attempts: attempts ?? this.attempts,
    serviceDisabled: serviceDisabled ?? this.serviceDisabled,
    isRequesting: isRequesting ?? this.isRequesting,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    item,
    grant,
    attempts,
    serviceDisabled,
    isRequesting,
    error,
  ];
}
