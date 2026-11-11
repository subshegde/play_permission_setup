import '../models/permission_grant.dart';

/// Every user-visible string of the default UI. Pass a copy with your own
/// (localised) text; unspecified fields keep the English defaults.
class PermissionSetupStrings {
  const PermissionSetupStrings({
    this.title = 'Set up permissions',
    this.subtitle = 'Allow access so everything works as expected.',
    this.allowAll = 'Allow all',
    this.allow = 'Allow',
    this.openSettings = 'Settings',
    this.manage = 'Manage',
    this.retry = 'Retry',
    this.continueLabel = 'Continue',
    this.skip = 'Skip',
    this.requiredBadge = 'Required',
    this.optionalBadge = 'Optional',
    this.statusGranted = 'Allowed',
    this.statusLimited = 'Limited access',
    this.statusProvisional = 'Allowed quietly',
    this.statusDenied = 'Not allowed',
    this.statusPermanentlyDenied = 'Blocked',
    this.statusRestricted = 'Restricted',
    this.statusNotApplicable = 'Not needed',
    this.statusUnknown = 'Checking…',
    this.permanentlyDeniedHint = 'Turned off. Enable it in Settings.',
    this.deniedAgainHint = 'The prompt may not appear again. Try Settings.',
    this.restrictedHint = 'Restricted by device policy. Can’t be changed here.',
    this.limitedHint = 'Only selected items are shared.',
    this.serviceDisabledHint = 'Allowed, but the service is turned off.',
    this.errorHint = 'Couldn’t check this permission.',
    this.blockedRequiredHint =
        'Some required permissions are restricted on this device, so setup can’t be completed.',
    this.emptyTitle = 'Nothing to set up',
    this.emptyMessage = 'This device doesn’t need any extra permissions.',
    this.loading = 'Checking permissions…',
    this.requesting = 'Requesting…',
    this.requiredChip = 'REQ',
    this.optionalChip = 'OPTIONAL',
    this.progressLabel = 'Setup progress',
    this.progressBadge,
    this.sectionTitle = 'Required permissions',
    this.sectionSubtitle =
        'Review the permissions below to enable all supported features.',
    this.footerNote,
    this.titleHighlight,
    this.heroBadge,
    this.stepLabel,
    this.progressTag,
    this.progressStatus,
    this.noteTitle,
    this.noteBody,
    this.hintNavigate = 'Navigate',
    this.hintAllow = 'Allow',
    this.hintContinue = 'Continue',
    this.restrictedChip = 'Device policy restricted',
  });

  final String title;
  final String subtitle;
  final String allowAll;
  final String allow;
  final String openSettings;
  final String manage;
  final String retry;
  final String continueLabel;
  final String skip;
  final String requiredBadge;
  final String optionalBadge;
  final String statusGranted;
  final String statusLimited;
  final String statusProvisional;
  final String statusDenied;
  final String statusPermanentlyDenied;
  final String statusRestricted;
  final String statusNotApplicable;
  final String statusUnknown;
  final String permanentlyDeniedHint;
  final String deniedAgainHint;
  final String restrictedHint;
  final String limitedHint;
  final String serviceDisabledHint;
  final String errorHint;
  final String blockedRequiredHint;
  final String emptyTitle;
  final String emptyMessage;
  final String loading;

  /// Shown on a row while its system dialog is open.
  final String requesting;

  /// Short chip next to the title of a required / optional permission
  /// (card rows).
  final String requiredChip;
  final String optionalChip;

  /// Label above the progress bar (hero header).
  final String progressLabel;

  /// Small badge at the end of the progress card (e.g. "Secured"); hidden when
  /// null.
  final String? progressBadge;

  /// Heading above the list and its caption (when the style shows it).
  final String sectionTitle;
  final String sectionSubtitle;

  /// Small note under the Continue button, e.g. "You can change this anytime in
  /// Settings."; hidden when null.
  final String? footerNote;

  /// Workstation header: the part of [title] drawn with the style's
  /// `titleGradient`, e.g. title "Let's get things ready", highlight "ready".
  final String? titleHighlight;

  /// Workstation header: small badge on top of the left panel
  /// (e.g. "MyApp SETUP v1.0") and the step counter next to it ("STEP 1 / 2").
  final String? heroBadge;
  final String? stepLabel;

  /// Workstation progress card: small tag after "Setup progress" (e.g. "REQ")
  /// and a status line under the bar (e.g. "State: in progress"). Both hidden
  /// when null.
  final String? progressTag;
  final String? progressStatus;

  /// Workstation: info box under the progress card (e.g. a privacy promise).
  /// Hidden when [noteBody] is null.
  final String? noteTitle;
  final String? noteBody;

  /// Workstation keyboard hint strip ("Tab Navigate · Space Allow · Enter Continue").
  final String hintNavigate;
  final String hintAllow;
  final String hintContinue;

  /// Pill shown on a row that the device policy blocks.
  final String restrictedChip;

  String progress(int granted, int total) => '$granted of $total allowed';
  String requiredCount(int n) => '$n REQUIRED';
  String optionalCount(int n) => '$n OPTIONAL';
  String progressCompleted(int granted, int total) =>
      '$granted of $total completed';
  String percentCompleted(int percent) => '$percent% completed';
  String lockedHint(String dependency) => 'Allow “$dependency” first.';

  String statusLabel(PermissionGrant g) => switch (g) {
    PermissionGrant.granted => statusGranted,
    PermissionGrant.limited => statusLimited,
    PermissionGrant.provisional => statusProvisional,
    PermissionGrant.denied => statusDenied,
    PermissionGrant.permanentlyDenied => statusPermanentlyDenied,
    PermissionGrant.restricted => statusRestricted,
    PermissionGrant.notApplicable => statusNotApplicable,
    PermissionGrant.unknown => statusUnknown,
  };
}
