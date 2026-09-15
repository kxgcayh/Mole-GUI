class AppRemnant {
  final String path;
  final String description;
  final int sizeBytes;

  const AppRemnant({
    required this.path,
    required this.description,
    required this.sizeBytes,
  });
}

class AppInfo {
  final String id;
  final String name;
  final String bundlePath;
  final int appSizeBytes;
  final int associatedSizeBytes;
  final bool isSystemApp;
  final List<AppRemnant> associatedPaths;

  const AppInfo({
    required this.id,
    required this.name,
    required this.bundlePath,
    required this.appSizeBytes,
    required this.associatedSizeBytes,
    required this.isSystemApp,
    required this.associatedPaths,
  });

  int get totalSizeBytes => appSizeBytes + associatedSizeBytes;
}
