/// Normalised result of checking/requesting one permission.
enum PermissionGrant {
  /// Fully granted.
  granted,

  /// Partially granted (iOS "Selected photos", Android partial media access).
  limited,

  /// iOS provisional notifications – delivered quietly, counts as OK.
  provisional,

  /// Not granted yet; can still be asked.
  denied,

  /// User chose "don't ask again" – only system settings can change it.
  permanentlyDenied,

  /// Blocked by the OS / parental controls / MDM. Settings can't fix it.
  restricted,

  /// Not needed or not supported on this platform / OS version.
  notApplicable,

  /// Not checked yet.
  unknown;

  /// Counts as "done" for the setup flow.
  bool get isSatisfied =>
      this == granted ||
      this == limited ||
      this == provisional ||
      this == notApplicable;

  bool get isFullyGranted => this == granted || this == notApplicable;

  /// Only the system settings screen can change this now.
  bool get needsSettings => this == permanentlyDenied;
}
