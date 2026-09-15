class CleanItem {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String category;
  final bool isChecked;

  const CleanItem({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.category,
    this.isChecked = true,
  });

  CleanItem copyWith({
    String? id,
    String? name,
    String? path,
    int? sizeBytes,
    String? category,
    bool? isChecked,
  }) {
    return CleanItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
