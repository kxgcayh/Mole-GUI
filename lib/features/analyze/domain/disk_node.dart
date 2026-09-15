import 'package:flutter/material.dart';

class DiskNode {
  final String path;
  final String name;
  final int sizeBytes;
  final bool isDirectory;
  final int itemCount;
  final List<DiskNode> children;
  final Color? customColor;

  const DiskNode({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.isDirectory,
    this.itemCount = 0,
    this.children = const [],
    this.customColor,
  });

  bool get isOtherGroup => name.contains('items') && isDirectory;

  DiskNode copyWith({
    String? path,
    String? name,
    int? sizeBytes,
    bool? isDirectory,
    int? itemCount,
    List<DiskNode>? children,
    Color? customColor,
  }) {
    return DiskNode(
      path: path ?? this.path,
      name: name ?? this.name,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isDirectory: isDirectory ?? this.isDirectory,
      itemCount: itemCount ?? this.itemCount,
      children: children ?? this.children,
      customColor: customColor ?? this.customColor,
    );
  }
}
