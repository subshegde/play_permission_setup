import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/permission_setup_bloc.dart';
import '../models/permission_item.dart';
import '../service/permission_service.dart';
import 'permission_setup_actions.dart';

/// Hosts the [PermissionSetupBloc] and hands you state + actions. Use it to
/// build a completely custom UI:
///
/// ```dart
/// final result = await detectPermissions();
/// PermissionSetupBuilder(
///   items: result.items,
///   onComplete: (_) => goHome(),
///   builder: (context, state, actions) => MyOwnPage(state, actions),
/// )
/// ```
///
/// The bloc is provided with a [BlocProvider]: it is created for you and
/// closed when the widget leaves the tree. If [items] (or [service]) change, a
/// new bloc is created. A bloc you pass in through [bloc] is never closed here.
class PermissionSetupBuilder extends StatelessWidget {
  const PermissionSetupBuilder({
    super.key,
    this.items = const [],
    this.bloc,
    this.service,
    this.onComplete,
    this.onSkip,
    this.autoCompleteWhenSatisfied = false,
    this.autoRequest = false,
    required this.builder,
  });

  final List<PermissionItem> items;

  /// Supply your own bloc (you then own its lifecycle).
  final PermissionSetupBloc? bloc;
  final PermissionService? service;
  final void Function(PermissionSetupState state)? onComplete;
  final void Function(PermissionSetupState state)? onSkip;
  final bool autoCompleteWhenSatisfied;

  /// See [PermissionSetupBloc.autoRequest].
  final bool autoRequest;
  final Widget Function(
    BuildContext context,
    PermissionSetupState state,
    PermissionSetupActions actions,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    final child = BlocConsumer<PermissionSetupBloc, PermissionSetupState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == PermissionSetupStatus.completed) {
          onComplete?.call(state);
        } else if (state.status == PermissionSetupStatus.skipped) {
          onSkip?.call(state);
        }
      },
      builder: (context, state) => builder(
        context,
        state,
        PermissionSetupActions(context.read<PermissionSetupBloc>()),
      ),
    );

    final external = bloc;
    if (external != null) {
      return BlocProvider<PermissionSetupBloc>.value(
        value: external,
        child: child,
      );
    }
    return BlocProvider<PermissionSetupBloc>(
      // A different list / service / mode gives a different key: the old bloc
      // is closed and a new one created.
      key: ValueKey(
        Object.hash(
          Object.hashAll(items),
          service,
          autoCompleteWhenSatisfied,
          autoRequest,
        ),
      ),
      create: (_) => PermissionSetupBloc(
        items: items,
        service: service,
        autoCompleteWhenSatisfied: autoCompleteWhenSatisfied,
        autoRequest: autoRequest,
      ),
      child: child,
    );
  }
}
