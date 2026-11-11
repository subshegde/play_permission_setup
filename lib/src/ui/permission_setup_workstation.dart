import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import 'permission_setup_hero.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// Full-width application bar of the workstation layout: logo, name, status
/// chip, navigation, theme toggle, Skip and an avatar.
class PermissionSetupTopBar extends StatelessWidget {
  const PermissionSetupTopBar({
    super.key,
    this.brand,
    this.style = const PermissionSetupStyle(),
    this.strings = const PermissionSetupStrings(),
    this.onToggleTheme,
    this.onSkip,
  });

  final PermissionSetupBrand? brand;
  final PermissionSetupStyle style;
  final PermissionSetupStrings strings;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final b = brand;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cyan = s.info(context);

    Widget circle(
      Widget child, {
      Color? color,
      VoidCallback? onTap,
      String? tip,
    }) => Tooltip(
      message: tip ?? '',
      child: Material(
        color: color ?? s.surfaceAlt(context),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 36, height: 36, child: Center(child: child)),
        ),
      ),
    );

    return Material(
      color: s.background(context).withValues(alpha: 0.92),
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: s.border(context))),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: LayoutBuilder(
              builder: (context, box) {
                final bigText = MediaQuery.textScalerOf(context).scale(14) > 18;
                final showNav =
                    !bigText &&
                    box.maxWidth >= 900 &&
                    (b?.navItems.isNotEmpty ?? false);
                final showChip =
                    !bigText && box.maxWidth >= 1100 && b?.chip != null;
                final narrow = box.maxWidth < 480;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: narrow ? 12 : 32),
                  child: Row(
                    children: [
                      b?.logo ??
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: cyan,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: cyan.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Icon(
                              b?.logoIcon ?? Icons.monitor_heart_outlined,
                              size: 20,
                              color: s.background(context),
                            ),
                          ),
                      if (b?.appName != null) ...[
                        const SizedBox(width: 8),
                        () {
                          final name = Text(
                            b!.appName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: s.type(
                              context,
                              size: 20,
                              weight: FontWeight.w600,
                              heading: true,
                            ),
                          );
                          return Flexible(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: name,
                            ),
                          );
                        }(),
                      ],
                      if (showChip) ...[
                        const SizedBox(width: 16),
                        Container(
                          width: 1,
                          height: 16,
                          color: s.border(context),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: s.surfaceAlt(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: s.granted(context),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: s.granted(context),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                b!.chip!.toUpperCase(),
                                style: s.type(
                                  context,
                                  size: 11,
                                  weight: FontWeight.w700,
                                  heading: true,
                                  color: s.textSecondary(context),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (!showNav) const Spacer(),
                      if (showNav)
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                children: [
                                  for (var i = 0; i < b!.navItems.length; i++)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: b.onNavSelected == null
                                            ? null
                                            : () => b.onNavSelected!(i),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            b.navItems[i],
                                            style: s.type(
                                              context,
                                              size: 14,
                                              weight: i == b.activeNavIndex
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: i == b.activeNavIndex
                                                  ? cyan
                                                  : s.textSecondary(context),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (onToggleTheme != null)
                        circle(
                          Icon(
                            dark
                                ? Icons.wb_sunny_outlined
                                : Icons.dark_mode_outlined,
                            size: 18,
                            color: s.textSecondary(context),
                          ),
                          onTap: onToggleTheme,
                          tip: dark ? 'Light mode' : 'Dark mode',
                        ),
                      if (onSkip != null) ...[
                        const SizedBox(width: 12),
                        Material(
                          color: s.surfaceAlt(context),
                          shape: const StadiumBorder(),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: onSkip,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!narrow) ...[
                                    Text(
                                      strings.skip,
                                      style: s.type(
                                        context,
                                        size: 14,
                                        weight: FontWeight.w600,
                                        color: s.textSecondary(context),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Icon(
                                    Icons.skip_next_rounded,
                                    size: 16,
                                    color: s.textSecondary(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (!narrow && (b?.avatar != null || b != null)) ...[
                        const SizedBox(width: 12),
                        b?.avatar ??
                            circle(
                              Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: s.background(context),
                              ),
                              color: cyan,
                            ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim monospace status strip. Use it for a banner under the top bar or as a
/// footer, e.g. `PermissionSetupMetaBar(leading: 'RUNTIME ENGINE', trailing: 'SESSION #42')`.
class PermissionSetupMetaBar extends StatelessWidget {
  const PermissionSetupMetaBar({
    super.key,
    this.style = const PermissionSetupStyle(),
    this.leading,
    this.middle,
    this.trailing,
    this.trailingChip,
    this.dotColor,
  });

  final PermissionSetupStyle style;

  /// Text next to the coloured dot.
  final String? leading;

  /// Text after a bullet.
  final String? middle;

  /// Text on the right, and an optional highlighted chip after it.
  final String? trailing;
  final String? trailingChip;

  /// Colour of the dot (defaults to the accent colour).
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    TextStyle mono(Color c) => s.type(
      context,
      size: 11,
      weight: FontWeight.w700,
      heading: true,
      color: c,
      letterSpacing: 0.9,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: s.card(context).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(s.cardRadius * 0.6),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            children: [
              if (leading != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor ?? s.accent(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      leading!.toUpperCase(),
                      style: mono(dotColor ?? s.accent(context)),
                    ),
                  ],
                ),
              if (leading != null && middle != null)
                Text('•', style: mono(s.border(context))),
              if (middle != null)
                Text(
                  middle!.toUpperCase(),
                  style: mono(s.textSecondary(context)),
                ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null)
                Flexible(
                  child: Text(
                    trailing!.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: mono(s.textMuted(context)),
                  ),
                ),
              if (trailingChip != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: s.surfaceAlt(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      trailingChip!.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: mono(s.granted(context)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Framed illustration for the workstation layout: grid backdrop, pulse rings,
/// a handheld with a shield and three orbiting badges.
class PermissionSetupPanelIllustration extends StatelessWidget {
  const PermissionSetupPanelIllustration({
    super.key,
    this.style = const PermissionSetupStyle(),
    this.height = 224,
    this.badgeIcons = const [
      Icons.photo_camera_outlined,
      Icons.notifications_active_outlined,
      Icons.lock_outline_rounded,
    ],
  });

  final PermissionSetupStyle style;
  final double height;

  /// Three badge icons: top-right, left, bottom-right.
  final List<IconData> badgeIcons;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final accent = s.accent(context);

    Widget badge(IconData i, Color c) => Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: s.surfaceAlt(context),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8)],
      ),
      child: Icon(i, size: 18, color: c),
    );

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(s.cardRadius * 0.75),
        child: Container(
          height: height,
          width: double.infinity,
          color: s.inset(context),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(
                    s.border(context).withValues(alpha: 0.6),
                  ),
                ),
              ),
              SizedBox(
                width: 176,
                height: 176,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 176,
                      height: 176,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 144,
                      height: 144,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 104,
                      height: 150,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: s.surfaceAlt(context),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: Color(0x66000000), blurRadius: 20),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 32,
                            height: 5,
                            margin: const EdgeInsets.only(top: 3, bottom: 4),
                            decoration: BoxDecoration(
                              color: s.border(context),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: s.background(context),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withValues(alpha: 0.5),
                                          blurRadius: 18,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.verified_user_outlined,
                                      size: 22,
                                      color: s.onAccent(context),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: 48,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: s.surfaceAlt(context),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 30,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: s
                                          .surfaceAlt(context)
                                          .withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (badgeIcons.isNotEmpty)
                      Positioned(
                        top: 6,
                        right: -12,
                        child: badge(badgeIcons[0], s.info(context)),
                      ),
                    if (badgeIcons.length > 1)
                      Positioned(
                        left: -16,
                        top: 70,
                        child: badge(badgeIcons[1], accent),
                      ),
                    if (badgeIcons.length > 2)
                      Positioned(
                        bottom: 10,
                        right: -4,
                        child: badge(badgeIcons[2], s.granted(context)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 0.75;
    for (var x = 0.0; x <= size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y <= size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

/// The big left panel of the workstation layout: badge, headline, subtitle,
/// illustration, progress card, optional note and keyboard hints.
class PermissionSetupWorkstationPanel extends StatelessWidget {
  const PermissionSetupWorkstationPanel({
    super.key,
    required this.state,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.illustration,
  });

  final PermissionSetupState state;
  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;

  /// Replaces the framed illustration.
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);

    TextSpan titleSpan() {
      final base =
          s.titleStyle ??
          s.type(
            context,
            size: 36,
            weight: FontWeight.w700,
            heading: true,
            height: 1.2,
            letterSpacing: -0.7,
          );
      final h = strings.titleHighlight;
      final i = h == null ? -1 : strings.title.indexOf(h);
      if (h == null || i < 0 || s.titleGradient == null) {
        return TextSpan(text: strings.title, style: base);
      }
      final prefix = TextPainter(
        text: TextSpan(text: strings.title.substring(0, i), style: base),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final word = TextPainter(
        text: TextSpan(text: h, style: base),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final shaderRect = Rect.fromLTWH(
        prefix.width,
        0,
        word.width,
        word.height,
      );
      return TextSpan(
        style: base,
        children: [
          TextSpan(text: strings.title.substring(0, i)),
          TextSpan(
            text: h,
            style: TextStyle(
              foreground: Paint()
                ..shader = s.titleGradient!.createShader(shaderRect),
            ),
          ),
          TextSpan(text: strings.title.substring(i + h.length)),
        ],
      );
    }

    Widget kbd(String key, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: s.surfaceAlt(context),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            key,
            style: s.type(
              context,
              size: 11,
              weight: FontWeight.w700,
              heading: true,
              color: s.text(context),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: s.type(
              context,
              size: 11,
              weight: FontWeight.w700,
              heading: true,
              color: s.textMuted(context),
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: s.card(context),
        borderRadius: BorderRadius.circular(s.cardRadius),
        boxShadow: s.cardShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (strings.heroBadge != null || strings.stepLabel != null)
            Row(
              children: [
                if (strings.heroBadge != null)
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: s.accentSoft(context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.health_and_safety_outlined,
                              size: 16,
                              color: s.accent(context),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                strings.heroBadge!,
                                overflow: TextOverflow.ellipsis,
                                style: s.type(
                                  context,
                                  size: 11,
                                  weight: FontWeight.w700,
                                  heading: true,
                                  color: s.accent(context),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (strings.heroBadge == null) const Spacer(),
                if (strings.stepLabel != null)
                  Flexible(
                    child: Text(
                      strings.stepLabel!,
                      overflow: TextOverflow.ellipsis,
                      style: s.type(
                        context,
                        size: 11,
                        weight: FontWeight.w700,
                        heading: true,
                        color: s.textMuted(context),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text.rich(titleSpan())),
          const SizedBox(height: 10),
          Text(
            strings.subtitle,
            style:
                s.subtitleStyle ??
                s.type(
                  context,
                  size: 15,
                  color: s.textSecondary(context),
                  height: 1.6,
                ),
          ),
          if (s.showIllustration) ...[
            const SizedBox(height: 20),
            illustration ?? PermissionSetupPanelIllustration(style: style),
          ],
          if (s.showProgress && state.total > 0) ...[
            const SizedBox(height: 20),
            PermissionProgressCard(
              state: state,
              strings: strings,
              style: style,
            ),
          ],
          if (strings.noteBody != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: s.inset(context),
                borderRadius: BorderRadius.circular(s.cardRadius * 0.75),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.grantedSoft(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.privacy_tip_outlined,
                      size: 18,
                      color: s.granted(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (strings.noteTitle != null)
                          Text(
                            strings.noteTitle!,
                            style: s.type(
                              context,
                              size: 14,
                              weight: FontWeight.w600,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          strings.noteBody!,
                          style: s.type(
                            context,
                            size: 13,
                            color: s.textSecondary(context),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (s.showKeyboardHints) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: s.inset(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 6,
                children: [
                  kbd('Tab', strings.hintNavigate),
                  kbd('Space', strings.hintAllow),
                  kbd('Enter', strings.hintContinue),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Header card above the list: title, "N REQUIRED" and "N OPTIONAL" counters,
/// caption and the "Grant all" pill.
class PermissionWorkstationSectionHeader extends StatelessWidget {
  const PermissionWorkstationSectionHeader({
    super.key,
    required this.state,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.onAllowAll,
  });

  final PermissionSetupState state;
  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;
  final VoidCallback? onAllowAll;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final req = state.requiredEntries.length;
    final opt = state.total - req;

    Widget chip(String t, Color fg, Color bg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        t,
        style: s.type(
          context,
          size: 10,
          weight: FontWeight.w700,
          heading: true,
          color: fg,
          letterSpacing: 0.6,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(
        color: s.card(context),
        borderRadius: BorderRadius.circular(s.cardRadius * 0.75),
        boxShadow: s.cardShadows,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final narrow =
              box.maxWidth < 460 ||
              MediaQuery.textScalerOf(context).scale(14) > 18;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      strings.sectionTitle.toUpperCase(),
                      style: s.type(
                        context,
                        size: 20,
                        weight: FontWeight.w700,
                        heading: true,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  if (req > 0)
                    chip(
                      strings.requiredCount(req),
                      s.info(context),
                      s.infoSoft(context),
                    ),
                  if (opt > 0)
                    chip(
                      strings.optionalCount(opt),
                      s.textMuted(context),
                      s.surfaceAlt(context),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                strings.sectionSubtitle,
                style: s.type(
                  context,
                  size: 13,
                  color: s.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          );
          final pill = onAllowAll == null
              ? null
              : Material(
                  color: s.accentSoft(context),
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: onAllowAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.done_all_rounded,
                            size: 18,
                            color: s.accent(context),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              strings.allowAll,
                              overflow: TextOverflow.ellipsis,
                              style: s.type(
                                context,
                                size: 14,
                                weight: FontWeight.w600,
                                color: s.accent(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
          if (narrow || pill == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                text,
                if (pill != null) ...[const SizedBox(height: 12), pill],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: text),
              const SizedBox(width: 16),
              pill,
            ],
          );
        },
      ),
    );
  }
}
