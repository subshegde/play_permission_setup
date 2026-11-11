import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import '../models/permission_grant.dart';
import 'permission_setup_actions.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// Default action bar: one primary button (Allow all, or Continue once the
/// required permissions are granted) and, when both make sense, a secondary
/// one. Everything sits in a single row.
class PermissionSetupFooter extends StatelessWidget {
  const PermissionSetupFooter({
    super.key,
    required this.state,
    required this.actions,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.showSkip = false,
    this.fill = true,
  });

  /// Current setup state.
  final PermissionSetupState state;

  /// What the buttons do.
  final PermissionSetupActions actions;

  /// Texts shown on the buttons.
  final PermissionSetupStrings strings;

  /// Colours used by the buttons.
  final PermissionSetupStyle style;

  /// Adds a Skip text button to the row (the default view puts Skip in the
  /// header instead).
  final bool showSkip;

  /// Buttons share the full width (phones) instead of hugging the right edge.
  final bool fill;

  /// At least one prompt can still be shown.
  bool get _hasAskable => state.entries.any(
    (e) =>
        e.grant == PermissionGrant.denied &&
        !state.isLocked(e) &&
        !e.isRequesting,
  );

  @override
  Widget build(BuildContext context) {
    final style = this.style.resolved(context);
    if (style.isCards) return _buildBig(context, style);
    final busy = state.isBusy;
    final canContinue = state.canContinue;
    final askable = _hasAskable;

    final Widget primary;
    Widget? secondary;
    if (canContinue) {
      primary = FilledButton(
        onPressed: busy ? null : actions.finish,
        child: Text(strings.continueLabel),
      );
      if (askable) {
        secondary = OutlinedButton(
          onPressed: busy ? null : actions.requestAll,
          child: Text(strings.allowAll),
        );
      }
    } else if (askable) {
      primary = FilledButton(
        onPressed: busy ? null : actions.requestAll,
        child: Text(strings.allowAll),
      );
    } else {
      primary = FilledButton(
        onPressed: null,
        child: Text(strings.continueLabel),
      );
    }

    Widget wrap(Widget b) => fill ? Expanded(child: b) : b;
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showSkip)
          TextButton(
            onPressed: busy ? null : actions.skip,
            child: Text(strings.skip),
          ),
        if (showSkip) const SizedBox(width: 8),
        if (secondary != null) ...[wrap(secondary), const SizedBox(width: 8)],
        wrap(primary),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.blockedRequired.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              strings.blockedRequiredHint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: style.error(context)),
            ),
          ),
        row,
      ],
    );
  }

  /// Big full-width Continue button with optional glow, trailing icon and note.
  Widget _buildBig(BuildContext context, PermissionSetupStyle style) {
    final busy = state.isBusy;
    final askable = _hasAskable;
    final canContinue = state.canContinue;
    final radius = style.primaryButtonRadius ?? style.buttonRadius;

    // Panels: a centred button at least 340 wide (or the available width).
    Widget wide(Widget b) => !style.isPanels
        ? b
        : LayoutBuilder(
            builder: (context, box) => ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: box.maxWidth < 340 ? box.maxWidth : 340,
                maxWidth: 560,
              ),
              child: b,
            ),
          );

    Widget big({
      required String label,
      required VoidCallback? onPressed,
      IconData? icon,
    }) {
      final enabled = onPressed != null;
      return Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          decoration: style
              .accentFill(context, radius: radius.clamp(0, 26).toDouble())
              .copyWith(boxShadow: enabled ? style.glow(context) : null),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius.clamp(0, 26)),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: style.type(
                          context,
                          size: style.isPanels ? 18 : 16,
                          weight: FontWeight.w700,
                          color: style.onAccent(context),
                          heading: true,
                        ),
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 18, color: style.onAccent(context)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final showAllowAllHere = !style.allowAllInSection && askable;
    final continueFirst = style.allowAllInSection || canContinue;
    final panels = style.isPanels;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: panels
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.stretch,
      children: [
        if (state.blockedRequired.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              strings.blockedRequiredHint,
              textAlign: TextAlign.center,
              style: style.type(context, size: 12, color: style.error(context)),
            ),
          ),
        if (continueFirst)
          wide(
            big(
              label: strings.continueLabel,
              icon: style.continueIcon,
              onPressed: (busy || !canContinue) ? null : actions.finish,
            ),
          )
        else if (showAllowAllHere)
          wide(
            big(
              label: strings.allowAll,
              onPressed: busy ? null : actions.requestAll,
            ),
          )
        else
          wide(
            big(
              label: strings.continueLabel,
              icon: style.continueIcon,
              onPressed: null,
            ),
          ),
        if (continueFirst && showAllowAllHere)
          TextButton(
            onPressed: busy ? null : actions.requestAll,
            child: Text(strings.allowAll),
          ),
        if (strings.footerNote != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (panels) ...[
                Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: style.textMuted(context),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  strings.footerNote!,
                  textAlign: TextAlign.center,
                  style: style.type(
                    context,
                    size: panels ? 13 : 11,
                    color: style.textSecondary(context),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    if (!panels) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: style.card(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(style.cardRadius * 0.75),
      ),
      child: content,
    );
  }
}
