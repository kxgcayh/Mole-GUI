class PurgeItem {
  final String id;
  final String name;
  final String projectPath;
  final String path;
  final int sizeBytes;
  final String type;
  final bool isChecked;

  const PurgeItem({
    required this.id,
    required this.name,
    required this.projectPath,
    required this.path,
    required this.sizeBytes,
    required this.type,
    this.isChecked = false,
  });

  PurgeItem copyWith({
    String? id,
    String? name,
    String? projectPath,
    String? path,
    int? sizeBytes,
    String? type,
    bool? isChecked,
  }) {
    return PurgeItem(
      id: id ?? this.id,
      name: name ?? this.name,
      projectPath: projectPath ?? this.projectPath,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      type: type ?? this.type,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
