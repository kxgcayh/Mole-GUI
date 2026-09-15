class VolumeInfo {
  final String name;
  final String mountPoint;
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final bool isExternal;

  const VolumeInfo({
    required this.name,
    required this.mountPoint,
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    this.isExternal = false,
  });

  double get usagePercent {
    if (totalBytes <= 0) return 0.0;
    return ((usedBytes / totalBytes) * 100).clamp(0.0, 100.0);
  }

  factory VolumeInfo.initial() => const VolumeInfo(
        name: 'Macintosh HD',
        mountPoint: '/',
        totalBytes: 500 * 1024 * 1024 * 1024,
        usedBytes: 250 * 1024 * 1024 * 1024,
        freeBytes: 250 * 1024 * 1024 * 1024,
        isExternal: false,
      );
}
