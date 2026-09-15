import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../domain/clean_category.dart';
import 'cleaner_view_model.dart';

class CleanerView extends ConsumerWidget {
  const CleanerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cleanerViewModelProvider);
    final viewModel = ref.read(cleanerViewModelProvider.notifier);

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Cleaner',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan and safely delete junk caches, logs, and leftovers',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (state.status != CleanerStatus.scanning && state.status != CleanerStatus.cleaning)
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
                      label: state.status == CleanerStatus.cleaning
                          ? 'Cleaning...'
                          : 'Clean ${ByteFormatter.format(state.totalSelectedBytes)}',
                      icon: CupertinoIcons.trash,
                      gradient: AppColors.cleanGradient,
                      isLoading: state.status == CleanerStatus.cleaning,
                      onPressed: state.totalSelectedBytes > 0 && state.status != CleanerStatus.cleaning
                          ? () => viewModel.cleanSelected()
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Banner if scanning or cleaning
            if (state.status == CleanerStatus.scanning || state.status == CleanerStatus.cleaning)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          state.currentProgressMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: state.progress > 0 ? state.progress : null,
                        minHeight: 6,
                        backgroundColor: AppColors.darkCardBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),

            // Summary Stats Bar
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.info_circle_fill, color: AppColors.accentCyan, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Found: ${ByteFormatter.format(state.totalScannedBytes)} across ${state.categories.length} categories',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    'Selected: ${ByteFormatter.format(state.totalSelectedBytes)} (${state.selectedCount} items)',
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

            // Categories List
            Expanded(
              child: state.categories.isEmpty && state.status == CleanerStatus.scanning
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : state.categories.isEmpty
                      ? const Center(
                          child: Text(
                            'No cleanable files found. Your system is spotless! 🎉',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: state.categories.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            return _buildCategoryCard(category, viewModel);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CleanCategory category, CleanerViewModel viewModel) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Category Header Bar
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => viewModel.toggleCategoryExpand(category.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Checkbox(
                      value: category.isAllSelected
                          ? true
                          : (category.isPartiallySelected ? null : false),
                      tristate: true,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        viewModel.toggleCategoryCheck(category.id, val ?? false);
                      },
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(category.id),
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
                            category.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            category.description,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ByteFormatter.format(category.totalSizeBytes),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      category.isExpanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 16,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible Items List
          if (category.isExpanded) ...[
            const Divider(height: 1),
            Container(
              color: AppColors.darkBg.withValues(alpha: 0.3),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: category.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1, indent: 48),
                itemBuilder: (context, idx) {
                  final item = category.items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: item.isChecked,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            viewModel.toggleItemCheck(category.id, item.id, val ?? false);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                item.path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          ByteFormatter.format(item.sizeBytes),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'user_caches':
        return CupertinoIcons.cube_box;
      case 'logs':
        return CupertinoIcons.doc_text;
      case 'developer_caches':
        return CupertinoIcons.hammer;
      case 'browser_caches':
        return CupertinoIcons.globe;
      case 'app_leftovers':
        return CupertinoIcons.trash_circle;
      case 'trash':
        return CupertinoIcons.trash;
      default:
        return CupertinoIcons.folder;
    }
  }
}
