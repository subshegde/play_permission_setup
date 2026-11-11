import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// Branding shown in the top bar of the hero layout. Every part is optional.
class PermissionSetupBrand {
  const PermissionSetupBrand({
    this.appName,
    this.badge,
    this.caption,
    this.logo,
    this.logoIcon = Icons.verified_user_rounded,
    this.chip,
    this.navItems = const [],
    this.activeNavIndex = 0,
    this.onNavSelected,
    this.avatar,
  });

  /// Bold app name.
  final String? appName;

  /// Small pill next to the name, e.g. "Setup".
  final String? badge;

  /// Second line under the name.
  final String? caption;

  /// Replaces the default logo square (any widget, drawn at about 36 × 36).
  final Widget? logo;

  /// Icon inside the default logo square.
  final IconData logoIcon;

  /// Workstation top bar: small pill with a status dot after the name, e.g.
  /// "my_package v1.0".
  final String? chip;

  /// Workstation top bar: navigation labels shown on wide windows, the active
  /// one and a callback when one is tapped.
  final List<String> navItems;
  final int activeNavIndex;
  final ValueChanged<int>? onNavSelected;

  /// Workstation top bar: widget at the far right (e.g. your user avatar).
  final Widget? avatar;
}

/// Top bar: logo, name, badge, caption on the left; theme toggle and Skip on
/// the right.
class PermissionSetupBrandBar extends StatelessWidget {
  const PermissionSetupBrandBar({
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

  /// Shows a moon / sun button when set.
  final VoidCallback? onToggleTheme;

  /// Shows the Skip button when set.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final style = this.style.resolved(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final b = brand;

    Widget logo() =>
        b?.logo ??
        Container(
          width: 36,
          height: 36,
          decoration: style.accentFill(context, radius: 12),
          child: Icon(
            b?.logoIcon ?? Icons.verified_user_rounded,
            size: 20,
            color: style.onAccent(context),
          ),
        );

    final hasBrand =
        b != null && (b.appName != null || b.logo != null || b.caption != null);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: style.border(context).withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 10),
        child: Row(
          children: [
            if (hasBrand) ...[
              logo(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (b.appName != null)
                          Text(
                            b.appName!,
                            style: style.type(
                              context,
                              size: 16,
                              weight: FontWeight.w700,
                              heading: true,
                            ),
                          ),
                        if (b.badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: style.accentSoft(context),
                              borderRadius: BorderRadius.circular(
                                style.buttonRadius,
                              ),
                            ),
                            child: Text(
                              b.badge!.toUpperCase(),
                              style: style.type(
                                context,
                                size: 11,
                                weight: FontWeight.w700,
                                color: style.accent(context),
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (b.caption != null)
                      Text(
                        b.caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.type(
                          context,
                          size: 12,
                          color: style.textSecondary(context),
                        ),
                      ),
                  ],
                ),
              ),
            ] else
              const Spacer(),
            if (onToggleTheme != null)
              IconButton(
                tooltip: dark ? 'Light mode' : 'Dark mode',
                visualDensity: VisualDensity.compact,
                onPressed: onToggleTheme,
                icon: Icon(
                  dark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                  size: 20,
                  color: dark
                      ? const Color(0xFFFFCA28)
                      : style.textSecondary(context),
                ),
              ),
            if (onSkip != null)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(48, 40),
                  foregroundColor: style.textSecondary(context),
                  textStyle: style.type(
                    context,
                    size: 13,
                    weight: FontWeight.w600,
                  ),
                ),
                onPressed: onSkip,
                child: Text(strings.skip),
              ),
          ],
        ),
      ),
    );
  }
}

/// Phone-with-shield illustration drawn from the style colours, with two
/// floating permission badges. Replace it with any widget via
/// `PermissionSetupPage.illustration`.
class PermissionSetupIllustration extends StatelessWidget {
  const PermissionSetupIllustration({
    super.key,
    this.style = const PermissionSetupStyle(),
    this.height = 150,
    this.badgeIcons = const [
      Icons.photo_camera_outlined,
      Icons.notifications_none_rounded,
    ],
  });

  final PermissionSetupStyle style;

  /// Rendered height; the width follows the artwork's 10 : 9 ratio.
  final double height;

  /// Icons of the two floating badges (left, right).
  final List<IconData> badgeIcons;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final accent = s.accent(context);
    final line = s.border(context);
    final card = s.card(context);

    Widget badge(IconData icon, Color color) => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: line, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: 18, color: color),
    );

    Widget dot(double x, double y, double r, Color c) => Positioned(
      left: x - r,
      top: y - r,
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
    );

    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 200,
            height: 180,
            child: Stack(
              children: [
                // ambient glow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(alpha: 0.16),
                          accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                dot(30, 40, 4, accent.withValues(alpha: 0.3)),
                dot(170, 50, 5, s.granted(context).withValues(alpha: 0.4)),
                dot(160, 140, 3.5, accent.withValues(alpha: 0.25)),
                // phone
                Positioned(
                  left: 52,
                  top: 24,
                  width: 96,
                  height: 132,
                  child: Container(
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: line, width: 2.5),
                    ),
                  ),
                ),
                Positioned(
                  left: 85,
                  top: 30,
                  width: 30,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // rings
                Positioned(
                  left: 62,
                  top: 47,
                  width: 76,
                  height: 76,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.accentSoft(context),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 72,
                  top: 57,
                  width: 56,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.accentSoft(context).withValues(alpha: 0.6),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                // shield
                Positioned(
                  left: 84,
                  top: 66,
                  width: 32,
                  height: 45,
                  child: CustomPaint(
                    painter: _ShieldPainter(accent, s.onAccent(context)),
                  ),
                ),
                if (badgeIcons.isNotEmpty)
                  Positioned(
                    left: 30,
                    top: 88,
                    child: badge(badgeIcons[0], accent),
                  ),
                if (badgeIcons.length > 1)
                  Positioned(
                    left: 138,
                    top: 76,
                    child: badge(badgeIcons[1], s.granted(context)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter(this.color, this.check);
  final Color color;
  final Color check;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 32;
    final sy = size.height / 45;
    Offset p(double x, double y) => Offset(x * sx, y * sy);
    final path = Path()
      ..moveTo(16 * sx, 0)
      ..lineTo(32 * sx, 7 * sy)
      ..lineTo(32 * sx, 20 * sy)
      ..cubicTo(
        p(32, 31.5).dx,
        p(32, 31.5).dy,
        p(25.2, 41.8).dx,
        p(25.2, 41.8).dy,
        16 * sx,
        45 * sy,
      )
      ..cubicTo(p(6.8, 41.8).dx, p(6.8, 41.8).dy, 0, p(0, 31.5).dy, 0, 20 * sy)
      ..lineTo(0, 7 * sy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    final tick = Path()
      ..moveTo(10 * sx, 22.5 * sy)
      ..lineTo(14 * sx, 26.5 * sy)
      ..lineTo(22 * sx, 18.5 * sy);
    canvas.drawPath(
      tick,
      Paint()
        ..color = check
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * sx
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) =>
      old.color != color || old.check != check;
}

/// Illustration + large title + subtitle.
class PermissionSetupHero extends StatelessWidget {
  const PermissionSetupHero({
    super.key,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.illustration,
    this.alignStart = false,
  });

  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;

  /// Replaces the default [PermissionSetupIllustration].
  final Widget? illustration;

  /// Left-align (desktop split) instead of centring (phone).
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final align = alignStart
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    final ta = alignStart ? TextAlign.start : TextAlign.center;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.showIllustration) ...[
          illustration ?? PermissionSetupIllustration(style: style),
          const SizedBox(height: 20),
        ],
        Semantics(
          header: true,
          child: Text(
            strings.title,
            textAlign: ta,
            style:
                s.titleStyle ??
                s.type(
                  context,
                  size: 28,
                  weight: FontWeight.w800,
                  heading: true,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            strings.subtitle,
            textAlign: ta,
            style:
                s.subtitleStyle ??
                s.type(
                  context,
                  size: 14,
                  color: s.textSecondary(context),
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

/// "SETUP PROGRESS · 4 of 5 completed", a bar, "80% completed" and an optional
/// badge.
class PermissionProgressCard extends StatelessWidget {
  const PermissionProgressCard({
    super.key,
    required this.state,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
  });

  final PermissionSetupState state;
  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    final done = state.grantedCount;
    final total = state.total;
    final value = state.isLoading ? 0.0 : state.progress;
    final percent = (value * 100).round();

    if (s.isWorkstation) {
      return _workstation(context, s, done, total, value, percent);
    }

    return Semantics(
      label: strings.progress(done, total),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.surfaceAlt(context),
          borderRadius: BorderRadius.circular(s.cardRadius),
          border: Border.all(color: s.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.progressLabel.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: s.type(
                      context,
                      size: 12,
                      weight: FontWeight.w700,
                      color: s.textSecondary(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    strings.progressCompleted(done, total),
                    textAlign: TextAlign.end,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: s.type(
                      context,
                      size: 12,
                      weight: FontWeight.w600,
                      color: s.accent(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: 10,
                width: double.infinity,
                color: s.border(context).withValues(alpha: 0.9),
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOut,
                  builder: (context, v, _) => FractionallySizedBox(
                    widthFactor: v.clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: s.accentFill(context, radius: 999),
                      child: const SizedBox(height: 10),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.percentCompleted(percent),
                    style: s.type(
                      context,
                      size: 11,
                      color: s.textMuted(context),
                    ),
                  ),
                ),
                if (strings.progressBadge != null)
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: s.granted(context),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            strings.progressBadge!,
                            overflow: TextOverflow.ellipsis,
                            style: s.type(
                              context,
                              size: 11,
                              weight: FontWeight.w600,
                              color: s.granted(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension on PermissionProgressCard {
  Widget _workstation(
    BuildContext context,
    PermissionSetupStyle s,
    int done,
    int total,
    double value,
    int percent,
  ) {
    final fill = s.progressGradient ?? s.accentGradient;
    return Semantics(
      label: strings.progress(done, total),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.surfaceAlt(context),
          borderRadius: BorderRadius.circular(s.cardRadius * 0.75),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              spacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        strings.progressLabel,
                        overflow: TextOverflow.ellipsis,
                        style: s.type(
                          context,
                          size: 18,
                          weight: FontWeight.w600,
                          heading: true,
                        ),
                      ),
                    ),
                    if (strings.progressTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: s.border(context),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          strings.progressTag!,
                          style: s.type(
                            context,
                            size: 10,
                            weight: FontWeight.w700,
                            heading: true,
                            color: s.textSecondary(context),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  strings.progressCompleted(done, total),
                  style: s.type(
                    context,
                    size: 18,
                    weight: FontWeight.w700,
                    heading: true,
                    color: s.accent(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 14,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: s.inset(context),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: AlignmentDirectional.centerStart,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, v, _) => FractionallySizedBox(
                  widthFactor: v.clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill == null ? s.accent(context) : null,
                      gradient: fill,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: s.accent(context).withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const SizedBox(height: 10),
                  ),
                ),
              ),
            ),
            if (strings.progressStatus != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: s.inset(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: s.granted(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        strings.progressStatus!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: s.type(
                          context,
                          size: 11,
                          weight: FontWeight.w600,
                          heading: true,
                          color: s.granted(context),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: s.type(
                        context,
                        size: 11,
                        weight: FontWeight.w600,
                        heading: true,
                        color: s.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// "REQUIRED PERMISSIONS" heading with a caption and an optional "Allow all"
/// link.
class PermissionSectionHeader extends StatelessWidget {
  const PermissionSectionHeader({
    super.key,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.onAllowAll,
  });

  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;

  /// Shows the "Allow all" link when set.
  final VoidCallback? onAllowAll;

  @override
  Widget build(BuildContext context) {
    final s = style.resolved(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  strings.sectionTitle.toUpperCase(),
                  style: s.type(
                    context,
                    size: 14,
                    weight: FontWeight.w700,
                    heading: true,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                strings.sectionSubtitle,
                style: s.type(
                  context,
                  size: 12,
                  color: s.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (onAllowAll != null)
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              minimumSize: const Size(48, 40),
              foregroundColor: s.accent(context),
              textStyle: s.type(context, size: 13, weight: FontWeight.w700),
            ),
            onPressed: onAllowAll,
            child: Text(strings.allowAll),
          ),
      ],
    );
  }
}
