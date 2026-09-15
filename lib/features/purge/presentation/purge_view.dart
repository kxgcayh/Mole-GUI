import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import 'purge_view_model.dart';

class PurgeView extends ConsumerWidget {
  const PurgeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(purgeViewModelProvider);
    final viewModel = ref.read(purgeViewModelProvider.notifier);

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
                      'Project Build Purge',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reclaim gigabytes from node_modules, .dart_tool, target, and build folders',
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
                      label: state.status == PurgeStatus.purging
                          ? 'Purging...'
                          : 'Purge ${ByteFormatter.format(state.selectedSizeBytes)}',
                      icon: CupertinoIcons.trash_fill,
                      color: AppColors.accentOrange,
                      isLoading: state.status == PurgeStatus.purging,
                      onPressed: state.selectedSizeBytes > 0 && state.status != PurgeStatus.purging
                          ? () => viewModel.purgeSelected()
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
                  const Icon(CupertinoIcons.hammer_fill, color: AppColors.accentOrange, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Found: ${ByteFormatter.format(state.totalSizeBytes)} across ${state.items.length} build folders',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    'Selected: ${ByteFormatter.format(state.selectedSizeBytes)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Expanded(
              child: state.status == PurgeStatus.scanning
                  ? const Center(child: CircularProgressIndicator())
                  : state.items.isEmpty
                      ? const Center(
                          child: Text(
                            'No project build artifacts found.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : GlassCard(
                          padding: EdgeInsets.zero,
                          child: ListView.separated(
                            itemCount: state.items.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1, indent: 48),
                            itemBuilder: (context, idx) {
                              final item = state.items[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: item.isChecked,
                                      activeColor: AppColors.accentOrange,
                                      onChanged: (val) {
                                        viewModel.toggleItemCheck(
                                            item.id, val ?? false);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentOrange
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.folder_badge_minus,
                                        size: 18,
                                        color: AppColors.accentOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkBg,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                      color: AppColors
                                                          .darkCardBorder),
                                                ),
                                                child: Text(
                                                  item.type,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
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
