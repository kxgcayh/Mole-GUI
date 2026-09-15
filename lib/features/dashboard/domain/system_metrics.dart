import 'volume_info.dart';

class ProcessMetric {
  final int pid;
  final String name;
  final double cpuPercent;
  final double memPercent;

  const ProcessMetric({
    required this.pid,
    required this.name,
    required this.cpuPercent,
    required this.memPercent,
  });
}

class SystemMetrics {
  final double cpuUsagePercent;
  final double cpuUserPercent;
  final double cpuSysPercent;
  final int totalMemoryBytes;
  final int usedMemoryBytes;
  final int appMemoryBytes;
  final int wiredMemoryBytes;
  final int compressedMemoryBytes;
  final int cachedMemoryBytes;
  final int swapUsedBytes;
  final int swapTotalBytes;
  final VolumeInfo mainVolume;
  final List<VolumeInfo> allVolumes;
  final bool hasBattery;
  final int batteryPercentage;
  final bool isCharging;
  final DateTime timestamp;

  // Real-Time System Telemetry
  final List<double> loadAverages; // [1min, 5min, 15min]
  final int totalProcesses;
  final int runningProcesses;
  final int totalThreads;
  final String networkIn;
  final String networkOut;
  final String diskRead;
  final String diskWritten;
  final String uptime;
  final List<ProcessMetric> topProcesses;

  const SystemMetrics({
    required this.cpuUsagePercent,
    this.cpuUserPercent = 0.0,
    this.cpuSysPercent = 0.0,
    required this.totalMemoryBytes,
    required this.usedMemoryBytes,
    this.appMemoryBytes = 0,
    this.wiredMemoryBytes = 0,
    this.compressedMemoryBytes = 0,
    this.cachedMemoryBytes = 0,
    this.swapUsedBytes = 0,
    this.swapTotalBytes = 0,
    required this.mainVolume,
    required this.allVolumes,
    this.hasBattery = false,
    required this.batteryPercentage,
    required this.isCharging,
    required this.timestamp,
    this.loadAverages = const [0.0, 0.0, 0.0],
    this.totalProcesses = 0,
    this.runningProcesses = 0,
    this.totalThreads = 0,
    this.networkIn = '0 B',
    this.networkOut = '0 B',
    this.diskRead = '0 B',
    this.diskWritten = '0 B',
    this.uptime = '0m',
    this.topProcesses = const [],
  });

  // Convenience getters for main disk
  int get totalDiskBytes => mainVolume.totalBytes;
  int get usedDiskBytes => mainVolume.usedBytes;
  int get freeDiskBytes => mainVolume.freeBytes;
  double get diskUsagePercent => mainVolume.usagePercent;

  List<VolumeInfo> get externalVolumes =>
      allVolumes.where((v) => v.isExternal).toList();

  bool get hasExternalVolumes => externalVolumes.isNotEmpty;

  double get memoryUsagePercent {
    if (totalMemoryBytes <= 0) return 0.0;
    return ((usedMemoryBytes / totalMemoryBytes) * 100).clamp(0.0, 100.0);
  }

  int get freeMemoryBytes => (totalMemoryBytes - usedMemoryBytes).clamp(0, totalMemoryBytes);

  factory SystemMetrics.initial() => SystemMetrics(
        cpuUsagePercent: 0.0,
        cpuUserPercent: 0.0,
        cpuSysPercent: 0.0,
        totalMemoryBytes: 16 * 1024 * 1024 * 1024,
        usedMemoryBytes: 8 * 1024 * 1024 * 1024,
        appMemoryBytes: 5 * 1024 * 1024 * 1024,
        wiredMemoryBytes: 2 * 1024 * 1024 * 1024,
        compressedMemoryBytes: 1 * 1024 * 1024 * 1024,
        cachedMemoryBytes: 3 * 1024 * 1024 * 1024,
        swapUsedBytes: 0,
        swapTotalBytes: 0,
        mainVolume: VolumeInfo.initial(),
        allVolumes: [VolumeInfo.initial()],
        hasBattery: false,
        batteryPercentage: 100,
        isCharging: true,
        timestamp: DateTime.now(),
        loadAverages: [1.2, 1.5, 1.8],
        totalProcesses: 400,
        runningProcesses: 2,
        totalThreads: 2400,
        networkIn: '0 B',
        networkOut: '0 B',
        diskRead: '0 B',
        diskWritten: '0 B',
        uptime: '0m',
        topProcesses: const [],
      );
}
