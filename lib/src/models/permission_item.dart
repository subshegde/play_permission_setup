import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../core/permission_kind.dart';

/// One row of the setup page. Everything except [kind] is optional – defaults
/// (title, description, icon) are provided by the default UI.
class PermissionItem extends Equatable {
  const PermissionItem({
    required this.kind,
    this.title,
    this.description,
    this.rationale,
    this.icon,
    this.isRequired = true,
    this.platforms,
  });

  final PermissionKind kind;

  /// Overrides the default title.
  final String? title;

  /// Why your app needs it. Overrides the default description.
  final String? description;

  /// Extra text shown after the user denied it ("Without it you can't ...").
  final String? rationale;

  final IconData? icon;

  /// Required items block "Continue" until satisfied.
  final bool isRequired;

  /// Platforms where this item applies. `null` = every platform the kind
  /// supports. The generated config sets this from your manifest/Info.plist so
  /// an item is never requested where it is not declared (which would crash on
  /// iOS).
  final Set<PermissionPlatform>? platforms;

  bool appliesTo(PermissionPlatform platform) =>
      platforms?.contains(platform) ?? kind.platforms.contains(platform);

  PermissionItem copyWith({
    String? title,
    String? description,
    String? rationale,
    IconData? icon,
    bool? isRequired,
    Set<PermissionPlatform>? platforms,
  }) => PermissionItem(
    kind: kind,
    title: title ?? this.title,
    description: description ?? this.description,
    rationale: rationale ?? this.rationale,
    icon: icon ?? this.icon,
    isRequired: isRequired ?? this.isRequired,
    platforms: platforms ?? this.platforms,
  );

  @override
  List<Object?> get props => [
    kind,
    title,
    description,
    rationale,
    icon,
    isRequired,
    platforms,
  ];
}
