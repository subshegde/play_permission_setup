import '../core/permission_kind.dart';

enum IssueSeverity { error, warning, info }

class ScanIssue {
  const ScanIssue(
    this.severity,
    this.message, {
    this.platform,
    this.kind,
    this.file,
  });
  final IssueSeverity severity;
  final String message;
  final PermissionPlatform? platform;
  final PermissionKind? kind;
  final String? file;

  @override
  String toString() {
    final tag = switch (severity) {
      IssueSeverity.error => 'ERROR',
      IssueSeverity.warning => 'WARN ',
      IssueSeverity.info => 'INFO ',
    };
    final where = [?platform?.name, ?file].join(' · ');
    return '$tag ${where.isEmpty ? '' : '[$where] '}$message';
  }
}

class ScanResult {
  ScanResult({
    required this.declared,
    required this.issues,
    required this.scanned,
    required this.files,
  });

  /// Kind -> platforms where it is declared.
  final Map<PermissionKind, Set<PermissionPlatform>> declared;
  final List<ScanIssue> issues;

  /// Platforms whose project folder / config file was found.
  final Set<PermissionPlatform> scanned;
  final List<String> files;

  bool get hasErrors => issues.any((i) => i.severity == IssueSeverity.error);
  bool get hasWarnings =>
      issues.any((i) => i.severity == IssueSeverity.warning);
}
