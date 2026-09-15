import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/byte_formatter.dart';
import '../domain/disk_node.dart';
import 'analyze_view_model.dart';
import 'widgets/treemap_widget.dart';

class AnalyzeView extends ConsumerWidget {
  const AnalyzeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyzeViewModelProvider);
    final viewModel = ref.read(analyzeViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Breadcrumbs & Telemetry
            _buildTopBar(context, state, viewModel),
            const SizedBox(height: 16),

            // Main Content: Left Panel (Folder list) & Right Canvas (Treemap)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Explorer Panel (Width: 240)
                  SizedBox(
                    width: 240,
                    child: _buildLeftPanel(context, state, viewModel),
                  ),
                  const SizedBox(width: 14),

                  // Right Interactive Treemap Canvas
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCardBg.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.darkCardBorder),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: state.isLoading
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFFD0A76F),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Analyzing storage blocks...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : state.errorMessage != null
                                ? Center(
                                    child: Text(
                                      state.errorMessage!,
                                      style: const TextStyle(color: AppColors.accentRed),
                                    ),
                                  )
                                : TreemapWidget(
                                    nodes: state.items,
                                    onNodeTap: (node) => viewModel.navigateTo(node),
                                    onNodeAction: (node, action) => _handleNodeAction(context, viewModel, node, action),
                                  ),
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

  Widget _buildTopBar(BuildContext context, AnalyzeState state, AnalyzeViewModel viewModel) {
    return Row(
      children: [
        // Breadcrumb navigation
        const Icon(CupertinoIcons.folder, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < state.breadcrumbs.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '›',
                        style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                      ),
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => viewModel.navigateToBreadcrumb(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        state.breadcrumbs[i],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: i == state.breadcrumbs.length - 1 ? FontWeight.bold : FontWeight.w500,
                          color: i == state.breadcrumbs.length - 1 ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Right Telemetry & Refresh
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.darkBg.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.darkCardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0A76F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Current ${ByteFormatter.format(state.totalSizeBytes, decimals: 2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (state.diskTotalBytes > 0) ...[
                const SizedBox(width: 6),
                Text(
                  '· Disk ${ByteFormatter.format(state.diskUsedBytes, decimals: 0)} / ${ByteFormatter.format(state.diskTotalBytes, decimals: 0)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: state.isLoading ? null : () => viewModel.scan(state.currentPath),
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 13,
                    color: state.isLoading ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanel(BuildContext context, AnalyzeState state, AnalyzeViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCardBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planet / Sphere Header
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 12),
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.3),
                        radius: 0.85,
                        colors: [
                          Color(0xFFF3E5AB), // Bright warm core
                          Color(0xFFD0A76F), // Golden band
                          Color(0xFFB85D3B), // Terracotta stripe
                          Color(0xFF5D4A3E), // Dark shadow edge
                        ],
                        stops: [0.1, 0.45, 0.75, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD0A76F).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${state.totalItemCount} items, ${ByteFormatter.format(state.totalSizeBytes, decimals: 2)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Menlo',
                      color: AppColors.textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Text(
              'Current Folder',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Scrollable folder list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final node = state.items[index];
                return _buildFolderListTile(context, node, viewModel);
              },
            ),
          ),

          // Footer hint
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Right-click: Open / Trash',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMuted.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderListTile(BuildContext context, DiskNode node, AnalyzeViewModel viewModel) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => viewModel.navigateTo(node),
        onSecondaryTapUp: (details) => _showItemContextMenu(context, details.globalPosition, viewModel, node),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Icon(
                node.isDirectory ? CupertinoIcons.folder : CupertinoIcons.doc,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      ByteFormatter.format(node.sizeBytes, decimals: 2),
                      style: const TextStyle(
                        fontSize: 9,
                        fontFamily: 'Menlo',
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (node.isDirectory)
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 11,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNodeAction(BuildContext context, AnalyzeViewModel viewModel, DiskNode node, String action) {
    if (action == 'reveal') {
      viewModel.revealInFinder(node.path);
    } else if (action == 'copy_path') {
      Clipboard.setData(ClipboardData(text: node.path));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Path copied to clipboard!'), duration: Duration(seconds: 1)),
      );
    } else if (action == 'trash') {
      viewModel.moveToTrash(node.path);
    }
  }

  void _showItemContextMenu(BuildContext context, Offset position, AnalyzeViewModel viewModel, DiskNode node) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final relativeRect = overlay != null
        ? RelativeRect.fromRect(
            Rect.fromLTWH(position.dx, position.dy, 0, 0),
            Offset.zero & overlay.size,
          )
        : RelativeRect.fromLTRB(position.dx, position.dy, 0, 0);

    showMenu(
      context: context,
      position: relativeRect,
      color: AppColors.darkCardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.darkCardBorder),
      ),
      items: [
        PopupMenuItem(
          height: 36,
          child: const Row(
            children: [
              Icon(CupertinoIcons.folder, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Reveal in Finder', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ],
          ),
          onTap: () => viewModel.revealInFinder(node.path),
        ),
        PopupMenuItem(
          height: 36,
          child: const Row(
            children: [
              Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Copy Path', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ],
          ),
          onTap: () {
            Clipboard.setData(ClipboardData(text: node.path));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Path copied!'), duration: Duration(seconds: 1)),
            );
          },
        ),
        PopupMenuItem(
          height: 36,
          child: const Row(
            children: [
              Icon(CupertinoIcons.trash, size: 14, color: AppColors.accentRed),
              SizedBox(width: 8),
              Text('Move to Trash', style: TextStyle(fontSize: 12, color: AppColors.accentRed)),
            ],
          ),
          onTap: () => viewModel.moveToTrash(node.path),
        ),
      ],
    );
  }
}
