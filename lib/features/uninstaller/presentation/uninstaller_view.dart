import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/app_info.dart';
import 'uninstaller_view_model.dart';

class UninstallerView extends ConsumerWidget {
  const UninstallerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uninstallerViewModelProvider);
    final viewModel = ref.read(uninstallerViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Uninstaller',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Completely remove applications along with their hidden remnant files',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => viewModel.scan(),
                  icon: const Icon(CupertinoIcons.refresh, size: 16),
                  label: const Text('Refresh Apps'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.darkCardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.darkCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.search, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search installed applications...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => viewModel.setSearchQuery(val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Split: Apps List (Left) & App Details Drawer (Right)
            Expanded(
              child: state.status == UninstallerStatus.scanning
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Apps list
                        Expanded(
                          flex: 3,
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            child: state.filteredApps.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text(
                                        'No applications found.',
                                        style: TextStyle(color: AppColors.textSecondary),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: state.filteredApps.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(height: 1, indent: 64),
                                    itemBuilder: (context, idx) {
                                      final app = state.filteredApps[idx];
                                      final isSelected =
                                          state.selectedApp?.id == app.id;

                                      return Material(
                                        color: isSelected
                                            ? AppColors.primary.withValues(alpha: 0.15)
                                            : Colors.transparent,
                                        child: InkWell(
                                          onTap: () => viewModel.selectApp(app),
                                          hoverColor: AppColors.primary.withValues(alpha: 0.08),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary
                                                        .withValues(alpha: 0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(8),
                                                  ),
                                                  child: const Center(
                                                    child: Icon(
                                                      CupertinoIcons.app_badge,
                                                      size: 20,
                                                      color: AppColors.primaryLight,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        app.name,
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${app.associatedPaths.length} remnant files found',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      ByteFormatter.format(
                                                          app.totalSizeBytes),
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.textPrimary,
                                                      ),
                                                    ),
                                                    if (app.isSystemApp)
                                                      const Text(
                                                        'System',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: AppColors.accentOrange,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Right: Selected App Details & Remnants
                        Expanded(
                          flex: 2,
                          child: state.selectedApp == null
                              ? GlassCard(
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(CupertinoIcons.cursor_rays,
                                            size: 32,
                                            color: AppColors.textMuted),
                                        SizedBox(height: 12),
                                        Text(
                                          'Select an app to inspect\nassociated remnants',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildAppDetailCard(
                                  state.selectedApp!,
                                  state,
                                  viewModel,
                                  context,
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

  Widget _buildAppDetailCard(
    AppInfo app,
    UninstallerState state,
    UninstallerViewModel viewModel,
    BuildContext context,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.app_badge,
                    size: 24,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ByteFormatter.format(app.totalSizeBytes),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'ASSOCIATED FILES & REMNANTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),

          // Remnants list
          Expanded(
            child: ListView(
              children: [
                _buildRemnantTile(
                  title: 'Application Binary',
                  path: app.bundlePath,
                  size: app.appSizeBytes,
                ),
                ...app.associatedPaths.map((remnant) => _buildRemnantTile(
                      title: remnant.description,
                      path: remnant.path,
                      size: remnant.sizeBytes,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Uninstall action
          SizedBox(
            width: double.infinity,
            child: ActionButton(
              label: 'Uninstall & Clean Remnants',
              icon: CupertinoIcons.trash,
              color: AppColors.accentRed,
              isLoading: state.status == UninstallerStatus.uninstalling,
              onPressed: app.isSystemApp
                  ? null
                  : () {
                      _showConfirmDialog(context, app, viewModel);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemnantTile({
    required String title,
    required String path,
    required int size,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.doc, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            ByteFormatter.format(size),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    AppInfo app,
    UninstallerViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCardBg,
        title: Text('Uninstall ${app.name}?'),
        content: Text(
          'This will permanently delete ${app.name} and ${app.associatedPaths.length} associated preference and cache files (${ByteFormatter.format(app.totalSizeBytes)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.uninstall(app);
            },
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}
