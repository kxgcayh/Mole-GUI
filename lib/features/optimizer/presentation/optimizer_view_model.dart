import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/optimization_task.dart';

class OptimizerState {
  final List<OptimizationTask> tasks;
  final List<String> logs;

  const OptimizerState({
    this.tasks = const [],
    this.logs = const [],
  });

  OptimizerState copyWith({
    List<OptimizationTask>? tasks,
    List<String>? logs,
  }) {
    return OptimizerState(
      tasks: tasks ?? this.tasks,
      logs: logs ?? this.logs,
    );
  }
}

class OptimizerViewModel extends Notifier<OptimizerState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  OptimizerState build() {
    return const OptimizerState(
      tasks: [
        OptimizationTask(
          id: 'flush_dns',
          name: 'Flush DNS Cache',
          description: 'Clear macOS DNS resolver cache to fix network connection issues',
          iconName: 'wifi',
        ),
        OptimizationTask(
          id: 'purge_ram',
          name: 'Purge Inactive RAM',
          description: 'Force macOS to flush inactive disk cache pages from physical memory',
          iconName: 'memorychip',
        ),
        OptimizationTask(
          id: 'rebuild_launchservices',
          name: 'Rebuild LaunchServices Database',
          description: 'Fix duplicate apps in "Open With" contextual menus and default handlers',
          iconName: 'arrow_2_squarepath',
        ),
        OptimizationTask(
          id: 'font_cache',
          name: 'Clear Font Cache',
          description: 'Reset system font database to resolve text rendering glitches',
          iconName: 'textformat',
        ),
      ],
    );
  }

  Future<void> runTask(OptimizationTask task) async {
    _updateTask(task.id, isRunning: true, isCompleted: false);
    _addLog('Executing "${task.name}"...');

    try {
      await _cliService.runOptimization(task, (log) {
        _addLog(log);
      });
      _updateTask(task.id, isRunning: false, isCompleted: true);
      _addLog('✓ ${task.name} completed.');
    } catch (e) {
      _updateTask(task.id, isRunning: false, isCompleted: false);
      _addLog('✗ ${task.name} failed: $e');
    }
  }

  void _updateTask(String id, {required bool isRunning, required bool isCompleted}) {
    if (!ref.mounted) return;
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id == id) {
          return t.copyWith(isRunning: isRunning, isCompleted: isCompleted);
        }
        return t;
      }).toList(),
    );
  }

  void _addLog(String msg) {
    if (!ref.mounted) return;
    state = state.copyWith(
      logs: [...state.logs, '[${DateTime.now().toIso8601String().split('T').last.substring(0, 8)}] $msg'],
    );
  }

  void clearLogs() {
    if (!ref.mounted) return;
    state = state.copyWith(logs: []);
  }
}

final optimizerViewModelProvider =
    NotifierProvider<OptimizerViewModel, OptimizerState>(
  OptimizerViewModel.new,
);
