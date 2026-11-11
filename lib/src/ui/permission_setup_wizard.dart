import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import '../models/permission_entry.dart';
import '../models/permission_grant.dart';
import 'permission_defaults.dart';
import 'permission_setup_actions.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// One permission per screen, with *Next* / *Back* / *Skip*: an alternative to
/// the list layout, common in onboarding flows.
///
/// Use it through `PermissionSetupPage(wizard: true)`, or put it inside a
/// `PermissionSetupBuilder` yourself:
///
/// ```dart
/// PermissionSetupBuilder(
///   items: items,
///   builder: (context, state, actions) =>
///       PermissionSetupWizard(state: state, actions: actions),
/// )
/// ```
///
/// Behaviour:
/// * *Allow* asks for the current permission. Once it is granted the wizard
///   moves on by itself.
/// * Blocked permissions show *Settings* instead; coming back with the
///   permission on moves on as well.
/// * *Skip* leaves a permission for later and goes to the next step. On the
///   last step, *Continue* finishes the flow once every required permission
///   is granted; otherwise *Review* jumps to the first missing required one.
/// * [showSkipAll] adds a "Skip setup" button that ends the whole flow.
class PermissionSetupWizard extends StatefulWidget {
  const PermissionSetupWizard({
    super.key,
    required this.state,
    required this.actions,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.showSkipAll = false,
    this.emptyBuilder,
    this.loadingBuilder,
  });

  final PermissionSetupState state;
  final PermissionSetupActions actions;
  final PermissionSetupStrings strings;

  /// Only [PermissionSetupStyle.accentColor] / `onAccentColor` are used.
  final PermissionSetupStyle style;

  /// Shows a button that ends the whole flow (calls `actions.skip()`).
  final bool showSkipAll;

  final Widget Function(BuildContext context, PermissionSetupState state)?
  emptyBuilder;
  final Widget Function(BuildContext context, PermissionSetupState state)?
  loadingBuilder;

  @override
  State<PermissionSetupWizard> createState() => _PermissionSetupWizardState();
}

class _PermissionSetupWizardState extends State<PermissionSetupWizard> {
  int _index = 0;

  /// The user asked for (or went to Settings for) the current step, so a grant
  /// that arrives next should move the wizard on.
  bool _advanceOnGrant = false;

  int get _last => widget.state.entries.length - 1;

  @override
  void didUpdateWidget(PermissionSetupWizard old) {
    super.didUpdateWidget(old);
    final entries = widget.state.entries;
    if (entries.isEmpty) return;
    _index = _index.clamp(0, _last);
    if (!_advanceOnGrant || old.state.entries.length != entries.length) return;
    final before = old.state.entries[_index];
    final now = entries[_index];
    if (!before.isSatisfied && now.isSatisfied) {
      _advanceOnGrant = false;
      if (_index < _last) _index++;
    }
  }

  void _go(int to) => setState(() {
    _advanceOnGrant = false;
    _index = to.clamp(0, _last);
  });

  void _review() {
    final i = widget.state.entries.indexWhere(
      (e) => e.item.isRequired && !e.isSatisfied,
    );
    if (i >= 0) _go(i);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state.isLoading) {
      return widget.loadingBuilder?.call(context, state) ??
          Center(
            child: Semantics(
              label: widget.strings.loading,
              child: const CircularProgressIndicator(),
            ),
          );
    }
    if (state.isEmpty) {
      return widget.emptyBuilder?.call(context, state) ?? _empty(context);
    }
    final index = _index.clamp(0, _last);
    final entry = state.entries[index];
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.style.accentColor ?? scheme.primary;
    final onAccent = widget.style.onAccentColor ?? scheme.onPrimary;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(context, index, state.entries.length, accent),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SingleChildScrollView(
                      key: ValueKey(entry.item.kind),
                      child: _content(context, entry, accent),
                    ),
                  ),
                ),
                _buttons(context, state, entry, index, accent, onAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final s = widget.strings;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                s.emptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(s.emptyMessage, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: widget.actions.finish,
                child: Text(s.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, int index, int total, Color accent) {
    final s = widget.strings;
    final label = s.wizardStepLabel
        .replaceAll('{current}', '${index + 1}')
        .replaceAll('{total}', '$total');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
            if (widget.showSkipAll)
              TextButton(
                onPressed: widget.state.isBusy ? null : widget.actions.skip,
                child: Text(s.wizardSkipAll),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (index + 1) / total,
            minHeight: 6,
            color: accent,
            semanticsLabel: s.progressLabel,
          ),
        ),
      ],
    );
  }

  String? _hint(PermissionEntry e) {
    final s = widget.strings;
    if (e.error != null) return s.errorHint;
    if (e.grant == PermissionGrant.restricted) return s.restrictedHint;
    if (e.grant == PermissionGrant.permanentlyDenied) {
      return s.permanentlyDeniedHint;
    }
    if (e.serviceDisabled) return s.serviceDisabledHint;
    if (e.grant == PermissionGrant.limited) return s.limitedHint;
    if (e.isSatisfied) return s.statusLabel(e.grant);
    if (e.attempts > 0) {
      return e.shouldOpenSettings
          ? s.deniedAgainHint
          : (e.item.rationale ?? s.statusDenied);
    }
    return null;
  }

  Widget _content(BuildContext context, PermissionEntry e, Color accent) {
    final theme = Theme.of(context);
    final title = e.item.title ?? PermissionDefaults.title(e.item.kind);
    final body =
        e.item.description ?? PermissionDefaults.description(e.item.kind);
    final hint = _hint(e);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
          ),
          child: Icon(
            e.item.icon ?? PermissionDefaults.icon(e.item.kind),
            size: 52,
            color: accent,
          ),
        ),
        const SizedBox(height: 28),
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          e.item.isRequired
              ? widget.strings.requiredBadge
              : widget.strings.optionalBadge,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 20),
          Semantics(
            liveRegion: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  e.isSatisfied
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: e.isSatisfied ? accent : theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Flexible(child: Text(hint, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buttons(
    BuildContext context,
    PermissionSetupState state,
    PermissionEntry entry,
    int index,
    Color accent,
    Color onAccent,
  ) {
    final s = widget.strings;
    final busy = state.isBusy;
    final isLast = index == _last;
    final style = FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: onAccent,
      minimumSize: const Size.fromHeight(52),
    );

    Widget primary;
    if (entry.isSatisfied && !entry.shouldOpenSettings ||
        entry.grant == PermissionGrant.limited) {
      primary = _next(isLast, state, style, busy);
    } else if (entry.grant == PermissionGrant.restricted) {
      primary = _next(isLast, state, style, busy);
    } else if (entry.shouldOpenSettings) {
      primary = FilledButton(
        style: style,
        onPressed: busy
            ? null
            : () {
                _advanceOnGrant = true;
                widget.actions.openSettings();
              },
        child: Text(s.openSettings),
      );
    } else {
      primary = FilledButton(
        style: style,
        onPressed: busy
            ? null
            : () {
                _advanceOnGrant = true;
                widget.actions.request(entry.item.kind);
              },
        child: entry.isRequesting
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: onAccent,
                ),
              )
            : Text(s.allow),
      );
    }

    final satisfied = entry.isSatisfied;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLast && !state.canContinue)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              s.wizardIncomplete,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        primary,
        const SizedBox(height: 8),
        Row(
          children: [
            if (index > 0)
              TextButton(
                onPressed: busy ? null : () => _go(index - 1),
                child: Text(s.wizardBack),
              ),
            const Spacer(),
            if (isLast && !state.canContinue)
              TextButton(
                onPressed: busy ? null : _review,
                child: Text(s.wizardReview),
              )
            else if (!satisfied && !isLast)
              TextButton(
                onPressed: busy ? null : () => _go(index + 1),
                child: Text(s.skip),
              )
            else if (!satisfied && isLast && state.canContinue)
              TextButton(
                onPressed: busy ? null : widget.actions.finish,
                child: Text(s.skip),
              ),
          ],
        ),
      ],
    );
  }

  /// "Next" in the middle of the flow, "Continue" on the last step.
  Widget _next(
    bool isLast,
    PermissionSetupState state,
    ButtonStyle style,
    bool busy,
  ) {
    final s = widget.strings;
    if (!isLast) {
      return FilledButton(
        style: style,
        onPressed: busy ? null : () => _go(_index + 1),
        child: Text(s.wizardNext),
      );
    }
    return FilledButton(
      style: style,
      onPressed: busy || !state.canContinue ? null : widget.actions.finish,
      child: Text(s.continueLabel),
    );
  }
}
