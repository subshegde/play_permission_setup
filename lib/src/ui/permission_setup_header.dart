import 'package:flutter/material.dart';

import '../bloc/permission_setup_bloc.dart';
import 'permission_setup_strings.dart';
import 'permission_setup_style.dart';

/// Default header: title, one-line subtitle and a slim progress bar.
class PermissionSetupHeader extends StatelessWidget {
  const PermissionSetupHeader({
    super.key,
    required this.state,
    this.strings = const PermissionSetupStrings(),
    this.style = const PermissionSetupStyle(),
    this.trailing,
  });

  /// Current setup state (drives the progress bar).
  final PermissionSetupState state;

  /// Texts shown by the header.
  final PermissionSetupStrings strings;

  /// Colours and text styles used by the header.
  final PermissionSetupStyle style;

  /// Widget at the top-right, e.g. a Skip button.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final style = this.style.resolved(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  strings.title,
                  style:
                      style.titleStyle ??
                      theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: 2),
        Text(
          strings.subtitle,
          style:
              style.subtitleStyle ??
              theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
        ),
        if (style.showProgress && state.total > 0) ...[
          const SizedBox(height: 14),
          Semantics(
            label: strings.progress(state.grantedCount, state.total),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: state.isLoading ? null : state.progress,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${state.grantedCount}/${state.total}',
                  style: theme.textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
