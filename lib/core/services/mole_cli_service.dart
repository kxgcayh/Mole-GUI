import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cleaner/domain/clean_category.dart';
import '../../features/cleaner/domain/clean_item.dart';
import '../../features/uninstaller/domain/app_info.dart';
import '../../features/purge/domain/purge_item.dart';
import '../../features/installer_cleaner/domain/installer_file.dart';
import '../../features/optimizer/domain/optimization_task.dart';
import 'logger_service.dart';

final moleCliServiceProvider = Provider<MoleCliService>((ref) {
  return MoleCliService();
});

class MoleCliService {
  String? _moleScriptPath;
  String _moleVersion = '1.51';
  bool _isHomebrew = false;

  MoleCliService() {
    _detectMolePath();
  }

  String? get molePath => _moleScriptPath;
  bool get isFound => _moleScriptPath != null;
  bool get isHomebrew => _isHomebrew;
  String get moleVersion => _moleVersion;

  void _detectMolePath() {
    // 1. Prioritize Homebrew paths (Apple Silicon & Intel)
    final homebrewCandidates = [
      '/opt/homebrew/bin/mole',
      '/opt/homebrew/bin/mo',
      '/usr/local/bin/mole',
      '/usr/local/bin/mo',
      '/opt/homebrew/opt/mole/bin/mole',
      '/usr/local/opt/mole/bin/mole',
    ];

    for (final p in homebrewCandidates) {
      if (File(p).existsSync()) {
        _moleScriptPath = File(p).absolute.path;
        _isHomebrew = true;
        LoggerService.i('Found Homebrew Mole executable at: $_moleScriptPath');
        _fetchVersion();
        return;
      }
    }

    // 2. Dynamic check via system PATH (`which mole` / `which mo`)
    try {
      final whichResult = Process.runSync('which', ['mole']);
      final path = whichResult.stdout.toString().trim();
      if (path.isNotEmpty && File(path).existsSync()) {
        _moleScriptPath = File(path).absolute.path;
        _isHomebrew = _moleScriptPath!.contains('homebrew') || _moleScriptPath!.contains('/usr/local');
        LoggerService.i('Found Mole via which at: $_moleScriptPath (Homebrew: $_isHomebrew)');
        _fetchVersion();
        return;
      }

      final whichMoResult = Process.runSync('which', ['mo']);
      final moPath = whichMoResult.stdout.toString().trim();
      if (moPath.isNotEmpty && File(moPath).existsSync()) {
        _moleScriptPath = File(moPath).absolute.path;
        _isHomebrew = _moleScriptPath!.contains('homebrew') || _moleScriptPath!.contains('/usr/local');
        LoggerService.i('Found Mole (mo) via which at: $_moleScriptPath (Homebrew: $_isHomebrew)');
        _fetchVersion();
        return;
      }
    } catch (_) {}

    LoggerService.w('Mole CLI not found in Homebrew or local path');
  }

  void _fetchVersion() {
    if (_moleScriptPath == null) return;
    try {
      final res = Process.runSync(_moleScriptPath!, ['--version']);
      final out = res.stdout.toString().trim();
      if (out.isNotEmpty) {
        final verMatch = RegExp(r'(\d+\.\d+(\.\d+)?)').firstMatch(out);
        if (verMatch != null) {
          _moleVersion = verMatch.group(1) ?? '1.51';
        }
      }
    } catch (_) {}
  }

  Future<ProcessResult?> runMoleCli(List<String> args, {Function(String log)? onLog}) async {
    if (_moleScriptPath == null) {
      onLog?.call('Error: Mole CLI executable not found.');
      return null;
    }
    try {
      onLog?.call('Executing: $_moleScriptPath ${args.join(" ")}');
      final result = await Process.run(_moleScriptPath!, args);
      if (result.stdout.toString().isNotEmpty) {
        onLog?.call(result.stdout.toString().trim());
      }
      if (result.stderr.toString().isNotEmpty) {
        onLog?.call(result.stderr.toString().trim());
      }
      return result;
    } catch (e) {
      onLog?.call('Failed to execute Mole CLI: $e');
      return null;
    }
  }

  bool rescan() {
    _detectMolePath();
    return isFound;
  }

  String? get brewPath {
    final candidates = ['/opt/homebrew/bin/brew', '/usr/local/bin/brew'];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    try {
      final res = Process.runSync('which', ['brew']);
      final path = res.stdout.toString().trim();
      if (path.isNotEmpty && File(path).existsSync()) return path;
    } catch (_) {}
    return null;
  }

  bool get isHomebrewInstalled => brewPath != null;

  Future<bool> installViaHomebrew(Function(String log) onLog) async {
    final brew = brewPath;
    if (brew == null) {
      onLog('Homebrew was not found on this Mac. Please install Homebrew first or use curl.');
      return false;
    }

    try {
      onLog('Running: $brew install mole');
      final process = await Process.start(
        brew,
        ['install', 'mole'],
        environment: {'HOME': homeDir, 'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'},
      );

      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog(line.trim());
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog(line.trim());
        }
      });

      final exitCode = await process.exitCode;
      if (exitCode == 0) {
        onLog('Homebrew installed Mole successfully!');
        rescan();
        return isFound;
      } else {
        onLog('Homebrew installation finished with code $exitCode');
        rescan();
        return isFound;
      }
    } catch (e) {
      onLog('Error installing via Homebrew: $e');
      return false;
    }
  }

  Future<bool> installViaCurl(Function(String log) onLog) async {
    try {
      onLog('Running: curl -fsSL https://mole.fit/install.sh | bash');
      final process = await Process.start(
        'bash',
        ['-c', 'curl -fsSL https://mole.fit/install.sh | bash'],
        environment: {'HOME': homeDir, 'PATH': '/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin'},
      );

      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog(line.trim());
        }
      });

      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        for (final line in data.split('\n')) {
          if (line.trim().isNotEmpty) onLog(line.trim());
        }
      });

      final exitCode = await process.exitCode;
      onLog('Curl script finished with code $exitCode');
      rescan();
      return isFound;
    } catch (e) {
      onLog('Error installing via curl: $e');
      return false;
    }
  }

  String get homeDir {
    return Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER'] ?? 'unknown'}';
  }

  // ==========================================
  // SYSTEM CLEANER (Caches, Logs, Leftovers, Trash)
  // ==========================================

  Future<List<CleanCategory>> scanSystemCleanables() async {
    LoggerService.i('Starting system clean scan...');
    final List<CleanCategory> categories = [];

    // 1. User Caches (~/Library/Caches)
    final userCaches = await _scanDirectoryItems('$homeDir/Library/Caches', 'User Caches');
    if (userCaches.isNotEmpty) {
      categories.add(
        CleanCategory(
          id: 'user_caches',
          title: 'User Caches',
          description: 'Application cache files that can be safely recreated',
          iconName: 'cube_box',
          items: userCaches,
        ),
      );
    }

    // 2. System & User Logs (~/Library/Logs)
    final logs = await _scanDirectoryItems('$homeDir/Library/Logs', 'Logs');
    if (logs.isNotEmpty) {
      categories.add(
        CleanCategory(
          id: 'logs',
          title: 'System & App Logs',
          description: 'Diagnostic logs and historical traces',
          iconName: 'doc_text',
          items: logs,
        ),
      );
    }

    // 3. Developer & Xcode Caches (~/Library/Developer/Xcode/DerivedData, etc.)
    final devItems = <CleanItem>[];
    final derivedData = Directory('$homeDir/Library/Developer/Xcode/DerivedData');
    if (derivedData.existsSync()) {
      final size = await _calculateDirSize(derivedData);
      if (size > 0) {
        devItems.add(
          CleanItem(
            id: 'xcode_derived_data',
            name: 'Xcode DerivedData',
            path: derivedData.path,
            sizeBytes: size,
            category: 'Developer Caches',
            isChecked: true,
          ),
        );
      }
    }
    final archives = Directory('$homeDir/Library/Developer/Xcode/Archives');
    if (archives.existsSync()) {
      final size = await _calculateDirSize(archives);
      if (size > 0) {
        devItems.add(
          CleanItem(
            id: 'xcode_archives',
            name: 'Xcode Archives',
            path: archives.path,
            sizeBytes: size,
            category: 'Developer Caches',
            isChecked: false,
          ),
        );
      }
    }
    final cocoapods = Directory('$homeDir/Library/Caches/CocoaPods');
    if (cocoapods.existsSync()) {
      final size = await _calculateDirSize(cocoapods);
      if (size > 0) {
        devItems.add(
          CleanItem(
            id: 'cocoapods_cache',
            name: 'CocoaPods Cache',
            path: cocoapods.path,
            sizeBytes: size,
            category: 'Developer Caches',
            isChecked: true,
          ),
        );
      }
    }
    if (devItems.isNotEmpty) {
      categories.add(
        CleanCategory(
          id: 'developer_caches',
          title: 'Developer Artifacts',
          description: 'Xcode build outputs, derived data, and package caches',
          iconName: 'hammer',
          items: devItems,
        ),
      );
    }

    // 4. Browser Caches (Chrome, Safari, Arc, Firefox)
    final browserItems = await _scanBrowserCaches();
    if (browserItems.isNotEmpty) {
      categories.add(
        CleanCategory(
          id: 'browser_caches',
          title: 'Browser Data & Caches',
          description: 'Web caching from Chrome, Safari, Arc, and Firefox',
          iconName: 'globe',
          items: browserItems,
        ),
      );
    }

    // 5. App Leftovers (Orphaned folders in Application Support / Containers)
    final leftoverItems = await _scanAppLeftovers();
    if (leftoverItems.isNotEmpty) {
      categories.add(
        CleanCategory(
          id: 'app_leftovers',
          title: 'App Leftovers',
          description: 'Remnants of uninstalled applications',
          iconName: 'trash_can',
          items: leftoverItems,
        ),
      );
    }

    // 6. Trash (~/.Trash)
    final trashDir = Directory('$homeDir/.Trash');
    if (trashDir.existsSync()) {
      final trashSize = await _calculateDirSize(trashDir);
      if (trashSize > 0) {
        categories.add(
          CleanCategory(
            id: 'trash',
            title: 'Trash Bin',
            description: 'Items currently in macOS Trash',
            iconName: 'trash',
            items: [
              CleanItem(
                id: 'user_trash',
                name: 'Trash Bin Items',
                path: trashDir.path,
                sizeBytes: trashSize,
                category: 'Trash Bin',
                isChecked: true,
              ),
            ],
          ),
        );
      }
    }

    return categories;
  }

  Future<List<CleanItem>> _scanDirectoryItems(String dirPath, String category) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return [];

    final List<CleanItem> items = [];
    try {
      final entries = dir.listSync(followLinks: false);
      for (final entry in entries) {
        try {
          final size = entry is Directory ? await _calculateDirSize(entry) : await (entry as File).length();
          if (size > 1024 * 100) {
            // Only show items > 100KB to keep UI clean
            final name = entry.path.split('/').last;
            items.add(
              CleanItem(
                id: entry.path,
                name: name,
                path: entry.path,
                sizeBytes: size,
                category: category,
                isChecked: true,
              ),
            );
          }
        } catch (_) {}
      }
    } catch (e) {
      LoggerService.w('Error scanning $dirPath: $e');
    }
    // Sort descending by size
    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return items;
  }

  Future<List<CleanItem>> _scanBrowserCaches() async {
    final items = <CleanItem>[];
    final browserPaths = {
      'Google Chrome': '$homeDir/Library/Caches/Google/Chrome',
      'Arc Browser': '$homeDir/Library/Caches/company.thebrowser.Browser',
      'Mozilla Firefox': '$homeDir/Library/Caches/Firefox',
      'Brave Browser': '$homeDir/Library/Caches/BraveSoftware/Brave-Browser',
      'Microsoft Edge': '$homeDir/Library/Caches/Microsoft Edge',
    };

    for (final entry in browserPaths.entries) {
      final dir = Directory(entry.value);
      if (dir.existsSync()) {
        final size = await _calculateDirSize(dir);
        if (size > 0) {
          items.add(
            CleanItem(
              id: entry.value,
              name: entry.key,
              path: entry.value,
              sizeBytes: size,
              category: 'Browser Caches',
              isChecked: true,
            ),
          );
        }
      }
    }
    return items;
  }

  Future<List<CleanItem>> _scanAppLeftovers() async {
    final items = <CleanItem>[];
    final appSupport = Directory('$homeDir/Library/Application Support');
    if (!appSupport.existsSync()) return items;

    // Get list of currently installed app names in /Applications and ~/Applications
    final installedApps = <String>{};
    for (final appDir in ['/Applications', '$homeDir/Applications']) {
      final dir = Directory(appDir);
      if (dir.existsSync()) {
        try {
          for (final f in dir.listSync()) {
            if (f.path.endsWith('.app')) {
              installedApps.add(f.path.split('/').last.replaceAll('.app', '').toLowerCase());
            }
          }
        } catch (_) {}
      }
    }

    try {
      for (final f in appSupport.listSync(followLinks: false)) {
        if (f is Directory) {
          final folderName = f.path.split('/').last.toLowerCase();
          // Exclude system folders
          if (folderName.startsWith('apple') ||
              folderName.startsWith('com.apple') ||
              folderName == 'crashreporter' ||
              folderName == 'dock') {
            continue;
          }
          // If not matching any installed app
          final matches = installedApps.any((app) => folderName.contains(app) || app.contains(folderName));
          if (!matches) {
            final size = await _calculateDirSize(f);
            if (size > 1024 * 1024 * 5) {
              // Leftovers > 5MB
              items.add(
                CleanItem(
                  id: f.path,
                  name: f.path.split('/').last,
                  path: f.path,
                  sizeBytes: size,
                  category: 'App Leftovers',
                  isChecked: false, // Default unchecked for safety
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      LoggerService.w('Leftover scan error: $e');
    }
    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return items;
  }

  Future<int> _calculateDirSize(Directory dir) async {
    int total = 0;
    try {
      final result = await Process.run('du', ['-sk', dir.path]);
      final out = result.stdout.toString().trim();
      final kb = int.tryParse(out.split(RegExp(r'\s+')).first) ?? 0;
      total = kb * 1024;
    } catch (_) {
      try {
        await for (final entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            total += await entity.length();
          }
        }
      } catch (_) {}
    }
    return total;
  }

  Future<void> executeCleanup(
    List<CleanItem> itemsToClean,
    Function(String progress, double fraction) onProgress,
  ) async {
    int count = 0;
    final total = itemsToClean.length;

    for (final item in itemsToClean) {
      count++;
      onProgress('Cleaning ${item.name}...', count / total);
      try {
        final f = File(item.path);
        if (f.existsSync()) {
          await f.delete();
          continue;
        }
        final d = Directory(item.path);
        if (d.existsSync()) {
          // If clearing Trash, empty contents
          if (item.id == 'user_trash') {
            for (final entity in d.listSync()) {
              try {
                if (entity is Directory) {
                  entity.deleteSync(recursive: true);
                } else {
                  entity.deleteSync();
                }
              } catch (_) {}
            }
          } else {
            await d.delete(recursive: true);
          }
        }
      } catch (e) {
        LoggerService.w('Could not delete ${item.path}: $e');
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }
    onProgress('Cleanup completed!', 1.0);
  }

  // ==========================================
  // UNINSTALLER (Applications & Remnants)
  // ==========================================

  Future<List<AppInfo>> scanInstalledApps() async {
    final List<AppInfo> apps = [];
    final appDirs = ['/Applications', '$homeDir/Applications', '/System/Applications'];

    for (final dirPath in appDirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      try {
        final entries = dir.listSync(followLinks: false);
        for (final entry in entries) {
          if (entry.path.endsWith('.app') && entry is Directory) {
            final appName = entry.path.split('/').last.replaceAll('.app', '');
            final appSize = await _calculateDirSize(entry);

            // Find associated remnant paths
            final remnants = await _findAppRemnants(appName);
            final remnantSize = remnants.fold<int>(0, (sum, p) => sum + p.sizeBytes);

            apps.add(
              AppInfo(
                id: entry.path,
                name: appName,
                bundlePath: entry.path,
                appSizeBytes: appSize,
                associatedSizeBytes: remnantSize,
                isSystemApp: dirPath.startsWith('/System'),
                associatedPaths: remnants,
              ),
            );
          }
        }
      } catch (e) {
        LoggerService.w('Error scanning apps in $dirPath: $e');
      }
    }

    apps.sort((a, b) => b.totalSizeBytes.compareTo(a.totalSizeBytes));
    return apps;
  }

  Future<List<AppRemnant>> _findAppRemnants(String appName) async {
    final searchName = appName.toLowerCase().replaceAll(' ', '');
    final remnants = <AppRemnant>[];

    final locations = [
      ('$homeDir/Library/Application Support', 'App Support'),
      ('$homeDir/Library/Caches', 'Caches'),
      ('$homeDir/Library/Preferences', 'Preferences'),
      ('$homeDir/Library/Saved Application State', 'Saved State'),
      ('$homeDir/Library/Containers', 'Containers'),
      ('$homeDir/Library/Logs', 'Logs'),
    ];

    for (final (loc, desc) in locations) {
      final dir = Directory(loc);
      if (!dir.existsSync()) continue;
      try {
        for (final item in dir.listSync(followLinks: false)) {
          final itemName = item.path.split('/').last.toLowerCase().replaceAll(' ', '');
          if (itemName.contains(searchName)) {
            final size = item is Directory ? await _calculateDirSize(item) : await (item as File).length();
            remnants.add(AppRemnant(path: item.path, description: desc, sizeBytes: size));
          }
        }
      } catch (_) {}
    }
    return remnants;
  }

  Future<void> uninstallApp(AppInfo app, Function(String status, double progress) onProgress) async {
    onProgress('Deleting application bundle...', 0.2);
    try {
      final appDir = Directory(app.bundlePath);
      if (appDir.existsSync()) {
        await appDir.delete(recursive: true);
      }
    } catch (e) {
      LoggerService.e('Failed to delete app bundle: ${app.bundlePath}', e);
    }

    int count = 0;
    final total = app.associatedPaths.length;
    for (final remnant in app.associatedPaths) {
      count++;
      onProgress('Removing remnant: ${remnant.path.split('/').last}', 0.2 + (0.8 * (count / (total > 0 ? total : 1))));
      try {
        final d = Directory(remnant.path);
        if (d.existsSync()) {
          await d.delete(recursive: true);
          continue;
        }
        final f = File(remnant.path);
        if (f.existsSync()) {
          await f.delete();
        }
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 20));
    }
    onProgress('Uninstalled ${app.name} successfully', 1.0);
  }

  // ==========================================
  // PROJECT BUILD PURGE (node_modules, target, build, etc.)
  // ==========================================

  Future<List<PurgeItem>> scanProjectBuildArtifacts(List<String> roots) async {
    final List<PurgeItem> artifacts = [];
    final targetDirs = {
      'node_modules': 'Node.js dependencies',
      '.dart_tool': 'Dart / Flutter tool cache',
      'build': 'Build output directory',
      'target': 'Rust / Cargo build output',
      '.gradle': 'Gradle build cache',
      '.venv': 'Python Virtualenv',
      'Pods': 'CocoaPods directory',
      'DerivedData': 'Xcode DerivedData',
      'dist': 'Distribution bundle',
    };

    for (final rootPath in roots) {
      final rootDir = Directory(rootPath);
      if (!rootDir.existsSync()) continue;

      try {
        await _scanDirForArtifacts(rootDir, targetDirs, artifacts, 0, 5);
      } catch (e) {
        LoggerService.w('Error scanning purge root $rootPath: $e');
      }
    }

    artifacts.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return artifacts;
  }

  Future<void> _scanDirForArtifacts(
    Directory dir,
    Map<String, String> targets,
    List<PurgeItem> result,
    int depth,
    int maxDepth,
  ) async {
    if (depth > maxDepth) return;

    try {
      final entries = dir.listSync(followLinks: false);
      for (final entry in entries) {
        if (entry is Directory) {
          final name = entry.path.split('/').last;

          if (targets.containsKey(name)) {
            final size = await _calculateDirSize(entry);
            if (size > 1024 * 1024) {
              // > 1MB
              result.add(
                PurgeItem(
                  id: entry.path,
                  name: name,
                  projectPath: dir.path,
                  path: entry.path,
                  sizeBytes: size,
                  type: targets[name] ?? 'Build Artifact',
                  isChecked: false,
                ),
              );
            }
          } else if (!name.startsWith('.') && !name.startsWith('Library') && !name.startsWith('Applications')) {
            await _scanDirForArtifacts(entry, targets, result, depth + 1, maxDepth);
          }
        }
      }
    } catch (_) {}
  }

  // ==========================================
  // INSTALLER SCANNER (.dmg, .pkg, .iso)
  // ==========================================

  Future<List<InstallerFile>> scanInstallers() async {
    final List<InstallerFile> installers = [];
    final scanDirs = ['$homeDir/Downloads', '$homeDir/Desktop', '$homeDir/Documents'];

    final extensions = ['.dmg', '.pkg', '.iso'];

    for (final dirPath in scanDirs) {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      try {
        for (final entity in dir.listSync(followLinks: false)) {
          if (entity is File) {
            final name = entity.path.split('/').last;
            final isMatch = extensions.any((ext) => name.toLowerCase().endsWith(ext));
            if (isMatch) {
              final size = await entity.length();
              installers.add(
                InstallerFile(
                  id: entity.path,
                  name: name,
                  path: entity.path,
                  sizeBytes: size,
                  extension: name.split('.').last.toUpperCase(),
                  isChecked: true,
                ),
              );
            }
          }
        }
      } catch (_) {}
    }

    installers.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return installers;
  }

  // ==========================================
  // SYSTEM OPTIMIZATIONS
  // ==========================================

  Future<void> runOptimization(OptimizationTask task, Function(String log) onLog) async {
    onLog('Running: ${task.name}...');
    switch (task.id) {
      case 'flush_dns':
        await Process.run('dscacheutil', ['-flushcache']);
        await Process.run('killall', ['-HUP', 'mDNSResponder']);
        onLog('DNS Cache flushed successfully.');
        break;
      case 'purge_ram':
        await Process.run('purge', []);
        onLog('Purged inactive RAM pages.');
        break;
      case 'rebuild_launchservices':
        final lsregister =
            '/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister';
        if (File(lsregister).existsSync()) {
          await Process.run(lsregister, ['-kill', '-r', '-domain', 'local', '-domain', 'system', '-domain', 'user']);
          onLog('LaunchServices database rebuilt.');
        }
        break;
      case 'font_cache':
        await Process.run('atsutil', ['databases', '-remove']);
        onLog('Font caches cleared.');
        break;
      default:
        onLog('Optimization complete.');
    }
  }
}
