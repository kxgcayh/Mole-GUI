import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/mole_cli_service.dart';
import '../domain/disk_node.dart';

class AnalyzeState {
  final String currentPath;
  final List<String> breadcrumbs;
  final List<DiskNode> items;
  final int totalSizeBytes;
  final int totalItemCount;
  final bool isLoading;
  final String? errorMessage;
  final int diskUsedBytes;
  final int diskTotalBytes;

  const AnalyzeState({
    required this.currentPath,
    required this.breadcrumbs,
    required this.items,
    required this.totalSizeBytes,
    required this.totalItemCount,
    this.isLoading = false,
    this.errorMessage,
    this.diskUsedBytes = 0,
    this.diskTotalBytes = 0,
  });

  AnalyzeState copyWith({
    String? currentPath,
    List<String>? breadcrumbs,
    List<DiskNode>? items,
    int? totalSizeBytes,
    int? totalItemCount,
    bool? isLoading,
    String? errorMessage,
    int? diskUsedBytes,
    int? diskTotalBytes,
  }) {
    return AnalyzeState(
      currentPath: currentPath ?? this.currentPath,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      items: items ?? this.items,
      totalSizeBytes: totalSizeBytes ?? this.totalSizeBytes,
      totalItemCount: totalItemCount ?? this.totalItemCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      diskUsedBytes: diskUsedBytes ?? this.diskUsedBytes,
      diskTotalBytes: diskTotalBytes ?? this.diskTotalBytes,
    );
  }
}

final analyzeViewModelProvider = NotifierProvider<AnalyzeViewModel, AnalyzeState>(() {
  return AnalyzeViewModel();
});

class AnalyzeViewModel extends Notifier<AnalyzeState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  AnalyzeState build() {
    final home = _cliService.homeDir;
    final initialPath = Directory(home).existsSync() ? home : '/';

    Future.microtask(() => scan(initialPath));

    return AnalyzeState(
      currentPath: initialPath,
      breadcrumbs: _buildBreadcrumbs(initialPath),
      items: const [],
      totalSizeBytes: 0,
      totalItemCount: 0,
      isLoading: true,
    );
  }

  List<String> _buildBreadcrumbs(String path) {
    if (path == '/') return ['Whole Disk'];
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return ['Whole Disk', ...segments];
  }

  String _pathFromBreadcrumbIndex(int index) {
    if (index == 0) return '/';
    final parts = state.breadcrumbs.sublist(1, index + 1);
    return '/${parts.join('/')}';
  }

  Future<void> scan(String path) async {
    if (!ref.mounted) return;

    state = state.copyWith(
      currentPath: path,
      breadcrumbs: _buildBreadcrumbs(path),
      isLoading: true,
      errorMessage: null,
    );

    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Directory does not exist: $path',
        );
        return;
      }

      // 1. Fetch disk telemetry for whole disk summary
      int diskUsed = 0;
      int diskTotal = 0;
      try {
        final dfRes = await Process.run('df', ['-k', path]);
        final lines = dfRes.stdout.toString().trim().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final totalKb = int.tryParse(parts[1]) ?? 0;
            final usedKb = int.tryParse(parts[2]) ?? 0;
            diskTotal = totalKb * 1024;
            diskUsed = usedKb * 1024;
          }
        }
      } catch (_) {}

      // 2. Scan direct children
      final List<DiskNode> directChildren = [];
      final entries = dir.listSync(followLinks: false);

      for (final entry in entries) {
        final name = entry.path.split('/').last;
        if (name.isEmpty) continue;

        if (entry is Directory) {
          final size = await _getDirSize(entry.path);
          directChildren.add(DiskNode(
            path: entry.path,
            name: name,
            sizeBytes: size,
            isDirectory: true,
          ));
        } else if (entry is File) {
          try {
            final size = await entry.length();
            directChildren.add(DiskNode(
              path: entry.path,
              name: name,
              sizeBytes: size,
              isDirectory: false,
            ));
          } catch (_) {}
        }
      }

      directChildren.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      final totalFolderBytes = directChildren.fold<int>(0, (sum, n) => sum + n.sizeBytes);

      if (!ref.mounted) return;
      state = state.copyWith(
        items: directChildren,
        totalSizeBytes: totalFolderBytes,
        totalItemCount: directChildren.length,
        diskUsedBytes: diskUsed,
        diskTotalBytes: diskTotal,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      LoggerService.e('Error scanning directory $path', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to scan $path: $e',
      );
    }
  }

  Future<int> _getDirSize(String dirPath) async {
    try {
      final res = await Process.run('du', ['-sk', dirPath]);
      final out = res.stdout.toString().trim();
      final kb = int.tryParse(out.split(RegExp(r'\s+')).first) ?? 0;
      return kb * 1024;
    } catch (_) {
      return 0;
    }
  }

  void navigateTo(DiskNode node) {
    if (node.isDirectory && node.path.isNotEmpty) {
      scan(node.path);
    }
  }

  void navigateToBreadcrumb(int index) {
    final targetPath = _pathFromBreadcrumbIndex(index);
    scan(targetPath);
  }

  void navigateUp() {
    if (state.breadcrumbs.length <= 1) return;
    final parent = Directory(state.currentPath).parent.path;
    scan(parent);
  }

  Future<void> revealInFinder(String path) async {
    try {
      await Process.run('open', ['-R', path]);
    } catch (e) {
      LoggerService.w('Could not reveal in Finder: $e');
    }
  }

  Future<void> moveToTrash(String path) async {
    try {
      final res = await Process.run('osascript', [
        '-e',
        'tell application "Finder" to delete POSIX file "$path"',
      ]);
      if (res.exitCode != 0) {
        // Fallback to directory/file deletion or moving to ~/.Trash
        final home = _cliService.homeDir;
        final name = path.split('/').last;
        final trashTarget = '$home/.Trash/$name';
        await Process.run('mv', [path, trashTarget]);
      }
      // Rescan current directory
      scan(state.currentPath);
    } catch (e) {
      LoggerService.e('Error moving $path to trash', e);
    }
  }
}
