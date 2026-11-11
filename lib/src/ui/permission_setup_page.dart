import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/permission_detection_cubit.dart';
import '../bloc/permission_setup_bloc.dart';
import '../models/permission_item.dart';
import '../service/permission_detector.dart';
import '../service/permission_service.dart';
import 'permission_defaults.dart';
import 'permission_setup_builder.dart';
import 'permission_setup_hero.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';
import 'permission_setup_wizard.dart';
import 'permission_setup_view.dart';

/// Ready-made, responsive permission setup screen.
///
/// Customise at four levels:
/// 1. [items] – titles, descriptions, icons, required/optional
/// 2. [style] / [strings] – colours, radii, breakpoints, all text
/// 3. builders – replace header, tiles, footer, empty/loading states
/// 4. [PermissionSetupBuilder] – build everything yourself on the same bloc
class PermissionSetupPage extends StatelessWidget {
  const PermissionSetupPage({
    super.key,
    this.items,
    this.detection = const PermissionDetection(),
    this.onComplete,
    this.onSkip,
    this.service,
    this.bloc,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.headerBuilder,
    this.itemBuilder,
    this.footerBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.allowSkip,
    this.autoCompleteWhenSatisfied = false,
    this.autoRequest = false,
    this.wizard = false,
    this.explainBeforeAsk = false,
    this.explainBuilder,
    this.forcedLayout,
    this.appBar,
    this.brand,
    this.onToggleTheme,
    this.illustration,
    this.desktopStyle,
    this.topBanner,
    this.bottomBanner,
  });

  /// The permissions to show. **Leave it out** and the page scans the running
  /// app (merged `AndroidManifest.xml`, iOS `Info.plist`) and shows exactly
  /// what it declares. Pass a list only to hard-code the screen.
  final List<PermissionItem>? items;

  /// How the scanned list is built (required kinds, exclusions, your own texts,
  /// fallback). Ignored when [items] or [bloc] is given.
  final PermissionDetection detection;

  /// Called once when all required permissions are granted and the user taps
  /// Continue (or immediately if [autoCompleteWhenSatisfied]).
  final void Function(PermissionSetupState state)? onComplete;

  /// Called when the user taps "Skip". The Skip button is shown when this is
  /// set (or [allowSkip] is true).
  final void Function(PermissionSetupState state)? onSkip;
  final PermissionService? service;
  final PermissionSetupBloc? bloc;
  final PermissionSetupStrings strings;
  final PermissionSetupStyle style;
  final PermissionHeaderBuilder? headerBuilder;
  final PermissionItemBuilder? itemBuilder;
  final PermissionFooterBuilder? footerBuilder;
  final PermissionStateBuilder? emptyBuilder;
  final PermissionStateBuilder? loadingBuilder;
  final bool? allowSkip;
  final bool autoCompleteWhenSatisfied;

  /// Open the system permission dialogs one after another as soon as the page
  /// appears, instead of waiting for taps. Ones that need Settings are skipped.
  final bool autoRequest;

  /// Before each system dialog, show a short "why we need this" message (the
  /// item's `description`, or the default one) with *Continue* / *Not now*.
  /// *Not now* skips that permission without counting as a refusal. Works
  /// together with [autoRequest]. Off by default.
  final bool explainBeforeAsk;

  /// One permission per screen with *Next* / *Back* / *Skip*, instead of the
  /// list. Uses [strings], [style] (accent colours), [allowSkip] (adds "Skip
  /// setup"), [emptyBuilder] and [loadingBuilder]; the list-only options
  /// (`itemBuilder`, `headerBuilder`, `footerBuilder`, `brand`, banners,
  /// `forcedLayout`, `desktopStyle`) are ignored. Off by default.
  final bool wizard;

  /// Replace the default explanation dialog. Return `true` to go on and show
  /// the system dialog, `false` to skip it. Only used with [explainBeforeAsk].
  final Future<bool> Function(BuildContext context, PermissionItem item)?
  explainBuilder;
  final PermissionSetupLayout? forcedLayout;
  final PreferredSizeWidget? appBar;

  /// Logo / name / badge in the top bar (hero style).
  final PermissionSetupBrand? brand;

  /// Shows a light/dark toggle when set.
  final VoidCallback? onToggleTheme;

  /// Replaces the hero illustration.
  final Widget? illustration;

  /// Style for desktop operating systems (Windows, macOS, Linux) and wide web
  /// windows, e.g. `PermissionSetupStyle.workstation`. Phones and tablets keep
  /// using [style].
  final PermissionSetupStyle? desktopStyle;

  /// Widgets above and below the content (see [PermissionSetupMetaBar]).
  final Widget? topBanner;
  final Widget? bottomBanner;

  @override
  Widget build(BuildContext context) {
    if (items != null || bloc != null) return _page(context, items ?? const []);
    return _DetectedItems(
      detection: detection,
      loading: (context) => Scaffold(
        backgroundColor: PermissionSetupStyle.select(
          context,
          style,
          desktopStyle,
        ).resolved(context).background(context),
        appBar: appBar,
        body:
            loadingBuilder?.call(context, const PermissionSetupState()) ??
            Center(
              child: Semantics(
                label: strings.loading,
                child: const CircularProgressIndicator(),
              ),
            ),
      ),
      builder: _page,
    );
  }

  Future<bool> _explain(BuildContext context, PermissionItem item) async {
    final title = item.title ?? PermissionDefaults.title(item.kind);
    final body = item.description ?? PermissionDefaults.description(item.kind);
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(item.icon ?? PermissionDefaults.icon(item.kind)),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body),
            const SizedBox(height: 12),
            Text(
              strings.explainFootnote,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.explainSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.explainContinue),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Widget _page(BuildContext context, List<PermissionItem> list) {
    return Scaffold(
      backgroundColor: PermissionSetupStyle.select(
        context,
        style,
        desktopStyle,
      ).resolved(context).background(context),
      appBar: appBar,
      body: PermissionSetupBuilder(
        items: list,
        bloc: bloc,
        service: service,
        onComplete: onComplete,
        onSkip: onSkip,
        autoCompleteWhenSatisfied: autoCompleteWhenSatisfied,
        autoRequest: autoRequest,
        beforeAsk: explainBeforeAsk ? (explainBuilder ?? _explain) : null,
        builder: (context, state, actions) => wizard
            ? PermissionSetupWizard(
                state: state,
                actions: actions,
                strings: strings,
                style: PermissionSetupStyle.select(
                  context,
                  style,
                  desktopStyle,
                ).resolved(context),
                showSkipAll: allowSkip ?? onSkip != null,
                emptyBuilder: emptyBuilder,
                loadingBuilder: loadingBuilder,
              )
            : PermissionSetupView(
                state: state,
                actions: actions,
                strings: strings,
                style: style,
                headerBuilder: headerBuilder,
                itemBuilder: itemBuilder,
                footerBuilder: footerBuilder,
                emptyBuilder: emptyBuilder,
                loadingBuilder: loadingBuilder,
                showSkip: allowSkip ?? onSkip != null,
                forcedLayout: forcedLayout,
                brand: brand,
                onToggleTheme: onToggleTheme,
                illustration: illustration,
                desktopStyle: desktopStyle,
                topBanner: topBanner,
                bottomBanner: bottomBanner,
              ),
      ),
    );
  }
}

/// Scans once (through a [PermissionDetectionCubit]), shows [loading]
/// meanwhile, then calls [builder] with the items. A different configuration
/// gets a different key, so it is scanned again; an equal one is not.
class _DetectedItems extends StatelessWidget {
  const _DetectedItems({
    required this.detection,
    required this.loading,
    required this.builder,
  });

  final PermissionDetection detection;
  final WidgetBuilder loading;
  final Widget Function(BuildContext context, List<PermissionItem> items)
  builder;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey(detection.scanHash),
    create: (_) => PermissionDetectionCubit(detection),
    child: BlocBuilder<PermissionDetectionCubit, PermissionDetectionState>(
      builder: (context, state) => state.isLoading
          ? loading(context)
          : builder(context, state.result!.items),
    ),
  );
}
