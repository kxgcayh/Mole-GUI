import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/widgets/macos_sidebar.dart';
import '../features/analyze/presentation/analyze_view.dart';
import '../features/cleaner/presentation/cleaner_view.dart';
import '../features/dashboard/presentation/dashboard_view.dart';
import '../features/installer_cleaner/presentation/installer_view.dart';
import '../features/optimizer/presentation/optimizer_view.dart';
import '../features/purge/presentation/purge_view.dart';
import '../features/setup/presentation/setup_view.dart';
import '../features/setup/presentation/setup_view_model.dart';
import '../features/uninstaller/presentation/uninstaller_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final setupState = ref.watch(setupViewModelProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      final isSetupRoute = state.matchedLocation == '/setup';
      final hasCli = setupState.isCliFound;
      final isSkipped = setupState.isSkipped;

      // Middleware: Redirect fresh install users to setup if CLI is missing
      if (!hasCli && !isSkipped) {
        return isSetupRoute ? null : '/setup';
      }

      // If CLI is detected or user opted to skip, leave setup page
      if (isSetupRoute && (hasCli || isSkipped)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/setup',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SetupView(),
        ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Scaffold(
            backgroundColor: AppColors.darkBg,
            body: Row(
              children: [
                MacosSidebar(
                  currentRoute: state.uri.path,
                  onSelectRoute: (route) => context.go(route),
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardView(),
            ),
          ),
          GoRoute(
            path: '/analyze',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyzeView(),
            ),
          ),
          GoRoute(
            path: '/cleaner',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CleanerView(),
            ),
          ),
          GoRoute(
            path: '/uninstaller',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UninstallerView(),
            ),
          ),
          GoRoute(
            path: '/purge',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PurgeView(),
            ),
          ),
          GoRoute(
            path: '/optimizer',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OptimizerView(),
            ),
          ),
          GoRoute(
            path: '/installers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InstallerView(),
            ),
          ),
        ],
      ),
    ],
  );
});
