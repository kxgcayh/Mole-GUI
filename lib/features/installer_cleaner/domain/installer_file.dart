class InstallerFile {
  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final String extension;
  final bool isChecked;

  const InstallerFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.extension,
    this.isChecked = true,
  });

  InstallerFile copyWith({
    String? id,
    String? name,
    String? path,
    int? sizeBytes,
    String? extension,
    bool? isChecked,
  }) {
    return InstallerFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      extension: extension ?? this.extension,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}
