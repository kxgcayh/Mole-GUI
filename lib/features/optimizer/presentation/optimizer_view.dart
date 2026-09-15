import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/optimization_task.dart';
import 'optimizer_view_model.dart';

class OptimizerView extends ConsumerWidget {
  const OptimizerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimizerViewModelProvider);
    final viewModel = ref.read(optimizerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Maintenance',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Refresh system caches, flush DNS, rebuild databases, and tune macOS',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tasks List and Logs Split
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tasks Column
                  Expanded(
                    flex: 3,
                    child: ListView.separated(
                      itemCount: state.tasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = state.tasks[index];
                        return _buildTaskCard(task, viewModel);
                      },
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Output Terminal Log Console
                  Expanded(
                    flex: 2,
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(CupertinoIcons.chevron_left_slash_chevron_right,
                                      size: 16, color: AppColors.accentCyan),
                                  SizedBox(width: 8),
                                  Text(
                                    'Console Output',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (state.logs.isNotEmpty)
                                GestureDetector(
                                  onTap: () => viewModel.clearLogs(),
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Expanded(
                            child: state.logs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Run a maintenance task\nto see live output.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: state.logs.length,
                                    itemBuilder: (context, idx) {
                                      final log = state.logs[idx];
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          log,
                                          style: const TextStyle(
                                            fontFamily: 'Courier',
                                            fontSize: 11,
                                            color: AppColors.accentGreen,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(OptimizationTask task, OptimizerViewModel viewModel) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTaskIcon(task.id),
              size: 20,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      task.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (task.isCompleted) ...[
                      const SizedBox(width: 8),
                      const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                          color: AppColors.accentGreen, size: 16),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  task.description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ActionButton(
            label: task.isRunning ? 'Running...' : 'Execute',
            height: 36,
            isLoading: task.isRunning,
            onPressed: task.isRunning ? null : () => viewModel.runTask(task),
          ),
        ],
      ),
    );
  }

  IconData _getTaskIcon(String id) {
    switch (id) {
      case 'flush_dns':
        return CupertinoIcons.wifi;
      case 'purge_ram':
        return CupertinoIcons.memories;
      case 'rebuild_launchservices':
        return CupertinoIcons.arrow_2_squarepath;
      case 'font_cache':
        return CupertinoIcons.textformat;
      default:
        return CupertinoIcons.slider_horizontal_3;
    }
  }
}
