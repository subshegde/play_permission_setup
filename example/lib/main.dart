import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:play_permission_setup/play_permission_setup.dart';

void main() => runApp(const PlaygroundApp());

/// The looks this demo can switch between.
const looks = <(String, PermissionSetupStyle)>[
  ('Crimson', PermissionSetupStyle.crimson),
  ('Clinical teal', PermissionSetupStyle.clinical),
  ('Classic list', PermissionSetupStyle()),
];

/// App-level UI state (theme and look). Kept in a Cubit:
class AppState extends Equatable {
  const AppState({this.themeMode = ThemeMode.light, this.look = 0});

  final ThemeMode themeMode;
  final int look;

  AppState copyWith({ThemeMode? themeMode, int? look}) =>
      AppState(themeMode: themeMode ?? this.themeMode, look: look ?? this.look);

  @override
  List<Object?> get props => [themeMode, look];
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState());

  void toggleTheme() => emit(
    state.copyWith(
      themeMode: state.themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark,
    ),
  );

  void nextLook() =>
      emit(state.copyWith(look: (state.look + 1) % looks.length));
}

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AppCubit(),
    child: BlocBuilder<AppCubit, AppState>(
      buildWhen: (a, b) => a.themeMode != b.themeMode,
      builder: (context, app) => MaterialApp(
        title: 'Permission setup demo',
        debugShowCheckedModeBanner: false,
        themeMode: app.themeMode,
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: const Gate(),
      ),
    ),
  );
}

class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final look = context.select((AppCubit c) => c.state.look);
    final (lookName, style) = looks[look];
    final cubit = context.read<AppCubit>();

    void goHome(PermissionSetupState _) => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const Home()));

    return PermissionSetupPage(
      // Rebuild the bloc-owning page when the look changes.
      key: ValueKey(lookName),
      // No list: the page scans the app's manifest / Info.plist by itself.
      detection: const PermissionDetection(
        requiredKinds: {PermissionKind.camera},
      ),
      onComplete: goHome,
      onSkip: goHome,
      style: style,
      // Windows, macOS, Linux and wide web get the workstation layout.
      desktopStyle: PermissionSetupStyle.workstation,
      onToggleTheme: cubit.toggleTheme,
      brand: PermissionSetupBrand(
        appName: 'Lumio',
        badge: 'Setup',
        caption: 'Look: $lookName · tap logo to switch',
        chip: 'play_permission_setup v0.1.0',
        navItems: const ['Overview', 'Permissions'],
        logo: GestureDetector(
          onTap: cubit.nextLook,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.accentColor ?? Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
        ),
      ),
      strings: const PermissionSetupStrings(
        title: "Let's get things ready",
        titleHighlight: 'ready',
        subtitle:
            'Allow a few permissions to unlock all the features and get the best experience from the application.',
        footerNote: 'You can manage permissions anytime in Settings.',
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Home')),
    body: Center(
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Back to permission setup'),
      ),
    ),
  );
}
