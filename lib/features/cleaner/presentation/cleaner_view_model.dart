import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/clean_category.dart';
import '../domain/clean_item.dart';

enum CleanerStatus { idle, scanning, scanned, cleaning, finished }

class CleanerState {
  final CleanerStatus status;
  final List<CleanCategory> categories;
  final String currentProgressMessage;
  final double progress;
  final int lastCleanedBytes;
  final String? errorMessage;

  const CleanerState({
    this.status = CleanerStatus.idle,
    this.categories = const [],
    this.currentProgressMessage = '',
    this.progress = 0.0,
    this.lastCleanedBytes = 0,
    this.errorMessage,
  });

  int get totalScannedBytes =>
      categories.fold<int>(0, (sum, cat) => sum + cat.totalSizeBytes);

  int get totalSelectedBytes =>
      categories.fold<int>(0, (sum, cat) => sum + cat.selectedSizeBytes);

  int get selectedCount => categories.fold<int>(
      0, (sum, cat) => sum + cat.items.where((i) => i.isChecked).length);

  CleanerState copyWith({
    CleanerStatus? status,
    List<CleanCategory>? categories,
    String? currentProgressMessage,
    double? progress,
    int? lastCleanedBytes,
    String? errorMessage,
  }) {
    return CleanerState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      currentProgressMessage:
          currentProgressMessage ?? this.currentProgressMessage,
      progress: progress ?? this.progress,
      lastCleanedBytes: lastCleanedBytes ?? this.lastCleanedBytes,
      errorMessage: errorMessage,
    );
  }
}

class CleanerViewModel extends Notifier<CleanerState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  CleanerState build() {
    Future.microtask(() => scan());
    return const CleanerState();
  }

  Future<void> scan() async {
    if (!ref.mounted) return;
    state = state.copyWith(
      status: CleanerStatus.scanning,
      currentProgressMessage: 'Scanning caches, logs, and leftovers...',
      progress: 0.1,
    );

    try {
      final categories = await _cliService.scanSystemCleanables();
      if (!ref.mounted) return;
      state = state.copyWith(
        status: CleanerStatus.scanned,
        categories: categories,
        progress: 1.0,
        currentProgressMessage: 'Scan complete',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: CleanerStatus.idle,
        errorMessage: 'Scan failed: $e',
      );
    }
  }

  void toggleCategoryExpand(String categoryId) {
    if (!ref.mounted) return;
    state = state.copyWith(
      categories: state.categories.map((cat) {
        if (cat.id == categoryId) {
          return cat.copyWith(isExpanded: !cat.isExpanded);
        }
        return cat;
      }).toList(),
    );
  }

  void toggleCategoryCheck(String categoryId, bool isChecked) {
    if (!ref.mounted) return;
    state = state.copyWith(
      categories: state.categories.map((cat) {
        if (cat.id == categoryId) {
          final updatedItems =
              cat.items.map((item) => item.copyWith(isChecked: isChecked)).toList();
          return cat.copyWith(items: updatedItems);
        }
        return cat;
      }).toList(),
    );
  }

  void toggleItemCheck(String categoryId, String itemId, bool isChecked) {
    if (!ref.mounted) return;
    state = state.copyWith(
      categories: state.categories.map((cat) {
        if (cat.id == categoryId) {
          final updatedItems = cat.items.map((item) {
            if (item.id == itemId) {
              return item.copyWith(isChecked: isChecked);
            }
            return item;
          }).toList();
          return cat.copyWith(items: updatedItems);
        }
        return cat;
      }).toList(),
    );
  }

  Future<void> cleanSelected() async {
    final selectedItems = <CleanItem>[];
    for (final cat in state.categories) {
      selectedItems.addAll(cat.items.where((i) => i.isChecked));
    }

    if (selectedItems.isEmpty) return;

    final bytesToClean = state.totalSelectedBytes;

    if (!ref.mounted) return;
    state = state.copyWith(
      status: CleanerStatus.cleaning,
      progress: 0.0,
      currentProgressMessage: 'Starting cleanup...',
    );

    try {
      await _cliService.executeCleanup(
        selectedItems,
        (msg, prog) {
          if (!ref.mounted) return;
          state = state.copyWith(
            currentProgressMessage: msg,
            progress: prog,
          );
        },
      );

      if (!ref.mounted) return;
      state = state.copyWith(
        status: CleanerStatus.finished,
        lastCleanedBytes: bytesToClean,
      );

      // Re-scan after short delay
      await Future.delayed(const Duration(seconds: 1));
      if (!ref.mounted) return;
      await scan();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: CleanerStatus.scanned,
        errorMessage: 'Cleanup error: $e',
      );
    }
  }
}

final cleanerViewModelProvider =
    NotifierProvider<CleanerViewModel, CleanerState>(
  CleanerViewModel.new,
);
