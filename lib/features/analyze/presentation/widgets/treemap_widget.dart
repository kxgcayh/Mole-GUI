import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/byte_formatter.dart';
import '../../domain/disk_node.dart';

class TreemapWidget extends StatelessWidget {
  final List<DiskNode> nodes;
  final Function(DiskNode node) onNodeTap;
  final Function(DiskNode node, String action)? onNodeAction;

  const TreemapWidget({
    super.key,
    required this.nodes,
    required this.onNodeTap,
    this.onNodeAction,
  });

  static const List<Color> palette = [
    Color(0xFFD0A76F), // Golden Tan (Largest / Dominant)
    Color(0xFFC2884A), // Warm Amber / Ochre
    Color(0xFF7F7188), // Dusty Lavender
    Color(0xFFB85D3B), // Terracotta / Rust
    Color(0xFF6D5E72), // Slate Mauve
    Color(0xFF5F5263), // Dark Mauve
    Color(0xFF544740), // Cocoa Brown
    Color(0xFF8F7256), // Olive Ochre
    Color(0xFFA36B5A), // Muted Sienna
    Color(0xFF463B35), // Dark Slate
  ];

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Center(
        child: Text(
          'Folder is empty or 0 bytes.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        if (totalWidth <= 0 || totalHeight <= 0) {
          return const SizedBox.shrink();
        }

        final tiles = _computeSquarifiedLayout(
          nodes,
          Rect.fromLTWH(0, 0, totalWidth, totalHeight),
        );

        return Stack(
          children: tiles.map((tile) {
            return Positioned(
              left: tile.rect.left,
              top: tile.rect.top,
              width: max(0.0, tile.rect.width),
              height: max(0.0, tile.rect.height),
              child: _TreemapTile(
                node: tile.node,
                color: tile.color,
                onTap: () => onNodeTap(tile.node),
                onAction: onNodeAction != null
                    ? (action) => onNodeAction!(tile.node, action)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<_PositionedTile> _computeSquarifiedLayout(
    List<DiskNode> rawNodes,
    Rect bounds,
  ) {
    if (rawNodes.isEmpty) return [];

    // Filter non-zero items & sort descending
    final sorted = List<DiskNode>.from(rawNodes.where((n) => n.sizeBytes > 0))
      ..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));

    if (sorted.isEmpty) return [];

    // Group smaller items (>8 items or < 1.5% size) into an aggregated "X items" block
    final totalSize = sorted.fold<int>(0, (sum, n) => sum + n.sizeBytes);
    final List<DiskNode> processed = [];
    int otherSize = 0;
    int otherCount = 0;

    for (int i = 0; i < sorted.length; i++) {
      final node = sorted[i];
      final ratio = totalSize > 0 ? (node.sizeBytes / totalSize) : 0.0;

      if (i < 8 && ratio >= 0.015) {
        processed.add(node);
      } else {
        otherSize += node.sizeBytes;
        otherCount++;
      }
    }

    if (otherCount > 0 && otherSize > 0) {
      processed.add(DiskNode(
        path: '',
        name: '$otherCount items',
        sizeBytes: otherSize,
        isDirectory: true,
        itemCount: otherCount,
      ));
    }

    final totalProcessed = processed.fold<int>(0, (sum, n) => sum + n.sizeBytes);
    if (totalProcessed <= 0) return [];

    final result = <_PositionedTile>[];
    _layoutRecursive(processed, bounds, totalProcessed, 0, result);
    return result;
  }

  void _layoutRecursive(
    List<DiskNode> items,
    Rect rect,
    int totalBytes,
    int colorIndex,
    List<_PositionedTile> output,
  ) {
    if (items.isEmpty || rect.width <= 0 || rect.height <= 0) return;

    if (items.length == 1) {
      final node = items.first;
      final color = node.isOtherGroup
          ? const Color(0xFF544740)
          : palette[colorIndex % palette.length];
      output.add(_PositionedTile(
        node: node,
        rect: _inset(rect),
        color: color,
      ));
      return;
    }

    final isHorizontal = rect.width >= rect.height;
    int mid = 1;
    int bestMid = 1;
    double bestAspectDiff = double.infinity;

    int currentSum = 0;
    for (int i = 0; i < items.length - 1; i++) {
      currentSum += items[i].sizeBytes;
      final weight = totalBytes > 0 ? (currentSum / totalBytes) : 0.5;

      final sliceSize = isHorizontal ? rect.width * weight : rect.height * weight;
      final otherSliceSize = isHorizontal ? rect.width * (1.0 - weight) : rect.height * (1.0 - weight);

      final aspect1 = isHorizontal ? (sliceSize / rect.height) : (rect.width / sliceSize);
      final aspect2 = isHorizontal ? (otherSliceSize / rect.height) : (rect.width / otherSliceSize);

      final diff = (aspect1 - 1.0).abs() + (aspect2 - 1.0).abs();
      if (diff < bestAspectDiff) {
        bestAspectDiff = diff;
        bestMid = i + 1;
      }
    }
    mid = bestMid;

    final leftItems = items.sublist(0, mid);
    final rightItems = items.sublist(mid);

    final leftBytes = leftItems.fold<int>(0, (sum, n) => sum + n.sizeBytes);
    final rightBytes = rightItems.fold<int>(0, (sum, n) => sum + n.sizeBytes);

    final leftFraction = totalBytes > 0 ? (leftBytes / totalBytes) : 0.5;

    Rect leftRect;
    Rect rightRect;

    if (isHorizontal) {
      final splitWidth = rect.width * leftFraction;
      leftRect = Rect.fromLTWH(rect.left, rect.top, splitWidth, rect.height);
      rightRect = Rect.fromLTWH(
        rect.left + splitWidth,
        rect.top,
        rect.width - splitWidth,
        rect.height,
      );
    } else {
      final splitHeight = rect.height * leftFraction;
      leftRect = Rect.fromLTWH(rect.left, rect.top, rect.width, splitHeight);
      rightRect = Rect.fromLTWH(
        rect.left,
        rect.top + splitHeight,
        rect.width,
        rect.height - splitHeight,
      );
    }

    _layoutRecursive(leftItems, leftRect, leftBytes, colorIndex, output);
    _layoutRecursive(
      rightItems,
      rightRect,
      rightBytes,
      colorIndex + leftItems.length,
      output,
    );
  }

  Rect _inset(Rect r) {
    const margin = 3.0;
    return Rect.fromLTWH(
      r.left + margin,
      r.top + margin,
      max(0.0, r.width - (margin * 2)),
      max(0.0, r.height - (margin * 2)),
    );
  }
}

class _PositionedTile {
  final DiskNode node;
  final Rect rect;
  final Color color;

  const _PositionedTile({
    required this.node,
    required this.rect,
    required this.color,
  });
}

class _TreemapTile extends StatefulWidget {
  final DiskNode node;
  final Color color;
  final VoidCallback onTap;
  final Function(String action)? onAction;

  const _TreemapTile({
    required this.node,
    required this.color,
    required this.onTap,
    this.onAction,
  });

  @override
  State<_TreemapTile> createState() => _TreemapTileState();
}

class _TreemapTileState extends State<_TreemapTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isGroup = widget.node.isOtherGroup;

    return MouseRegion(
      cursor: isGroup ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isGroup ? null : widget.onTap,
        onSecondaryTapUp: (details) {
          if (widget.node.path.isNotEmpty && widget.onAction != null) {
            _showContextMenu(context, details.globalPosition);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          decoration: BoxDecoration(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.9)
                : widget.color.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.15),
              width: _isHovered ? 1.5 : 0.8,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canShowFull = constraints.maxWidth > 70 && constraints.maxHeight > 50;
                final canShowSmall = constraints.maxWidth > 40 && constraints.maxHeight > 30;

                if (!canShowSmall) return const SizedBox.shrink();

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isGroup
                                  ? CupertinoIcons.square_grid_2x2_fill
                                  : (widget.node.isDirectory
                                      ? CupertinoIcons.folder_fill
                                      : CupertinoIcons.doc_fill),
                              size: canShowFull ? 16 : 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            if (canShowFull) ...[
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  widget.node.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (!canShowFull && canShowSmall) ...[
                          const SizedBox(height: 2),
                          Flexible(
                            child: Text(
                              widget.node.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                        if (canShowFull) ...[
                          const SizedBox(height: 4),
                          Text(
                            ByteFormatter.format(widget.node.sizeBytes, decimals: 2),
                            style: TextStyle(
                              fontFamily: 'Menlo',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
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
          onTap: () => widget.onAction?.call('reveal'),
        ),
        PopupMenuItem(
          height: 36,
          child: const Row(
            children: [
              Icon(CupertinoIcons.doc_on_clipboard, size: 14, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text('Copy Full Path', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
            ],
          ),
          onTap: () => widget.onAction?.call('copy_path'),
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
          onTap: () => widget.onAction?.call('trash'),
        ),
      ],
    );
  }
}
