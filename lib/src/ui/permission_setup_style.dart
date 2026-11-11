import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/permission_kind.dart';
import '../models/platform.dart';

/// Size class of the space the page is given (not the device!), so the page
/// also adapts when embedded in a dialog, side panel or split view.
enum PermissionSetupLayout { compact, medium, expanded }

/// How the permission rows are drawn.
enum PermissionTileVariant {
  /// Rows share one rounded container separated by hairlines (system-settings
  /// look). The default.
  grouped,

  /// Every permission is its own bordered, rounded card with a status pill.
  cards,

  /// Borderless, roomy panels for desktop workstations: coloured icon circle,
  /// inline status next to the action, "Allow ->" button, tonal Settings.
  panels,
}

/// How the top of the page is drawn.
enum PermissionHeaderVariant {
  /// Title, one-line subtitle and a slim progress bar.
  compact,

  /// Illustration, large title and subtitle, and a progress card. On wide
  /// windows this block sits left of the list (see
  /// [PermissionSetupStyle.splitWhenExpanded]).
  hero,

  /// Desktop workstation: one big left panel (badge, headline, framed
  /// illustration, progress card, privacy note, keyboard hints) and a header
  /// card with counters above the list.
  workstation,
}

/// Visual knobs of the default UI. Every colour falls back to the app theme,
/// so a plain `PermissionSetupStyle()` follows your `ThemeData`.
///
/// Ready-made looks: [PermissionSetupStyle.crimson] (red, light + dark) and
/// [PermissionSetupStyle.clinical] (deep-navy / teal). Start from one and tweak
/// it with [copyWith]:
///
/// ```dart
/// style: PermissionSetupStyle.crimson.copyWith(accentColor: Colors.indigo)
/// ```
///
/// [dark] is used instead of this style when the app theme is dark.
class PermissionSetupStyle {
  const PermissionSetupStyle({
    // ── colours ────────────────────────────────────────────────────────────
    this.backgroundColor,
    this.cardColor,
    this.surfaceAltColor,
    this.insetColor,
    this.borderColor,
    this.accentColor,
    this.onAccentColor,
    this.accentGradient,
    this.progressGradient,
    this.titleGradient,
    this.accentSoftColor,
    this.grantedColor,
    this.grantedSoftColor,
    this.warningColor,
    this.warningSoftColor,
    this.errorColor,
    this.errorSoftColor,
    this.infoColor,
    this.infoSoftColor,
    this.textColor,
    this.secondaryTextColor,
    this.mutedTextColor,
    // ── shape & depth ──────────────────────────────────────────────────────
    this.cardRadius = 16,
    this.buttonRadius = 999,
    this.primaryButtonRadius,
    this.iconRadius = 12,
    this.cardShadows = const [],
    this.glowButtons = false,
    this.tileGap = 12,
    this.spacing = 16,
    // ── layout ─────────────────────────────────────────────────────────────
    this.maxContentWidth = 1000,
    this.singleColumnMaxWidth = 640,
    this.minColumnWidth = 420,
    this.maxColumns = 2,
    this.compactBreakpoint = 600,
    this.expandedBreakpoint = 1000,
    this.splitWhenExpanded = false,
    this.pinFooterOnWide = false,
    // ── variants & switches ────────────────────────────────────────────────
    this.tileVariant = PermissionTileVariant.grouped,
    this.headerVariant = PermissionHeaderVariant.compact,
    this.showProgress = true,
    this.showIllustration = true,
    this.showSectionHeader = false,
    this.allowAllInSection = false,
    this.continueIcon,
    this.showKeyboardHints = false,
    this.enableKeyboardShortcuts = false,
    // ── typography ─────────────────────────────────────────────────────────
    this.fontFamily,
    this.headingFontFamily,
    this.titleStyle,
    this.subtitleStyle,
    this.tileTitleStyle,
    this.tileDescriptionStyle,
    // ── dark variant ───────────────────────────────────────────────────────
    this.dark,
  });

  // ── colours ──────────────────────────────────────────────────────────────

  /// Page background.
  final Color? backgroundColor;

  /// Permission rows / cards.
  final Color? cardColor;

  /// Slightly raised surface, e.g. the progress card.
  final Color? surfaceAltColor;

  /// Recessed surface: illustration panel, note box, progress track.
  final Color? insetColor;

  /// Hairline borders of cards and dividers.
  final Color? borderColor;

  /// Brand colour: Allow button, progress bar, icons.
  final Color? accentColor;

  /// Text / icons drawn on top of [accentColor] (e.g. the button label).
  final Color? onAccentColor;

  /// Optional gradient for primary buttons and the progress bar; overrides
  /// [accentColor] there.
  final Gradient? accentGradient;

  /// Gradient of the progress bar; defaults to [accentGradient].
  final Gradient? progressGradient;

  /// Gradient painted on the highlighted word of the headline
  /// (`PermissionSetupStrings.titleHighlight`).
  final Gradient? titleGradient;

  /// Tinted background behind the row icon; defaults to a faint [accentColor].
  final Color? accentSoftColor;

  final Color? grantedColor;
  final Color? grantedSoftColor;
  final Color? warningColor;
  final Color? warningSoftColor;
  final Color? errorColor;
  final Color? errorSoftColor;

  /// "Limited access" accent.
  final Color? infoColor;
  final Color? infoSoftColor;

  /// Main text (titles).
  final Color? textColor;

  /// Descriptions and captions.
  final Color? secondaryTextColor;

  /// Placeholders and de-emphasised hints.
  final Color? mutedTextColor;

  // ── shape & depth ────────────────────────────────────────────────────────

  /// Corner radius of cards and groups.
  final double cardRadius;

  /// Corner radius of buttons, pills and chips (999 = fully round).
  final double buttonRadius;

  /// Corner radius of the big bottom Continue button; defaults to [buttonRadius].
  final double? primaryButtonRadius;

  /// Corner radius of the icon tile in each row.
  final double iconRadius;

  /// Shadows under cards ([PermissionTileVariant.cards]).
  final List<BoxShadow> cardShadows;

  /// Soft coloured glow under the primary button.
  final bool glowButtons;

  /// Space between cards ([PermissionTileVariant.cards]).
  final double tileGap;
  final double spacing;

  // ── layout ───────────────────────────────────────────────────────────────

  /// Widest the content gets when it is laid out in several columns.
  final double maxContentWidth;

  /// Widest the content gets when there is only one column (keeps rows readable).
  final double singleColumnMaxWidth;

  /// Smallest width of one column; more columns appear only when they fit.
  final double minColumnWidth;

  /// Upper limit for the number of columns.
  final int maxColumns;

  /// Width below which the compact layout is used.
  final double compactBreakpoint;

  /// Width from which the expanded (desktop) layout is used.
  final double expandedBreakpoint;

  /// [PermissionHeaderVariant.hero] only: on the expanded layout put the hero
  /// and progress left and the list right (otherwise everything stacks).
  final bool splitWhenExpanded;

  /// Keep the action bar pinned to the bottom on wide windows too (it is always
  /// pinned on phones).
  final bool pinFooterOnWide;

  // ── variants & switches ──────────────────────────────────────────────────
  final PermissionTileVariant tileVariant;
  final PermissionHeaderVariant headerVariant;
  final bool showProgress;

  /// Hero header: draw the illustration.
  final bool showIllustration;

  /// Show a "Permissions · Allow all" heading above the list.
  final bool showSectionHeader;

  /// Put "Allow all" in the section heading instead of the bottom bar, leaving
  /// the bar with a single Continue button.
  final bool allowAllInSection;

  /// Icon after the Continue label (e.g. `Icons.arrow_forward_rounded`).
  final IconData? continueIcon;

  /// Desktop: show a "Tab · Space · Enter" hint strip.
  final bool showKeyboardHints;

  /// Desktop: pressing Enter (while nothing else is focused) taps Continue.
  final bool enableKeyboardShortcuts;

  // ── typography ───────────────────────────────────────────────────────────

  /// Font for body text. Register it in your app's pubspec (or use
  /// google_fonts) – an unknown family silently falls back.
  final String? fontFamily;

  /// Font for titles and numbers; defaults to [fontFamily].
  final String? headingFontFamily;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final TextStyle? tileTitleStyle;
  final TextStyle? tileDescriptionStyle;

  // ── dark variant ─────────────────────────────────────────────────────────

  /// Replaces this style while the app theme is dark.
  final PermissionSetupStyle? dark;

  // ═══════════════════════════════════════════════════════════════════════════

  PermissionSetupLayout layoutFor(double width) {
    if (width < compactBreakpoint) return PermissionSetupLayout.compact;
    if (width < expandedBreakpoint) return PermissionSetupLayout.medium;
    return PermissionSetupLayout.expanded;
  }

  /// Card-like rows (`cards` or `panels`).
  bool get isCards => tileVariant != PermissionTileVariant.grouped;
  bool get isPanels => tileVariant == PermissionTileVariant.panels;

  /// Any header that is not the plain compact one.
  bool get isHero => headerVariant != PermissionHeaderVariant.compact;
  bool get isWorkstation =>
      headerVariant == PermissionHeaderVariant.workstation;

  /// True on Windows, macOS and Linux (not web).
  static bool get isDesktopOs {
    if (kIsWeb) return false;
    final p = currentPermissionPlatform();
    return p == PermissionPlatform.windows ||
        p == PermissionPlatform.macos ||
        p == PermissionPlatform.linux;
  }

  /// Picks [desktop] on desktop operating systems (and on wide web windows),
  /// otherwise [base].
  static PermissionSetupStyle select(
    BuildContext context,
    PermissionSetupStyle base,
    PermissionSetupStyle? desktop,
  ) {
    if (desktop == null) return base;
    final wideWeb =
        kIsWeb &&
        MediaQuery.sizeOf(context).width >= desktop.expandedBreakpoint;
    return (isDesktopOs || wideWeb) ? desktop : base;
  }

  /// The style to actually draw with: [dark] under a dark theme, else `this`.
  PermissionSetupStyle resolved(BuildContext c) =>
      (dark != null && Theme.of(c).brightness == Brightness.dark)
      ? dark!
      : this;

  // ── colour accessors (explicit value, else derived from ThemeData) ───────

  ColorScheme _s(BuildContext c) => Theme.of(c).colorScheme;
  bool _isDark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

  Color background(BuildContext c) => backgroundColor ?? _s(c).surface;
  Color card(BuildContext c) => cardColor ?? _s(c).surfaceContainerLow;
  Color surfaceAlt(BuildContext c) =>
      surfaceAltColor ?? _s(c).surfaceContainerHighest.withValues(alpha: 0.5);
  Color inset(BuildContext c) =>
      insetColor ?? _s(c).surfaceContainerHighest.withValues(alpha: 0.35);
  Color border(BuildContext c) => borderColor ?? _s(c).outlineVariant;
  Color accent(BuildContext c) => accentColor ?? _s(c).primary;
  Color onAccent(BuildContext c) => onAccentColor ?? _s(c).onPrimary;
  Color accentSoft(BuildContext c) =>
      accentSoftColor ?? accent(c).withValues(alpha: 0.10);
  Color granted(BuildContext c) =>
      grantedColor ??
      (_isDark(c) ? const Color(0xFF66D19E) : const Color(0xFF1B7F4B));
  Color grantedSoft(BuildContext c) =>
      grantedSoftColor ?? granted(c).withValues(alpha: 0.14);
  Color warning(BuildContext c) =>
      warningColor ??
      (_isDark(c) ? const Color(0xFFFFC266) : const Color(0xFF9A5B00));
  Color warningSoft(BuildContext c) =>
      warningSoftColor ?? warning(c).withValues(alpha: 0.14);
  Color error(BuildContext c) => errorColor ?? _s(c).error;
  Color errorSoft(BuildContext c) =>
      errorSoftColor ?? error(c).withValues(alpha: 0.12);
  Color info(BuildContext c) =>
      infoColor ??
      (_isDark(c) ? const Color(0xFF64B5F6) : const Color(0xFF1E88E5));
  Color infoSoft(BuildContext c) =>
      infoSoftColor ?? info(c).withValues(alpha: 0.12);
  Color text(BuildContext c) => textColor ?? _s(c).onSurface;
  Color textSecondary(BuildContext c) =>
      secondaryTextColor ?? _s(c).onSurfaceVariant;
  Color textMuted(BuildContext c) =>
      mutedTextColor ?? _s(c).onSurfaceVariant.withValues(alpha: 0.7);

  /// Fill for primary buttons / progress: [accentGradient] or flat accent.
  BoxDecoration accentFill(BuildContext c, {double? radius}) => BoxDecoration(
    color: accentGradient == null ? accent(c) : null,
    gradient: accentGradient,
    borderRadius: BorderRadius.circular(radius ?? buttonRadius),
  );

  /// Soft glow under the primary button (empty unless [glowButtons]).
  List<BoxShadow> glow(BuildContext c) => glowButtons
      ? [
          BoxShadow(
            color: accent(c).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ]
      : const [];

  /// A [TextStyle] with this style's fonts and colour applied.
  TextStyle type(
    BuildContext c, {
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    bool heading = false,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color ?? text(c),
    height: height,
    letterSpacing: letterSpacing,
    fontFamily: heading ? (headingFontFamily ?? fontFamily) : fontFamily,
  );

  PermissionSetupStyle copyWith({
    Color? backgroundColor,
    Color? cardColor,
    Color? surfaceAltColor,
    Color? insetColor,
    Color? borderColor,
    Color? accentColor,
    Color? onAccentColor,
    Gradient? accentGradient,
    Gradient? progressGradient,
    Gradient? titleGradient,
    Color? accentSoftColor,
    Color? grantedColor,
    Color? grantedSoftColor,
    Color? warningColor,
    Color? warningSoftColor,
    Color? errorColor,
    Color? errorSoftColor,
    Color? infoColor,
    Color? infoSoftColor,
    Color? textColor,
    Color? secondaryTextColor,
    Color? mutedTextColor,
    double? cardRadius,
    double? buttonRadius,
    double? primaryButtonRadius,
    double? iconRadius,
    List<BoxShadow>? cardShadows,
    bool? glowButtons,
    double? tileGap,
    double? spacing,
    double? maxContentWidth,
    double? singleColumnMaxWidth,
    double? minColumnWidth,
    int? maxColumns,
    double? compactBreakpoint,
    double? expandedBreakpoint,
    bool? splitWhenExpanded,
    bool? pinFooterOnWide,
    PermissionTileVariant? tileVariant,
    PermissionHeaderVariant? headerVariant,
    bool? showProgress,
    bool? showIllustration,
    bool? showSectionHeader,
    bool? allowAllInSection,
    IconData? continueIcon,
    bool? showKeyboardHints,
    bool? enableKeyboardShortcuts,
    String? fontFamily,
    String? headingFontFamily,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    TextStyle? tileTitleStyle,
    TextStyle? tileDescriptionStyle,
    PermissionSetupStyle? dark,

    /// Drops the [dark] variant, so this style is used in dark mode too.
    bool removeDark = false,
  }) => PermissionSetupStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    cardColor: cardColor ?? this.cardColor,
    surfaceAltColor: surfaceAltColor ?? this.surfaceAltColor,
    insetColor: insetColor ?? this.insetColor,
    borderColor: borderColor ?? this.borderColor,
    accentColor: accentColor ?? this.accentColor,
    onAccentColor: onAccentColor ?? this.onAccentColor,
    accentGradient: accentGradient ?? this.accentGradient,
    progressGradient: progressGradient ?? this.progressGradient,
    titleGradient: titleGradient ?? this.titleGradient,
    accentSoftColor: accentSoftColor ?? this.accentSoftColor,
    grantedColor: grantedColor ?? this.grantedColor,
    grantedSoftColor: grantedSoftColor ?? this.grantedSoftColor,
    warningColor: warningColor ?? this.warningColor,
    warningSoftColor: warningSoftColor ?? this.warningSoftColor,
    errorColor: errorColor ?? this.errorColor,
    errorSoftColor: errorSoftColor ?? this.errorSoftColor,
    infoColor: infoColor ?? this.infoColor,
    infoSoftColor: infoSoftColor ?? this.infoSoftColor,
    textColor: textColor ?? this.textColor,
    secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
    mutedTextColor: mutedTextColor ?? this.mutedTextColor,
    cardRadius: cardRadius ?? this.cardRadius,
    buttonRadius: buttonRadius ?? this.buttonRadius,
    primaryButtonRadius: primaryButtonRadius ?? this.primaryButtonRadius,
    iconRadius: iconRadius ?? this.iconRadius,
    cardShadows: cardShadows ?? this.cardShadows,
    glowButtons: glowButtons ?? this.glowButtons,
    tileGap: tileGap ?? this.tileGap,
    spacing: spacing ?? this.spacing,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    singleColumnMaxWidth: singleColumnMaxWidth ?? this.singleColumnMaxWidth,
    minColumnWidth: minColumnWidth ?? this.minColumnWidth,
    maxColumns: maxColumns ?? this.maxColumns,
    compactBreakpoint: compactBreakpoint ?? this.compactBreakpoint,
    expandedBreakpoint: expandedBreakpoint ?? this.expandedBreakpoint,
    splitWhenExpanded: splitWhenExpanded ?? this.splitWhenExpanded,
    pinFooterOnWide: pinFooterOnWide ?? this.pinFooterOnWide,
    tileVariant: tileVariant ?? this.tileVariant,
    headerVariant: headerVariant ?? this.headerVariant,
    showProgress: showProgress ?? this.showProgress,
    showIllustration: showIllustration ?? this.showIllustration,
    showSectionHeader: showSectionHeader ?? this.showSectionHeader,
    allowAllInSection: allowAllInSection ?? this.allowAllInSection,
    continueIcon: continueIcon ?? this.continueIcon,
    showKeyboardHints: showKeyboardHints ?? this.showKeyboardHints,
    enableKeyboardShortcuts:
        enableKeyboardShortcuts ?? this.enableKeyboardShortcuts,
    fontFamily: fontFamily ?? this.fontFamily,
    headingFontFamily: headingFontFamily ?? this.headingFontFamily,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    tileTitleStyle: tileTitleStyle ?? this.tileTitleStyle,
    tileDescriptionStyle: tileDescriptionStyle ?? this.tileDescriptionStyle,
    dark: removeDark ? null : (dark ?? this.dark),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // Presets
  // ═══════════════════════════════════════════════════════════════════════════

  /// Clean red onboarding look: hero illustration, progress card,
  /// one card per permission, status pills and a glowing Continue button.
  /// Includes a matching dark variant.
  static const PermissionSetupStyle crimson = PermissionSetupStyle(
    backgroundColor: Color(0xFFFFFFFF),
    cardColor: Color(0xFFFFFFFF),
    surfaceAltColor: Color(0xFFF8F9FA),
    borderColor: Color(0xFFEEEEEE),
    accentColor: Color(0xFFE53935),
    onAccentColor: Color(0xFFFFFFFF),
    accentSoftColor: Color(0xFFFFEBEE),
    grantedColor: Color(0xFF2EAD70),
    grantedSoftColor: Color(0xFFE8F5E9),
    warningColor: Color(0xFFE6A23C),
    warningSoftColor: Color(0xFFFFF8E1),
    errorColor: Color(0xFFD94343),
    errorSoftColor: Color(0xFFFFEBEE),
    infoColor: Color(0xFF1E88E5),
    infoSoftColor: Color(0xFFE3F2FD),
    textColor: Color(0xFF202124),
    secondaryTextColor: Color(0xFF757575),
    mutedTextColor: Color(0xFF9E9E9E),
    cardRadius: 16,
    iconRadius: 16,
    primaryButtonRadius: 16,
    cardShadows: [
      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
    ],
    glowButtons: true,
    tileGap: 12,
    singleColumnMaxWidth: 560,
    splitWhenExpanded: true,
    expandedBreakpoint: 720, // tablets get the desktop layout
    pinFooterOnWide: true,
    maxContentWidth: 960,
    tileVariant: PermissionTileVariant.cards,
    headerVariant: PermissionHeaderVariant.hero,
    showSectionHeader: true,
    allowAllInSection: true,
    continueIcon: Icons.arrow_forward_rounded,
    fontFamily: 'Inter',
    dark: PermissionSetupStyle(
      backgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      surfaceAltColor: Color(0xFF1E1E1E),
      borderColor: Color(0xFF2C2C2C),
      accentColor: Color(0xFFE53935),
      onAccentColor: Color(0xFFFFFFFF),
      accentSoftColor: Color(0x33E53935),
      grantedColor: Color(0xFF4CC38A),
      grantedSoftColor: Color(0x294CC38A),
      warningColor: Color(0xFFFFB74D),
      warningSoftColor: Color(0x29FFB74D),
      errorColor: Color(0xFFEF5350),
      errorSoftColor: Color(0x29EF5350),
      infoColor: Color(0xFF64B5F6),
      infoSoftColor: Color(0x2964B5F6),
      textColor: Color(0xFFFFFFFF),
      secondaryTextColor: Color(0xFFB0B0B0),
      mutedTextColor: Color(0xFF8A8A8A),
      cardRadius: 16,
      iconRadius: 16,
      primaryButtonRadius: 16,
      glowButtons: true,
      tileGap: 12,
      singleColumnMaxWidth: 560,
      splitWhenExpanded: true,
      expandedBreakpoint: 720, // tablets get the desktop layout
      pinFooterOnWide: true,
      maxContentWidth: 960,
      tileVariant: PermissionTileVariant.cards,
      headerVariant: PermissionHeaderVariant.hero,
      showSectionHeader: true,
      allowAllInSection: true,
      continueIcon: Icons.arrow_forward_rounded,
      fontFamily: 'Inter',
    ),
  );

  /// Deep-navy "clinical luminance" look: midnight surfaces, teal gradient
  /// actions, generous 24px corners, pill buttons. Dark by design (also used
  /// when the app theme is light). Fonts: Space Grotesk headings, Plus Jakarta
  /// Sans body – register them in your app or they fall back to the default.
  static const PermissionSetupStyle clinical = PermissionSetupStyle(
    backgroundColor: Color(0xFF090F1D),
    cardColor: Color(0xFF132238),
    surfaceAltColor: Color(0xFF0F172A),
    borderColor: Color(0x1F94A3B8),
    accentColor: Color(0xFF06B6D4),
    onAccentColor: Color(0xFF090F1D),
    accentGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF06B6D4), Color(0xFF14B8A6)],
    ),
    accentSoftColor: Color(0x1F06B6D4),
    grantedColor: Color(0xFF10B981),
    grantedSoftColor: Color(0x1F10B981),
    warningColor: Color(0xFFF59E0B),
    warningSoftColor: Color(0x1FF59E0B),
    errorColor: Color(0xFFF43F5E),
    errorSoftColor: Color(0x1FF43F5E),
    infoColor: Color(0xFF2DD4BF),
    infoSoftColor: Color(0x1F2DD4BF),
    textColor: Color(0xFFF8FAFC),
    secondaryTextColor: Color(0xFF94A3B8),
    mutedTextColor: Color(0xFF475569),
    cardRadius: 24,
    iconRadius: 18,
    cardShadows: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 32,
        spreadRadius: -4,
        offset: Offset(0, 8),
      ),
      BoxShadow(color: Color(0x1F06B6D4), blurRadius: 16, spreadRadius: -2),
    ],
    glowButtons: true,
    tileGap: 16,
    singleColumnMaxWidth: 560,
    splitWhenExpanded: true,
    expandedBreakpoint: 720, // tablets get the desktop layout
    pinFooterOnWide: true,
    maxContentWidth: 960,
    tileVariant: PermissionTileVariant.cards,
    headerVariant: PermissionHeaderVariant.hero,
    showSectionHeader: true,
    allowAllInSection: true,
    continueIcon: Icons.arrow_forward_rounded,
    fontFamily: 'Plus Jakarta Sans',
    headingFontFamily: 'Space Grotesk',
  );

  /// Desktop workstation look (Windows, macOS, Linux, wide web): midnight
  /// surfaces, salmon actions, mint "Allowed" pills, a big left panel and
  /// roomy panel rows. Dark by design. Pair it with a phone style:
  ///
  /// ```dart
  /// PermissionSetupPage(
  ///   style: PermissionSetupStyle.crimson,            // phones and tablets
  ///   desktopStyle: PermissionSetupStyle.workstation, // desktop OS and web
  /// )
  /// ```
  static const PermissionSetupStyle workstation = PermissionSetupStyle(
    backgroundColor: Color(0xFF0D1321),
    cardColor: Color(0xFF1A1F2E),
    surfaceAltColor: Color(0xFF242A39),
    insetColor: Color(0xFF151B2A),
    borderColor: Color(0x403D494C),
    accentColor: Color(0xFFFFB4AB),
    onAccentColor: Color(0xFF690005),
    accentSoftColor: Color(0x26FFB4AB),
    progressGradient: LinearGradient(
      colors: [Color(0xFFFFB4AB), Color(0xFFE53935), Color(0xFF04B4A2)],
    ),
    titleGradient: LinearGradient(
      colors: [Color(0xFFFFB4AB), Color(0xFF4FDBC8), Color(0xFF4CD7F6)],
    ),
    grantedColor: Color(0xFF4FDBC8),
    grantedSoftColor: Color(0x264FDBC8),
    warningColor: Color(0xFFFFB4AB),
    warningSoftColor: Color(0x26FFB4AB),
    errorColor: Color(0xFFFFB4AB),
    errorSoftColor: Color(0x26FFB4AB),
    infoColor: Color(0xFF4CD7F6),
    infoSoftColor: Color(0x1A4CD7F6),
    textColor: Color(0xFFDDE2F6),
    secondaryTextColor: Color(0xFFBCC9CD),
    mutedTextColor: Color(0xFF869397),
    cardRadius: 32,
    iconRadius: 16,
    cardShadows: [
      BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 1)),
    ],
    glowButtons: true,
    tileGap: 8,
    maxContentWidth: 1280,
    expandedBreakpoint: 900,
    splitWhenExpanded: true,
    tileVariant: PermissionTileVariant.panels,
    headerVariant: PermissionHeaderVariant.workstation,
    showSectionHeader: true,
    allowAllInSection: true,
    showKeyboardHints: true,
    enableKeyboardShortcuts: true,
    continueIcon: Icons.arrow_forward_rounded,
    fontFamily: 'Plus Jakarta Sans',
    headingFontFamily: 'Space Grotesk',
  );
}
