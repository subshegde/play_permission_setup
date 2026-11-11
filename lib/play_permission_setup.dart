/// Permission setup page + BLoC for Flutter (mobile, tablet, desktop).
///
/// The build-time scanner lives in `package:play_permission_setup/scanner.dart`
/// (pure Dart, run via `dart run play_permission_setup`).
library;

export 'src/bloc/permission_detection_cubit.dart';
export 'src/bloc/permission_setup_bloc.dart';
export 'src/core/permission_kind.dart';
export 'src/models/permission_entry.dart';
export 'src/models/permission_grant.dart';
export 'src/models/permission_item.dart';
export 'src/models/platform.dart' show currentPermissionPlatform;
export 'src/service/permission_detector.dart'
    show
        DeclaredPermissions,
        DetectionResult,
        PermissionDetection,
        PermissionDetector,
        PlatformPermissionDetector,
        detectPermissions;
export 'src/service/permission_handler_service.dart';
export 'src/service/permission_service.dart';
export 'src/ui/permission_defaults.dart';
export 'src/ui/permission_setup_actions.dart';
export 'src/ui/permission_setup_builder.dart';
export 'src/ui/permission_setup_footer.dart';
export 'src/ui/permission_setup_header.dart';
export 'src/ui/permission_setup_hero.dart';
export 'src/ui/permission_setup_page.dart';
export 'src/ui/permission_setup_strings.dart';
export 'src/ui/permission_setup_style.dart';
export 'src/ui/permission_setup_view.dart';
export 'src/ui/permission_setup_wizard.dart';
export 'src/ui/permission_setup_workstation.dart';
export 'src/ui/permission_tile.dart';
