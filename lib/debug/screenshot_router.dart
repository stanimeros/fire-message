import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../screens/create_app_screen.dart';
import '../screens/main_screen.dart';
import 'demo_data.dart';

/// Debug-only routes for `firemessage://shot/<id>` deep links, driven by
/// `appstoresuite auto-capture` (see app_store_suite.yaml's `shots:`) and handy
/// for manual review. Flutter dispatches `firemessage://shot/apps` as route
/// "/apps". Each route seeds demo data (see DemoData) and lands on a screen.
///
/// Only registered via `onGenerateRoute: kDebugMode ? ... : null` in main.dart.
/// Splash race: PaywallGate never navigates (it swaps its own build output),
/// so it cannot clobber a route pushed on top of it by this router.
class ScreenshotRouter {
  /// Navigator of the app's MaterialApp (debug builds only), so
  /// [startRouteFileWatcher] can push routes without a BuildContext.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Timer? _routeFileTimer;

  /// Alternative to the deep link itself for iOS simulators: auto-capture
  /// (`auto_capture.ios_route_file`) writes the `firemessage://shot/...` URL
  /// into this file in the app's tmp dir instead of `simctl openurl`, which on
  /// Xcode 27 shows an "Open in Fire Message?" sheet nobody can script a tap
  /// on. Polls it and pushes the same route a deep link would. Debug only.
  static void startRouteFileWatcher() {
    if (!kDebugMode || _routeFileTimer != null) return;
    final file = File('${Directory.systemTemp.path}/appstoresuite_route');
    _routeFileTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      if (!file.existsSync()) return;
      final url = file.readAsStringSync().trim();
      file.deleteSync();
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      // Same name Flutter's deep-link handling gives onGenerateRoute
      // (the `shot` host is dropped): e.g. "/apps".
      final name = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      navigatorKey.currentState?.pushNamed(name);
    });
  }

  static Route<void>? onGenerateRoute(RouteSettings settings) {
    if (!kDebugMode || settings.name == null) return null;
    final uri = Uri.parse(settings.name!);

    Widget screen;
    switch (uri.path) {
      case '/apps':
      case '/seed':
        screen = const MainScreen();
        break;
      case '/create_notification':
        screen = MainScreen(
          initialIndex: 1,
          demoNotification: DemoData.createPrefill(),
        );
        break;
      case '/targeting':
        screen = MainScreen(
          initialIndex: 1,
          demoNotification: DemoData.createPrefill(useCondition: true),
          demoOpenTargetSelector: true,
        );
        break;
      case '/history':
        screen = const MainScreen(initialIndex: 2);
        break;
      case '/security':
        screen = CreateAppScreen(
          demoName: 'Acme Shop',
          demoPackage: 'com.acme.shop',
          demoServiceAccount: DemoData.fakeServiceAccount('acme-shop'),
          demoAccepted: true,
        );
        break;
      default:
        return null;
    }

    return MaterialPageRoute(
      settings: settings,
      builder: (context) => _Prepared(prepare: DemoData.seed, child: screen),
    );
  }
}

/// Runs [prepare] exactly once (cached in [State], not rebuilt on every
/// build), then shows [child]. [prepare] may trigger a locale change that
/// notifies listeners and rebuilds this widget's ancestors — calling
/// [prepare] again on every build would re-trigger that and loop.
///
/// If you need a BuildContext inside `prepare` (e.g. for `precacheImage`,
/// see gotcha #6 above), change the signature to
/// `Future<void> Function(BuildContext)` and call `widget.prepare(context)`
/// in `_PreparedState` below instead.
class _Prepared extends StatefulWidget {
  const _Prepared({required this.prepare, required this.child});

  final Future<void> Function() prepare;
  final Widget child;

  @override
  State<_Prepared> createState() => _PreparedState();
}

class _PreparedState extends State<_Prepared> {
  late final Future<void> _future = widget.prepare();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return widget.child;
      },
    );
  }
}