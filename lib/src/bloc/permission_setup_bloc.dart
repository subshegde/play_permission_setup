import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../core/permission_kind.dart';
import '../models/permission_entry.dart';
import '../models/permission_grant.dart';
import '../models/permission_item.dart';
import '../models/platform.dart';
import '../service/permission_handler_service.dart';
import '../service/permission_service.dart';

part 'permission_setup_event.dart';
part 'permission_setup_state.dart';

class PermissionSetupBloc
    extends Bloc<PermissionSetupEvent, PermissionSetupState>
    with WidgetsBindingObserver {
  PermissionSetupBloc({
    required List<PermissionItem> items,
    PermissionService? service,
    PermissionPlatform? platform,
    this.autoRefreshOnResume = true,
    this.autoCompleteWhenSatisfied = false,
    this.autoRequest = false,
    this.beforeAsk,
  }) : _service = service ?? PermissionHandlerService(),
       super(
         PermissionSetupState(
           entries: _prepare(items, platform ?? currentPermissionPlatform()),
         ),
       ) {
    // One system dialog at a time: ignore taps while one is open.
    on<PermissionSetupStarted>(_onRefresh, transformer: restartable());
    on<PermissionSetupRefreshed>(_onRefresh, transformer: restartable());
    on<PermissionRequested>(_onRequested, transformer: droppable());
    on<PermissionAllRequested>(_onAllRequested, transformer: droppable());
    on<PermissionSettingsOpened>(_onSettings, transformer: droppable());
    on<PermissionSetupSkipped>(
      (e, emit) => emit(state.copyWith(status: PermissionSetupStatus.skipped)),
    );
    on<PermissionSetupContinued>(_onContinued);

    if (autoRefreshOnResume) {
      try {
        WidgetsBinding.instance.addObserver(this);
        _observing = true;
      } catch (_) {
        // Binding not initialised (pure Dart tests) – resume refresh is off.
      }
    }
    add(const PermissionSetupStarted());
  }

  final PermissionService _service;
  final bool autoRefreshOnResume;

  /// Skip the page entirely when every required permission is already granted.
  /// Ask for every missing permission automatically when the page opens: the
  /// system dialogs appear one after another, no tap needed. Permissions that
  /// can only be changed in Settings are skipped.
  final bool autoRequest;

  /// Called right before each system dialog. Show your "why we need this"
  /// message and return `true` to go on and ask, or `false` to skip this
  /// permission for now (nothing is requested and it is not counted as a
  /// refusal). The page's `explainBeforeAsk: true` supplies a ready-made one.
  final Future<bool> Function(PermissionItem item)? beforeAsk;
  final bool autoCompleteWhenSatisfied;
  bool _observing = false;

  /// Removes items that don't apply here, de-duplicates and orders items so
  /// dependencies (location) come before dependents (locationAlways).
  static List<PermissionEntry> _prepare(
    List<PermissionItem> items,
    PermissionPlatform platform,
  ) {
    final seen = <PermissionKind>{};
    final applicable = <PermissionItem>[];
    for (final i in items) {
      if (!i.appliesTo(platform)) continue;
      if (!seen.add(i.kind)) continue; // duplicate kind
      applicable.add(i);
    }
    final ordered = <PermissionItem>[];
    final placed = <PermissionKind>{};
    void place(PermissionItem i) {
      if (placed.contains(i.kind)) return;
      for (final dep in i.kind.dependsOn) {
        for (final other in applicable) {
          if (other.kind == dep) place(other);
        }
      }
      placed.add(i.kind);
      ordered.add(i);
    }

    applicable.forEach(place);
    return [for (final i in ordered) PermissionEntry(item: i)];
  }

  // ---- lifecycle -----------------------------------------------------------

  @override
  // ignore: avoid_renaming_method_parameters
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed && !state.isBusy) {
      add(const PermissionSetupRefreshed());
    }
  }

  @override
  Future<void> close() {
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    return super.close();
  }

  // ---- handlers ------------------------------------------------------------

  Future<PermissionEntry> _check(PermissionEntry e) async {
    try {
      final r = await _service.check(e.item.kind);
      return e.copyWith(
        grant: r.grant,
        serviceDisabled: !r.serviceEnabled,
        clearError: true,
      );
    } catch (err) {
      return e.copyWith(grant: PermissionGrant.unknown, error: '$err');
    }
  }

  Future<void> _onRefresh(
    PermissionSetupEvent event,
    Emitter<PermissionSetupState> emit,
  ) async {
    if (state.isBusy) return; // a dialog is open; its result will update us
    final updated = await Future.wait(state.entries.map(_check));
    if (state.isBusy) return;
    final finished =
        state.status == PermissionSetupStatus.completed ||
        state.status == PermissionSetupStatus.skipped;
    var next = state.copyWith(
      status: finished ? state.status : PermissionSetupStatus.ready,
      entries: updated,
      openedSettings: false,
    );
    if (event is PermissionSetupStarted &&
        autoCompleteWhenSatisfied &&
        next.canContinue) {
      next = next.copyWith(status: PermissionSetupStatus.completed);
    }
    emit(next);
    // Open the system dialogs one after another, without waiting for a tap.
    if (event is PermissionSetupStarted &&
        autoRequest &&
        next.status != PermissionSetupStatus.completed &&
        !isClosed) {
      add(const PermissionAllRequested());
    }
  }

  Future<void> _onRequested(
    PermissionRequested event,
    Emitter<PermissionSetupState> emit,
  ) async {
    await _requestOne(event.kind, emit);
    if (!isClosed) {
      emit(state.copyWith(status: PermissionSetupStatus.ready));
    }
  }

  Future<void> _onAllRequested(
    PermissionAllRequested event,
    Emitter<PermissionSetupState> emit,
  ) async {
    for (final kind in [for (final e in state.entries) e.item.kind]) {
      if (isClosed) return;
      final entry = state.entryOf(kind)!;
      if (entry.isSatisfied) continue;
      // Nothing to gain: needs Settings / blocked / its dependency was refused.
      if (entry.grant == PermissionGrant.permanentlyDenied ||
          entry.grant == PermissionGrant.restricted ||
          state.isLocked(entry)) {
        continue;
      }
      await _requestOne(kind, emit);
    }
    if (!isClosed) emit(state.copyWith(status: PermissionSetupStatus.ready));
  }

  Future<void> _requestOne(
    PermissionKind kind,
    Emitter<PermissionSetupState> emit,
  ) async {
    final before = state.entryOf(kind);
    if (before == null || before.isSatisfied) return;
    if (state.isLocked(before)) return;

    _replace(
      emit,
      kind,
      (e) => e.copyWith(isRequesting: true, clearError: true),
      status: PermissionSetupStatus.requesting,
    );
    final explain = beforeAsk;
    if (explain != null) {
      var go = false;
      try {
        go = await explain(before.item);
      } catch (_) {
        go = false;
      }
      if (!go || isClosed) {
        _replace(
          emit,
          kind,
          (e) => e.copyWith(isRequesting: false),
          status: PermissionSetupStatus.ready,
        );
        return;
      }
    }
    try {
      final r = await _service.request(kind);
      _replace(
        emit,
        kind,
        (e) => e.copyWith(
          grant: r.grant,
          serviceDisabled: !r.serviceEnabled,
          attempts: e.attempts + 1,
          isRequesting: false,
        ),
      );
    } catch (err) {
      _replace(
        emit,
        kind,
        (e) => e.copyWith(isRequesting: false, error: '$err'),
      );
    }
  }

  void _replace(
    Emitter<PermissionSetupState> emit,
    PermissionKind kind,
    PermissionEntry Function(PermissionEntry) f, {
    PermissionSetupStatus? status,
  }) {
    if (isClosed) return;
    emit(
      state.copyWith(
        status: status,
        entries: [
          for (final e in state.entries) e.item.kind == kind ? f(e) : e,
        ],
      ),
    );
  }

  Future<void> _onSettings(
    PermissionSettingsOpened event,
    Emitter<PermissionSetupState> emit,
  ) async {
    final ok = await _service.openSettings();
    if (ok && !isClosed) emit(state.copyWith(openedSettings: true));
  }

  void _onContinued(
    PermissionSetupContinued event,
    Emitter<PermissionSetupState> emit,
  ) {
    if (state.canContinue) {
      emit(state.copyWith(status: PermissionSetupStatus.completed));
    }
  }
}
