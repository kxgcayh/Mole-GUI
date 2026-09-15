import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/purge_item.dart';

enum PurgeStatus { idle, scanning, scanned, purging }

class PurgeState {
  final PurgeStatus status;
  final List<PurgeItem> items;
  final List<String> searchPaths;
  final double progress;
  final String currentProgressMessage;

  const PurgeState({
    this.status = PurgeStatus.idle,
    this.items = const [],
    this.searchPaths = const [],
    this.progress = 0.0,
    this.currentProgressMessage = '',
  });

  int get totalSizeBytes => items.fold<int>(0, (sum, i) => sum + i.sizeBytes);
  int get selectedSizeBytes =>
      items.where((i) => i.isChecked).fold<int>(0, (sum, i) => sum + i.sizeBytes);

  PurgeState copyWith({
    PurgeStatus? status,
    List<PurgeItem>? items,
    List<String>? searchPaths,
    double? progress,
    String? currentProgressMessage,
  }) {
    return PurgeState(
      status: status ?? this.status,
      items: items ?? this.items,
      searchPaths: searchPaths ?? this.searchPaths,
      progress: progress ?? this.progress,
      currentProgressMessage:
          currentProgressMessage ?? this.currentProgressMessage,
    );
  }
}

class PurgeViewModel extends Notifier<PurgeState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  PurgeState build() {
    final home = _cliService.homeDir;
    final defaultRoots = [
      '$home/Projects',
      '$home/Developer',
      '$home/Documents',
      '$home/Desktop',
    ].where((p) => Directory(p).existsSync()).toList();

    Future.microtask(() => scan());
    return PurgeState(searchPaths: defaultRoots);
  }

  Future<void> scan() async {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: PurgeStatus.scanning,
      currentProgressMessage: 'Scanning developer project build artifacts...',
      progress: 0.1,
    );

    try {
      final items = await _cliService.scanProjectBuildArtifacts(state.searchPaths);
      if (!ref.mounted) return;
      state = state.copyWith(
        status: PurgeStatus.scanned,
        items: items,
        progress: 1.0,
      );
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: PurgeStatus.idle);
    }
  }

  void toggleItemCheck(String id, bool isChecked) {
    if (!ref.mounted) return;
    state = state.copyWith(
      items: state.items.map((i) {
        if (i.id == id) {
          return i.copyWith(isChecked: isChecked);
        }
        return i;
      }).toList(),
    );
  }

  void toggleAll(bool isChecked) {
    if (!ref.mounted) return;
    state = state.copyWith(
      items: state.items.map((i) => i.copyWith(isChecked: isChecked)).toList(),
    );
  }

  Future<void> purgeSelected() async {
    final selected = state.items.where((i) => i.isChecked).toList();
    if (selected.isEmpty) return;

    if (!ref.mounted) return;
    state = state.copyWith(
      status: PurgeStatus.purging,
      currentProgressMessage: 'Purging build artifacts...',
      progress: 0.0,
    );

    int count = 0;
    for (final item in selected) {
      count++;
      if (!ref.mounted) return;
      state = state.copyWith(
        currentProgressMessage: 'Deleting ${item.name} in ${item.projectPath.split('/').last}...',
        progress: count / selected.length,
      );

      try {
        final d = Directory(item.path);
        if (d.existsSync()) {
          await d.delete(recursive: true);
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 20));
    }

    if (!ref.mounted) return;
    state = state.copyWith(status: PurgeStatus.scanned);
    await scan();
  }
}

final purgeViewModelProvider =
    NotifierProvider<PurgeViewModel, PurgeState>(
  PurgeViewModel.new,
);
