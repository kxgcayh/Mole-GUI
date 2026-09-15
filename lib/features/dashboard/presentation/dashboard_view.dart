import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/circular_gauge.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/system_metrics.dart';
import 'dashboard_view_model.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Overview',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Live performance telemetry & system health',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ActionButton(
                      label: 'Smart Clean',
                      icon: CupertinoIcons.sparkles,
                      gradient: AppColors.cleanGradient,
                      onPressed: () => context.go('/cleaner'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 1. Live Hardware Telemetry Gauges Card (CPU, RAM, Disk, Battery)
                metricsAsync.when(
                  data: (metrics) => _buildTelemetryCard(metrics, constraints.maxWidth),
                  loading: () => _buildTelemetryCard(SystemMetrics.initial(), constraints.maxWidth),
                  error: (err, _) => GlassCard(
                    child: Center(
                      child: Text(
                        'Error reading hardware status: $err',
                        style: const TextStyle(color: AppColors.accentRed),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Live System Diagnostics (Load, I/O, Top Processes)
                metricsAsync.maybeWhen(
                  data: (metrics) => _buildSystemDiagnosticsSection(metrics, isNarrow),
                  orElse: () => _buildSystemDiagnosticsSection(SystemMetrics.initial(), isNarrow),
                ),
                const SizedBox(height: 20),

                // 3. Secondary Cards (Quick Actions & Storage Breakdown)
                if (isNarrow) ...[
                  _buildQuickActionsCard(context),
                  const SizedBox(height: 20),
                  metricsAsync.maybeWhen(
                    data: (metrics) => _buildStorageSummaryCard(metrics),
                    orElse: () => _buildStorageSummaryCard(SystemMetrics.initial()),
                  ),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildQuickActionsCard(context)),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: metricsAsync.maybeWhen(
                          data: (metrics) => _buildStorageSummaryCard(metrics),
                          orElse: () => _buildStorageSummaryCard(SystemMetrics.initial()),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTelemetryCard(SystemMetrics metrics, double availableWidth) {
    final gaugeSize = (availableWidth < 550) ? 90.0 : 110.0;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Telemetry',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: AppColors.accentGreen, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Uptime: ${metrics.uptime}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.spaceAround,
            runAlignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              CircularGauge(
                size: gaugeSize,
                value: metrics.cpuUsagePercent,
                label: 'CPU Load',
                sublabel:
                    '${metrics.cpuUserPercent.toStringAsFixed(1)}% u · ${metrics.cpuSysPercent.toStringAsFixed(1)}% s',
                gradientColors: AppColors.cpuGradient,
              ),
              CircularGauge(
                size: gaugeSize,
                value: metrics.memoryUsagePercent,
                label: 'RAM Usage',
                sublabel:
                    '${ByteFormatter.format(metrics.usedMemoryBytes, decimals: 0)} / ${ByteFormatter.format(metrics.totalMemoryBytes, decimals: 0)}',
                gradientColors: AppColors.ramGradient,
              ),
              CircularGauge(
                size: gaugeSize,
                value: metrics.diskUsagePercent,
                label: 'Disk Space',
                sublabel: '${ByteFormatter.format(metrics.usedDiskBytes, decimals: 0)} used',
                gradientColors: AppColors.diskGradient,
              ),
              if (metrics.hasBattery)
                CircularGauge(
                  size: gaugeSize,
                  value: metrics.batteryPercentage.toDouble(),
                  label: 'Battery',
                  sublabel: metrics.isCharging ? 'Charging ⚡' : 'Discharging',
                  gradientColors: AppColors.cleanGradient,
                ),
            ],
          ),
          if (metrics.appMemoryBytes > 0) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.darkBg.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMemStatItem('App Memory', ByteFormatter.format(metrics.appMemoryBytes, decimals: 1), AppColors.primaryLight),
                  _buildMemDivider(),
                  _buildMemStatItem('Wired', ByteFormatter.format(metrics.wiredMemoryBytes, decimals: 1), AppColors.accentCyan),
                  _buildMemDivider(),
                  _buildMemStatItem('Compressed', ByteFormatter.format(metrics.compressedMemoryBytes, decimals: 1), AppColors.accentOrange),
                  _buildMemDivider(),
                  _buildMemStatItem('Cached Files', ByteFormatter.format(metrics.cachedMemoryBytes, decimals: 1), AppColors.accentGreen),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemDiagnosticsSection(SystemMetrics metrics, bool isNarrow) {
    if (isNarrow) {
      return Column(
        children: [
          _buildSystemLoadCard(metrics),
          const SizedBox(height: 16),
          _buildTopProcessesCard(metrics),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSystemLoadCard(metrics)),
        const SizedBox(width: 20),
        Expanded(child: _buildTopProcessesCard(metrics)),
      ],
    );
  }

  Widget _buildSystemLoadCard(SystemMetrics metrics) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.waveform_path_ecg, color: AppColors.accentCyan, size: 18),
              SizedBox(width: 8),
              Text(
                'System Activity & I/O',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Load Averages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Load Averages', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _buildLoadBadge('1m', metrics.loadAverages.isNotEmpty ? metrics.loadAverages[0] : 1.0),
                    _buildLoadBadge('5m', metrics.loadAverages.length > 1 ? metrics.loadAverages[1] : 1.0),
                    _buildLoadBadge('15m', metrics.loadAverages.length > 2 ? metrics.loadAverages[2] : 1.0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Processes & Threads
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Tasks', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${metrics.totalProcesses} total · ${metrics.runningProcesses} running · ${metrics.totalThreads} threads',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontFamily: 'Menlo', fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Network Traffic Cumulative
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Network I/O', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.arrow_down, size: 12, color: AppColors.accentGreen),
                    Flexible(
                      child: Text(' ${metrics.networkIn}  ',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontFamily: 'Menlo', color: AppColors.textPrimary)),
                    ),
                    const Icon(CupertinoIcons.arrow_up, size: 12, color: AppColors.accentOrange),
                    Flexible(
                      child: Text(' ${metrics.networkOut}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontFamily: 'Menlo', color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Disk I/O Cumulative
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Disk Transfers', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '📖 ${metrics.diskRead} · ✍️ ${metrics.diskWritten}',
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontFamily: 'Menlo', color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProcessesCard(SystemMetrics metrics) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(CupertinoIcons.flame_fill, color: AppColors.accentOrange, size: 18),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Top Active Processes',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CPU % / RAM %',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted.withValues(alpha: 0.8)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (metrics.topProcesses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Reading active processes...', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ),
            )
          else
            ...metrics.topProcesses.map((proc) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkCardBorder.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.app, size: 13, color: AppColors.primaryLight),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proc.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'PID: ${proc.pid}',
                              style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${proc.cpuPercent.toStringAsFixed(1)}% CPU',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Menlo',
                              fontWeight: FontWeight.bold,
                              color: proc.cpuPercent > 50 ? AppColors.accentRed : AppColors.accentOrange,
                            ),
                          ),
                          Text(
                            '${proc.memPercent.toStringAsFixed(1)}% RAM',
                            style: const TextStyle(fontSize: 9, fontFamily: 'Menlo', color: AppColors.accentCyan),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildLoadBadge(String label, double val) {
    Color color = AppColors.accentGreen;
    if (val > 4.0) {
      color = AppColors.accentRed;
    } else if (val > 2.5) {
      color = AppColors.accentOrange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: ${val.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 10, fontFamily: 'Menlo', fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildMemStatItem(String label, String value, Color accentColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildMemDivider() {
    return Container(
      height: 20,
      width: 1,
      color: AppColors.darkCardBorder.withValues(alpha: 0.6),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.bolt_fill, color: AppColors.accentOrange, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quick Maintenance',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildQuickActionTile(
            icon: CupertinoIcons.sparkles,
            title: 'Clean System Caches & Logs',
            subtitle: 'Reclaim space from temp files and user caches',
            color: AppColors.accentGreen,
            onTap: () => context.go('/cleaner'),
          ),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: CupertinoIcons.app_badge,
            title: 'Uninstall Applications',
            subtitle: 'Erase unwanted apps and hidden leftovers',
            color: AppColors.primaryLight,
            onTap: () => context.go('/uninstaller'),
          ),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: CupertinoIcons.chart_pie_fill,
            title: 'Visual Disk Explorer',
            subtitle: 'Interactive treemap analysis of large files and folders',
            color: const Color(0xFFD0A76F),
            onTap: () => context.go('/analyze'),
          ),
          const SizedBox(height: 10),
          _buildQuickActionTile(
            icon: CupertinoIcons.hammer,
            title: 'Purge Project Build Artifacts',
            subtitle: 'Clear node_modules, .dart_tool, target, build',
            color: AppColors.accentPurple,
            onTap: () => context.go('/purge'),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSummaryCard(SystemMetrics metrics) {
    final mainVol = metrics.mainVolume;

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Internal Main Drive
          Row(
            children: [
              const Icon(CupertinoIcons.cube_box, color: AppColors.accentCyan, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mainVol.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Internal',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ByteFormatter.format(mainVol.freeBytes, decimals: 1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.accentGreen,
              letterSpacing: -0.5,
            ),
          ),
          const Text('Free storage available', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: mainVol.totalBytes > 0 ? (mainVol.usedBytes / mainVol.totalBytes) : 0.5,
              minHeight: 8,
              backgroundColor: AppColors.darkCardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Used: ${ByteFormatter.format(mainVol.usedBytes, decimals: 1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Total: ${ByteFormatter.format(mainVol.totalBytes, decimals: 1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),

          // Conditional External Volumes Section
          if (metrics.hasExternalVolumes) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            const Text(
              'EXTERNAL VOLUMES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            ...metrics.externalVolumes.map((vol) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkCardBorder.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(CupertinoIcons.square_stack_3d_up, size: 14, color: AppColors.accentOrange),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              vol.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${ByteFormatter.format(vol.freeBytes, decimals: 0)} free',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: vol.totalBytes > 0 ? (vol.usedBytes / vol.totalBytes) : 0.0,
                          minHeight: 4,
                          backgroundColor: AppColors.darkCardBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: ${ByteFormatter.format(vol.totalBytes, decimals: 1)} (${vol.mountPoint})',
                        style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.darkBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.darkCardBorder.withValues(alpha: 0.6)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right, size: 12, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
