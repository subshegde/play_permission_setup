import 'package:flutter/material.dart';

import '../models/permission_entry.dart';
import '../models/permission_grant.dart';
import 'permission_defaults.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// Default row for one permission: icon, title, short description and a single
/// trailing control (Allow / ✓ / Settings). It has no border of its own – the
/// view places rows in a rounded group with dividers. Reuse it inside your own
/// `itemBuilder` to keep the behaviour but change the surroundings.
class PermissionTile extends StatelessWidget {
  const PermissionTile({
    super.key,
    required this.entry,
    required this.onAllow,
    required this.onOpenSettings,
    this.lockedBy,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
  });

  /// The permission (and its current status) shown by this row.
  final PermissionEntry entry;

  /// Called when the user taps Allow (or Retry).
  final VoidCallback onAllow;

  /// Called when the user taps Settings / Manage.
  final VoidCallback onOpenSettings;

  /// Title of an unmet dependency; Allow is disabled while this is set.
  final String? lockedBy;

  /// Texts shown by the row.
  final PermissionSetupStrings strings;

  /// Colours and shapes used by the row.
  final PermissionSetupStyle style;

  String? _hint() {
    if (entry.error != null) return strings.errorHint;
    switch (entry.grant) {
      case PermissionGrant.permanentlyDenied:
        return strings.permanentlyDeniedHint;
      case PermissionGrant.restricted:
        return strings.restrictedHint;
      case PermissionGrant.limited:
        return strings.limitedHint;
      case PermissionGrant.denied:
        if (lockedBy != null) return strings.lockedHint(lockedBy!);
        if (entry.attempts >= 2) return strings.deniedAgainHint;
        return entry.item.rationale;
      default:
        return entry.serviceDisabled ? strings.serviceDisabledHint : null;
    }
  }

  Color _hintColor(BuildContext c, PermissionSetupStyle style) {
    switch (entry.grant) {
      case PermissionGrant.permanentlyDenied:
      case PermissionGrant.restricted:
        return style.error(c);
      case PermissionGrant.limited:
        return style.warning(c);
      default:
        return entry.error != null
            ? style.error(c)
            : (entry.serviceDisabled
                  ? style.warning(c)
                  : Theme.of(c).colorScheme.onSurfaceVariant);
    }
  }

  static const _compact = VisualDensity(horizontal: -2, vertical: -2);

  /// The one control on the right-hand side.
  Widget? _trailing(BuildContext context, PermissionSetupStyle style) {
    final grant = entry.grant;
    ButtonStyle? btn(ButtonStyle? base) => base;
    final small = ButtonStyle(
      visualDensity: _compact,
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(64, 36)),
    );

    if (entry.isRequesting) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (entry.error != null) {
      return OutlinedButton(
        style: btn(small),
        onPressed: onAllow,
        child: Text(strings.retry),
      );
    }
    switch (grant) {
      case PermissionGrant.denied:
      case PermissionGrant.unknown:
        if (grant == PermissionGrant.unknown) return null;
        // After repeated refusals the system dialog may never show again.
        if (entry.shouldOpenSettings && entry.attempts >= 2) {
          return OutlinedButton(
            style: btn(small),
            onPressed: onOpenSettings,
            child: Text(strings.openSettings),
          );
        }
        return FilledButton.tonal(
          style: btn(small),
          onPressed: lockedBy == null ? onAllow : null,
          child: Text(strings.allow),
        );
      case PermissionGrant.permanentlyDenied:
        return OutlinedButton(
          style: btn(small),
          onPressed: onOpenSettings,
          child: Text(strings.openSettings),
        );
      case PermissionGrant.restricted:
        return Icon(
          Icons.lock_outline_rounded,
          size: 22,
          color: style.error(context),
        );
      case PermissionGrant.limited:
        return OutlinedButton(
          style: btn(small),
          onPressed: onOpenSettings,
          child: Text(strings.manage),
        );
      default:
        if (entry.serviceDisabled) {
          return OutlinedButton(
            style: btn(small),
            onPressed: onOpenSettings,
            child: Text(strings.openSettings),
          );
        }
        return Icon(
          Icons.check_circle_rounded,
          size: 24,
          color: style.granted(context),
        );
    }
  }

  // ── card variant ─────────────────────────────────────────────────────────

  /// Dot + text under the description for the card variant.
  ({Widget leading, String text, Color color})? _cardStatus(
    BuildContext c,
    PermissionSetupStyle s,
  ) {
    Widget dot(Color col) => Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: col, shape: BoxShape.circle),
    );
    Widget icon(IconData i, Color col) => Icon(i, size: 13, color: col);

    if (entry.error != null) {
      return (
        leading: dot(s.error(c)),
        text: strings.errorHint,
        color: s.error(c),
      );
    }
    switch (entry.grant) {
      case PermissionGrant.permanentlyDenied:
        return (
          leading: icon(Icons.error_outline_rounded, s.warning(c)),
          text: strings.permanentlyDeniedHint,
          color: s.warning(c),
        );
      case PermissionGrant.restricted:
        return (
          leading: icon(Icons.lock_outline_rounded, s.textMuted(c)),
          text: strings.restrictedHint,
          color: s.textMuted(c),
        );
      case PermissionGrant.limited:
        return (
          leading: dot(s.info(c)),
          text: strings.statusLimited,
          color: s.info(c),
        );
      case PermissionGrant.denied:
        if (lockedBy != null) {
          return (
            leading: icon(Icons.lock_clock_outlined, s.textMuted(c)),
            text: strings.lockedHint(lockedBy!),
            color: s.textMuted(c),
          );
        }
        if (entry.attempts >= 2) {
          return (
            leading: icon(Icons.error_outline_rounded, s.warning(c)),
            text: strings.deniedAgainHint,
            color: s.warning(c),
          );
        }
        return (
          leading: dot(s.error(c)),
          text: entry.item.rationale ?? strings.statusDenied,
          color: s.error(c),
        );
      default:
        if (entry.serviceDisabled) {
          return (
            leading: dot(s.warning(c)),
            text: strings.serviceDisabledHint,
            color: s.warning(c),
          );
        }
        return null;
    }
  }

  Widget? _cardTrailing(BuildContext c, PermissionSetupStyle s) {
    if (entry.isRequesting) {
      return _Pill(
        style: s,
        kind: _PillKind.soft,
        color: s.accent(c),
        busy: true,
        label: strings.requesting,
      );
    }
    if (entry.error != null) {
      return _Pill(
        style: s,
        kind: _PillKind.outlined,
        label: strings.retry,
        icon: Icons.refresh_rounded,
        onPressed: onAllow,
      );
    }
    final panels = s.isPanels;
    Widget settings() => _Pill(
      style: s,
      kind: panels ? _PillKind.tonal : _PillKind.outlined,
      label: strings.openSettings,
      icon: Icons.settings_outlined,
      onPressed: onOpenSettings,
    );
    switch (entry.grant) {
      case PermissionGrant.unknown:
        return null;
      case PermissionGrant.denied:
        if (entry.shouldOpenSettings && entry.attempts >= 2) return settings();
        return _Pill(
          style: s,
          kind: _PillKind.filled,
          label: strings.allow,
          trailingIcon: panels ? Icons.arrow_forward_rounded : null,
          onPressed: lockedBy == null ? onAllow : null,
        );
      case PermissionGrant.permanentlyDenied:
        return settings();
      case PermissionGrant.restricted:
        if (panels) {
          return _Pill(
            style: s,
            kind: _PillKind.tonal,
            color: s.textMuted(c),
            icon: Icons.lock_outline_rounded,
            label: strings.restrictedChip,
          );
        }
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: s.border(c).withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: s.textMuted(c),
          ),
        );
      case PermissionGrant.limited:
        return _Pill(
          style: s,
          kind: panels ? _PillKind.tonal : _PillKind.outlined,
          label: strings.manage,
          onPressed: onOpenSettings,
        );
      default:
        if (entry.serviceDisabled) return settings();
        return _Pill(
          style: s,
          kind: _PillKind.soft,
          color: s.granted(c),
          soft: s.grantedSoft(c),
          label: strings.statusLabel(entry.grant),
          icon: panels
              ? Icons.check_circle_outline_rounded
              : Icons.check_rounded,
        );
    }
  }

  Widget _chip(BuildContext c, PermissionSetupStyle s) {
    final needsSettings =
        !s.isPanels && entry.grant == PermissionGrant.permanentlyDenied;
    final String label;
    final Color fg;
    final Color bg;
    if (needsSettings) {
      label = strings.openSettings;
      fg = s.warning(c);
      bg = s.warningSoft(c);
    } else {
      label = entry.item.isRequired
          ? strings.requiredChip
          : strings.optionalChip;
      fg = s.textSecondary(c);
      bg = s.border(c).withValues(alpha: 0.7);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: s.type(
          c,
          size: 10,
          weight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, PermissionSetupStyle s) {
    final item = entry.item;
    final title = item.title ?? PermissionDefaults.title(item.kind);
    final description =
        item.description ?? PermissionDefaults.description(item.kind);
    final panels = s.isPanels;
    // Panels show "Not allowed" / "Limited access" next to the action.
    final inline =
        panels &&
        entry.error == null &&
        ((entry.grant == PermissionGrant.denied &&
                lockedBy == null &&
                entry.attempts < 2) ||
            entry.grant == PermissionGrant.limited);
    final status = inline ? null : _cardStatus(context, s);
    final action = _cardTrailing(context, s);
    final Widget? inlineStatus = !inline
        ? null
        : entry.grant == PermissionGrant.limited
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: s.infoSoft(context),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: s.info(context),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    strings.statusLimited,
                    overflow: TextOverflow.ellipsis,
                    style: s.type(
                      context,
                      size: 11,
                      weight: FontWeight.w700,
                      heading: true,
                      color: s.info(context),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: s.error(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entry.item.rationale ?? strings.statusDenied,
                  overflow: TextOverflow.ellipsis,
                  style: s.type(
                    context,
                    size: 11,
                    weight: FontWeight.w700,
                    heading: true,
                    color: s.error(context),
                  ),
                ),
              ),
            ],
          );
    final trailing = (action == null && inlineStatus == null)
        ? null
        : Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [?inlineStatus, ?action],
          );
    final muted =
        entry.grant == PermissionGrant.restricted ||
        entry.grant == PermissionGrant.notApplicable;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style:
                  s.tileTitleStyle ??
                  s.type(
                    context,
                    size: panels ? 18 : 14,
                    weight: panels ? FontWeight.w600 : FontWeight.w700,
                    heading: true,
                    color: panels && muted ? s.textSecondary(context) : null,
                  ),
            ),
            _chip(context, s),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style:
              s.tileDescriptionStyle ??
              s.type(
                context,
                size: panels ? 13 : 12,
                color: s.textSecondary(context),
                height: 1.4,
              ),
        ),
        if (status != null) ...[
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: status.leading,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  status.text,
                  style: s.type(
                    context,
                    size: 11,
                    weight: FontWeight.w500,
                    color: status.color,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // Panels colour the icon by status; cards use the accent.
    Color iconColor = s.accent(context);
    Color iconBg = s.accentSoft(context);
    if (muted) {
      iconColor = s.textSecondary(context);
      iconBg = s.border(context).withValues(alpha: 0.6);
    } else if (panels) {
      switch (entry.grant) {
        case PermissionGrant.granted:
        case PermissionGrant.provisional:
          iconColor = s.granted(context);
          iconBg = s.grantedSoft(context);
        case PermissionGrant.permanentlyDenied:
        case PermissionGrant.limited:
          iconColor = s.info(context);
          iconBg = s.infoSoft(context);
        default:
      }
    }
    final iconSize = panels ? 48.0 : 44.0;
    final icon = ExcludeSemantics(
      child: Container(
        width: iconSize,
        height: iconSize,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(s.iconRadius),
        ),
        child: Icon(
          item.icon ?? PermissionDefaults.icon(item.kind),
          size: panels ? 24 : 22,
          color: iconColor,
        ),
      ),
    );

    return Semantics(
      container: true,
      label: '$title. ${strings.statusLabel(entry.grant)}. $description',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.card(context),
          borderRadius: BorderRadius.circular(s.cardRadius),
          border: s.isPanels ? null : Border.all(color: s.border(context)),
          boxShadow: s.cardShadows,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final stack =
                box.maxWidth < (s.isPanels ? 540 : 330) ||
                MediaQuery.textScalerOf(context).scale(14) > 21;
            return Padding(
              padding: EdgeInsets.all(s.isPanels ? 20 : 16),
              child: stack
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            icon,
                            const SizedBox(width: 12),
                            Expanded(child: text),
                          ],
                        ),
                        if (trailing != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: trailing,
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: text),
                        if (trailing != null) ...[
                          const SizedBox(width: 10),
                          trailing,
                        ],
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = this.style.resolved(context);
    if (style.isCards) return _buildCard(context, style);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = entry.item;
    final title = item.title ?? PermissionDefaults.title(item.kind);
    final description =
        item.description ?? PermissionDefaults.description(item.kind);
    final hint = _hint();
    final done =
        entry.isSatisfied &&
        !entry.serviceDisabled &&
        entry.grant != PermissionGrant.limited;
    final trailing = _trailing(context, style);
    final showRequired = item.isRequired && !entry.isSatisfied;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style:
                  style.tileTitleStyle ??
                  theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (showRequired)
              Text(
                strings.requiredBadge,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: style.accent(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style:
              style.tileDescriptionStyle ??
              theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: done ? 0.75 : 1,
                ),
              ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: _hintColor(context, style),
            ),
          ),
        ],
      ],
    );

    final icon = ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: style.accent(context).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          item.icon ?? PermissionDefaults.icon(item.kind),
          size: 22,
          color: style.accent(context),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: '$title. ${strings.statusLabel(entry.grant)}. $description',
      child: LayoutBuilder(
        builder: (context, box) {
          // Very narrow row or huge text: put the control under the text.
          final stack =
              box.maxWidth < 330 ||
              MediaQuery.textScalerOf(context).scale(14) > 21;
          return Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
            child: stack
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: text),
                        ],
                      ),
                      if (trailing != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: trailing,
                        ),
                      ],
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: 12),
                      Expanded(child: text),
                      if (trailing != null) ...[
                        const SizedBox(width: 12),
                        trailing,
                      ],
                    ],
                  ),
          );
        },
      ),
    );
  }
}

enum _PillKind { filled, outlined, soft, tonal }

/// Rounded status / action pill used by card rows.
class _Pill extends StatelessWidget {
  const _Pill({
    required this.style,
    required this.kind,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.soft,
    this.busy = false,
    this.trailingIcon,
  });

  final PermissionSetupStyle style;
  final IconData? trailingIcon;
  final _PillKind kind;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? soft;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = style;
    final radius = BorderRadius.circular(s.buttonRadius);
    final enabled = onPressed != null;

    final Color fg;
    BoxDecoration deco;
    switch (kind) {
      case _PillKind.filled:
        fg = s.onAccent(context);
        deco = s
            .accentFill(context)
            .copyWith(
              boxShadow: enabled
                  ? s
                        .glow(context)
                        .map(
                          (b) => BoxShadow(
                            color: b.color.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        )
                        .toList()
                  : null,
            );
      case _PillKind.outlined:
        fg = s.text(context);
        deco = BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: s.border(context).withValues(alpha: 1)),
        );
      case _PillKind.tonal:
        fg = color ?? s.text(context);
        deco = BoxDecoration(
          color: s.surfaceAlt(context),
          borderRadius: radius,
        );
      case _PillKind.soft:
        fg = color ?? s.accent(context);
        deco = BoxDecoration(
          color: soft ?? s.accentSoft(context),
          borderRadius: radius,
        );
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            ),
            const SizedBox(width: 6),
          ] else if (icon != null) ...[
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: s.type(
                context,
                size: 12,
                weight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 16, color: fg),
          ],
        ],
      ),
    );

    return Opacity(
      opacity: (kind == _PillKind.filled && !enabled) ? 0.5 : 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: deco,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onPressed,
            child: Align(
              alignment: Alignment.center,
              widthFactor: 1,
              heightFactor: 1,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
