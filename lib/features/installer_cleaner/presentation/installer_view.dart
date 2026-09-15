import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import 'installer_view_model.dart';

class InstallerView extends ConsumerWidget {
  const InstallerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(installerViewModelProvider);
    final viewModel = ref.read(installerViewModelProvider.notifier);

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
                      'Leftover Installers',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Clean downloaded .dmg, .pkg, and disk image installers',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => viewModel.scan(),
                      icon: const Icon(CupertinoIcons.refresh, size: 16),
                      label: const Text('Rescan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.darkCardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ActionButton(
                      label: state.status == InstallerStatus.cleaning
                          ? 'Cleaning...'
                          : 'Delete ${ByteFormatter.format(state.selectedSizeBytes)}',
                      icon: CupertinoIcons.trash,
                      gradient: AppColors.cleanGradient,
                      isLoading: state.status == InstallerStatus.cleaning,
                      onPressed: state.selectedSizeBytes > 0 && state.status != InstallerStatus.cleaning
                          ? () => viewModel.cleanSelected()
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Stats Bar
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.arrow_down_doc_fill, color: AppColors.accentCyan, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Found: ${ByteFormatter.format(state.totalSizeBytes)} in ${state.files.length} installer packages',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    'Selected: ${ByteFormatter.format(state.selectedSizeBytes)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Files list
            Expanded(
              child: state.status == InstallerStatus.scanning
                  ? const Center(child: CircularProgressIndicator())
                  : state.files.isEmpty
                      ? const Center(
                          child: Text(
                            'No redundant installer files found in Downloads/Desktop. 👍',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : GlassCard(
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            itemCount: state.files.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
                            itemBuilder: (context, idx) {
                              final item = state.files[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isChecked,
                                      activeColor: AppColors.primary,
                                      onChanged: (val) {
                                        viewModel.toggleItemCheck(item.id, val ?? false);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.arrow_down_doc,
                                        size: 18,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            item.path,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      ByteFormatter.format(item.sizeBytes),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
