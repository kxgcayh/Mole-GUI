import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/installer_file.dart';

enum InstallerStatus { idle, scanning, scanned, cleaning }

class InstallerState {
  final InstallerStatus status;
  final List<InstallerFile> files;
  final double progress;

  const InstallerState({
    this.status = InstallerStatus.idle,
    this.files = const [],
    this.progress = 0.0,
  });

  int get totalSizeBytes => files.fold<int>(0, (sum, f) => sum + f.sizeBytes);
  int get selectedSizeBytes =>
      files.where((f) => f.isChecked).fold<int>(0, (sum, f) => sum + f.sizeBytes);

  InstallerState copyWith({
    InstallerStatus? status,
    List<InstallerFile>? files,
    double? progress,
  }) {
    return InstallerState(
      status: status ?? this.status,
      files: files ?? this.files,
      progress: progress ?? this.progress,
    );
  }
}

class InstallerViewModel extends Notifier<InstallerState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  InstallerState build() {
    Future.microtask(() => scan());
    return const InstallerState();
  }

  Future<void> scan() async {
    if (!ref.mounted) return;
    state = state.copyWith(status: InstallerStatus.scanning, progress: 0.2);
    try {
      final files = await _cliService.scanInstallers();
      if (!ref.mounted) return;
      state = state.copyWith(status: InstallerStatus.scanned, files: files, progress: 1.0);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(status: InstallerStatus.idle);
    }
  }

  void toggleItemCheck(String id, bool isChecked) {
    if (!ref.mounted) return;
    state = state.copyWith(
      files: state.files.map((f) {
        if (f.id == id) {
          return f.copyWith(isChecked: isChecked);
        }
        return f;
      }).toList(),
    );
  }

  Future<void> cleanSelected() async {
    final selected = state.files.where((f) => f.isChecked).toList();
    if (selected.isEmpty) return;

    if (!ref.mounted) return;
    state = state.copyWith(status: InstallerStatus.cleaning);
    for (final item in selected) {
      try {
        final f = File(item.path);
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (_) {}
    }
    if (!ref.mounted) return;
    await scan();
  }
}

final installerViewModelProvider =
    NotifierProvider<InstallerViewModel, InstallerState>(
  InstallerViewModel.new,
);
