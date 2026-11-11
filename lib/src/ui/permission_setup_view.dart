import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import '../core/permission_kind.dart';
import '../models/permission_entry.dart';
import 'permission_defaults.dart';
import 'permission_setup_actions.dart';
import 'permission_setup_footer.dart';
import '../models/permission_grant.dart';
import 'permission_setup_header.dart';
import 'permission_setup_hero.dart';
import 'permission_setup_workstation.dart';
import 'package:flutter/services.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';
import 'permission_tile.dart';

typedef PermissionHeaderBuilder =
    Widget Function(
      BuildContext context,
      PermissionSetupState state,
      PermissionSetupLayout layout,
    );
typedef PermissionItemBuilder =
    Widget Function(
      BuildContext context,
      PermissionEntry entry,
      PermissionSetupState state,
      PermissionSetupActions actions,
    );
typedef PermissionFooterBuilder =
    Widget Function(
      BuildContext context,
      PermissionSetupState state,
      PermissionSetupActions actions,
    );
typedef PermissionStateBuilder =
    Widget Function(BuildContext context, PermissionSetupState state);

/// Responsive default UI. Rows live in a rounded group (like system settings)
/// so a long list stays compact:
///
/// * compact  – full width, buttons share one row in a pinned bar (phones)
/// * medium   – one readable column, centred (tablets, small windows)
/// * expanded – two columns when they fit, buttons right-aligned (desktop)
///
/// Layout is chosen from the space the widget is given, so it also works in
/// dialogs, side panels and resizable desktop windows.
class PermissionSetupView extends StatelessWidget {
  /// Creates the default view for [state].
  const PermissionSetupView({
    super.key,
    required this.state,
    required this.actions,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.headerBuilder,
    this.itemBuilder,
    this.footerBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.showSkip = true,
    this.forcedLayout,
    this.brand,
    this.onToggleTheme,
    this.illustration,
    this.desktopStyle,
    this.topBanner,
    this.bottomBanner,
  });

  /// State to render.
  final PermissionSetupState state;

  /// What the buttons do.
  final PermissionSetupActions actions;

  /// All texts.
  final PermissionSetupStrings strings;

  /// Colours, radii and breakpoints.
  final PermissionSetupStyle style;

  /// Replaces the header.
  final PermissionHeaderBuilder? headerBuilder;

  /// Replaces each row.
  final PermissionItemBuilder? itemBuilder;

  /// Replaces the action bar.
  final PermissionFooterBuilder? footerBuilder;

  /// Replaces the "nothing to set up" state.
  final PermissionStateBuilder? emptyBuilder;

  /// Replaces the loading state.
  final PermissionStateBuilder? loadingBuilder;

  /// Shows the Skip button.
  final bool showSkip;

  /// Pin a layout instead of choosing by width.
  final PermissionSetupLayout? forcedLayout;

  /// Name / logo / badge shown in the top bar of the hero layout.
  final PermissionSetupBrand? brand;

  /// Shows a light/dark toggle in the top bar when set (the host app owns the
  /// theme, so it decides what toggling means).
  final VoidCallback? onToggleTheme;

  /// Replaces the hero illustration.
  final Widget? illustration;

  /// Style used instead of [style] on desktop operating systems (Windows,
  /// macOS, Linux) and on wide web windows. Typically
  /// `PermissionSetupStyle.workstation`.
  final PermissionSetupStyle? desktopStyle;

  /// Widget shown above the content (e.g. a [PermissionSetupMetaBar]) and one
  /// at the very end (e.g. a status footer). Workstation layout.
  final Widget? topBanner;
  final Widget? bottomBanner;

  @override
  Widget build(BuildContext context) => _ViewBuilder(
    this,
    PermissionSetupStyle.select(context, style, desktopStyle).resolved(context),
  ).build(context);
}

/// The layout logic of [PermissionSetupView]. A plain object (no widget state):
/// everything it needs is the view's fields and the resolved style.
class _ViewBuilder {
  _ViewBuilder(this.widget, this._style);

  final PermissionSetupView widget;
  final PermissionSetupStyle _style;

  PermissionSetupState get _state => widget.state;

  bool get _askable => _state.entries.any(
    (e) =>
        e.grant == PermissionGrant.denied &&
        !_state.isLocked(e) &&
        !e.isRequesting,
  );

  /// Hero block: illustration, title, subtitle and progress card.
  Widget _hero(BuildContext c, PermissionSetupLayout layout, bool alignStart) {
    final custom = widget.headerBuilder;
    if (custom != null) return custom(c, _state, layout);
    if (_style.isWorkstation) {
      return PermissionSetupWorkstationPanel(
        state: _state,
        strings: widget.strings,
        style: _style,
        illustration: widget.illustration,
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PermissionSetupHero(
          strings: widget.strings,
          style: _style,
          illustration: widget.illustration,
          alignStart: alignStart,
        ),
        if (_style.showProgress && _state.total > 0) ...[
          const SizedBox(height: 24),
          PermissionProgressCard(
            state: _state,
            strings: widget.strings,
            style: _style,
          ),
        ],
      ],
    );
  }

  Widget _topBar() => _style.isWorkstation
      ? PermissionSetupTopBar(
          brand: widget.brand,
          style: _style,
          strings: widget.strings,
          onToggleTheme: widget.onToggleTheme,
          onSkip: widget.showSkip && !_state.isBusy
              ? widget.actions.skip
              : null,
        )
      : PermissionSetupBrandBar(
          brand: widget.brand,
          style: _style,
          strings: widget.strings,
          onToggleTheme: widget.onToggleTheme,
          onSkip: widget.showSkip && !_state.isBusy
              ? widget.actions.skip
              : null,
        );

  bool get _hasTopBar =>
      widget.brand != null || widget.onToggleTheme != null || widget.showSkip;

  /// Optional heading + the permission rows.
  Widget _list(BuildContext c, int cols) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_style.showSectionHeader) ...[
        if (_style.isWorkstation)
          PermissionWorkstationSectionHeader(
            state: _state,
            strings: widget.strings,
            style: _style,
            onAllowAll: _style.allowAllInSection && _askable && !_state.isBusy
                ? widget.actions.requestAll
                : null,
          )
        else
          PermissionSectionHeader(
            strings: widget.strings,
            style: _style,
            onAllowAll: _style.allowAllInSection && _askable && !_state.isBusy
                ? widget.actions.requestAll
                : null,
          ),
        SizedBox(height: _style.isWorkstation ? 8 : 14),
      ],
      _groups(c, cols),
    ],
  );

  Widget _header(BuildContext c, PermissionSetupLayout layout) {
    final custom = widget.headerBuilder;
    if (custom != null) return custom(c, _state, layout);
    return PermissionSetupHeader(
      state: _state,
      strings: widget.strings,
      style: _style,
      trailing: widget.showSkip
          ? TextButton(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsetsDirectional.only(start: 12),
                minimumSize: const Size(48, 40),
                alignment: AlignmentDirectional.centerEnd,
              ),
              onPressed: _state.isBusy ? null : widget.actions.skip,
              child: Text(widget.strings.skip),
            )
          : null,
    );
  }

  Widget _footer(BuildContext c, {required bool fill}) {
    final custom = widget.footerBuilder?.call(c, _state, widget.actions);
    if (custom != null) return custom;
    final footer = PermissionSetupFooter(
      state: _state,
      actions: widget.actions,
      strings: widget.strings,
      style: _style,
      fill: fill,
    );
    // A full-width big button looks wrong on a desktop window.
    return _style.isCards && !_style.isPanels && !fill
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: footer,
            ),
          )
        : footer;
  }

  Widget _tile(BuildContext c, PermissionEntry e) {
    final custom = widget.itemBuilder;
    if (custom != null) return custom(c, e, _state, widget.actions);
    String? lockedBy;
    for (final dep in e.item.kind.dependsOn) {
      final d = _state.entryOf(dep);
      if (d != null && !d.isSatisfied) {
        lockedBy = d.item.title ?? PermissionDefaults.title(dep);
        break;
      }
    }
    return PermissionTile(
      key: ValueKey(e.item.kind),
      entry: e,
      lockedBy: lockedBy,
      strings: widget.strings,
      style: _style,
      onAllow: () => widget.actions.request(e.item.kind),
      onOpenSettings: widget.actions.openSettings,
    );
  }

  Widget _groups(BuildContext c, int cols) {
    final tiles = [for (final e in _state.entries) _tile(c, e)];
    if (cols <= 1) return _Group(style: _style, children: tiles);
    final per = (tiles.length / cols).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cols; i++) ...[
          if (i > 0) SizedBox(width: _style.spacing),
          Expanded(
            child: i * per >= tiles.length
                ? const SizedBox.shrink()
                : _Group(
                    style: _style,
                    children: tiles.sublist(
                      i * per,
                      ((i + 1) * per).clamp(0, tiles.length),
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, box) {
        if (_state.isLoading) {
          return widget.loadingBuilder?.call(context, _state) ??
              _CenteredMessage(
                loading: true,
                title: widget.strings.loading,
                message: null,
              );
        }
        if (_state.isEmpty) {
          return widget.emptyBuilder?.call(context, _state) ??
              _CenteredMessage(
                title: widget.strings.emptyTitle,
                message: widget.strings.emptyMessage,
                footer: _footer(context, fill: true),
              );
        }

        final layout = widget.forcedLayout ?? _style.layoutFor(box.maxWidth);
        final gutter = layout == PermissionSetupLayout.compact ? 16.0 : 24.0;
        final avail =
            (box.maxWidth.isFinite ? box.maxWidth : 600.0) - 2 * gutter;
        final hero = _style.isHero;
        // Hero + list side by side on wide windows.
        final split =
            hero &&
            _style.splitWhenExpanded &&
            layout == PermissionSetupLayout.expanded;
        final cols = (layout == PermissionSetupLayout.compact || split)
            ? 1
            : ((avail + _style.spacing) /
                      (_style.minColumnWidth + _style.spacing))
                  .floor()
                  .clamp(1, _style.maxColumns);
        final contentW =
            (cols == 1 && !split
                    ? _style.singleColumnMaxWidth
                    : _style.maxContentWidth)
                .clamp(0.0, avail);
        final fill = layout == PermissionSetupLayout.compact;

        final bounded = box.hasBoundedHeight;
        // Short window (landscape phone): footer scrolls with the content.
        // Pinned bar on phones; on wider screens the buttons sit under the
        // list (a pinned bar would float far from a short list).
        final pinFooter =
            bounded && box.maxHeight >= 480 && (fill || _style.pinFooterOnWide);

        Widget centered(Widget child) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: contentW, child: child),
        );

        final body = Padding(
          padding: EdgeInsets.fromLTRB(gutter, gutter, gutter, gutter),
          child: centered(
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hero) ...[
                  if (!_style.isWorkstation && _hasTopBar) _topBar(),
                  if (widget.topBanner != null) ...[
                    widget.topBanner!,
                    const SizedBox(height: 24),
                  ] else
                    const SizedBox(height: 20),
                  if (split)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _hero(context, layout, true)),
                        const SizedBox(width: 40),
                        Expanded(flex: 7, child: _list(context, 1)),
                      ],
                    )
                  else ...[
                    _hero(context, layout, false),
                    const SizedBox(height: 24),
                    _list(context, cols),
                  ],
                ] else ...[
                  _header(context, layout),
                  const SizedBox(height: 16),
                  _list(context, cols),
                ],
                if (!pinFooter) ...[
                  SizedBox(height: _style.isPanels ? 24 : 16),
                  _footer(context, fill: fill),
                ],
                if (widget.bottomBanner != null) ...[
                  const SizedBox(height: 24),
                  widget.bottomBanner!,
                ],
              ],
            ),
          ),
        );

        if (!bounded) return SafeArea(child: body);

        // (Material adds a scrollbar on desktop by itself.)
        final scrollable = SingleChildScrollView(child: body);
        return SafeArea(
          child: pinFooter
              ? Column(
                  children: [
                    Expanded(child: scrollable),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _style.background(context),
                        border: Border(
                          top: BorderSide(
                            color: _style.isCards
                                ? _style.border(context)
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        boxShadow: _style.isCards
                            ? const [
                                BoxShadow(
                                  color: Color(0x0D000000),
                                  blurRadius: 24,
                                  offset: Offset(0, -8),
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
                        child: centered(_footer(context, fill: fill)),
                      ),
                    ),
                  ],
                )
              : scrollable,
        );
      },
    );

    Widget page = content;
    // Workstation: a full-width app bar above the scrolling content.
    if (_style.isWorkstation &&
        !_state.isLoading &&
        !_state.isEmpty &&
        _hasTopBar) {
      page = LayoutBuilder(
        builder: (context, box) => Column(
          mainAxisSize: box.hasBoundedHeight
              ? MainAxisSize.max
              : MainAxisSize.min,
          children: [
            _topBar(),
            if (box.hasBoundedHeight) Expanded(child: content) else content,
          ],
        ),
      );
    }

    // Desktop keyboard: Enter continues when nothing else has focus.
    if (_style.enableKeyboardShortcuts) {
      page = Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              node.hasPrimaryFocus &&
              _state.canContinue &&
              !_state.isBusy) {
            widget.actions.finish();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: page,
      );
    }

    return ColoredBox(color: _style.background(context), child: page);
  }
}

/// Rounded container that stacks rows with hairline dividers.
class _Group extends StatelessWidget {
  const _Group({required this.children, required this.style});
  final List<Widget> children;
  final PermissionSetupStyle style;

  @override
  Widget build(BuildContext context) {
    if (style.isCards) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: style.tileGap),
            children[i],
          ],
        ],
      );
    }
    final line = Theme.of(context).colorScheme.outlineVariant;
    return Material(
      color: style.card(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.cardRadius),
        side: BorderSide(color: line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 68, color: line),
            SizedBox(width: double.infinity, child: children[i]),
          ],
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.title,
    this.message,
    this.footer,
    this.loading = false,
  });
  final String title;
  final String? message;
  final Widget? footer;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const CircularProgressIndicator()
                else
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 56,
                    color: theme.colorScheme.primary,
                  ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (footer != null) ...[const SizedBox(height: 24), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
