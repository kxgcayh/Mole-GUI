import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/app_info.dart';

enum UninstallerStatus { idle, scanning, scanned, uninstalling }

class UninstallerState {
  final UninstallerStatus status;
  final List<AppInfo> apps;
  final String searchQuery;
  final String currentProgressMessage;
  final double progress;
  final AppInfo? selectedApp;

  const UninstallerState({
    this.status = UninstallerStatus.idle,
    this.apps = const [],
    this.searchQuery = '',
    this.currentProgressMessage = '',
    this.progress = 0.0,
    this.selectedApp,
  });

  List<AppInfo> get filteredApps {
    if (searchQuery.trim().isEmpty) return apps;
    final q = searchQuery.toLowerCase();
    return apps.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  UninstallerState copyWith({
    UninstallerStatus? status,
    List<AppInfo>? apps,
    String? searchQuery,
    String? currentProgressMessage,
    double? progress,
    AppInfo? selectedApp,
    bool clearSelectedApp = false,
  }) {
    return UninstallerState(
      status: status ?? this.status,
      apps: apps ?? this.apps,
      searchQuery: searchQuery ?? this.searchQuery,
      currentProgressMessage:
          currentProgressMessage ?? this.currentProgressMessage,
      progress: progress ?? this.progress,
      selectedApp: clearSelectedApp ? null : (selectedApp ?? this.selectedApp),
    );
  }
}

class UninstallerViewModel extends Notifier<UninstallerState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  UninstallerState build() {
    Future.microtask(() => scan());
    return const UninstallerState();
  }

  Future<void> scan() async {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: UninstallerStatus.scanning,
      currentProgressMessage: 'Scanning installed applications...',
      progress: 0.2,
    );

    try {
      final apps = await _cliService.scanInstalledApps();
      if (!ref.mounted) return;
      state = state.copyWith(
        status: UninstallerStatus.scanned,
        apps: apps,
        progress: 1.0,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(status: UninstallerStatus.idle);
    }
  }

  void setSearchQuery(String query) {
    if (!ref.mounted) return;
    state = state.copyWith(searchQuery: query);
  }

  void selectApp(AppInfo? app) {
    if (!ref.mounted) return;
    state = state.copyWith(selectedApp: app, clearSelectedApp: app == null);
  }

  Future<void> uninstall(AppInfo app) async {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: UninstallerStatus.uninstalling,
      progress: 0.0,
      currentProgressMessage: 'Uninstalling ${app.name}...',
    );

    try {
      await _cliService.uninstallApp(app, (msg, prog) {
        if (!ref.mounted) return;
        state = state.copyWith(
          currentProgressMessage: msg,
          progress: prog,
        );
      });
      if (!ref.mounted) return;
      state = state.copyWith(
        status: UninstallerStatus.scanned,
        clearSelectedApp: true,
      );
      await scan();
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: UninstallerStatus.scanned);
    }
  }
}

final uninstallerViewModelProvider =
    NotifierProvider<UninstallerViewModel, UninstallerState>(
  UninstallerViewModel.new,
);
