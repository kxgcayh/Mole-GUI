import 'dart:math';

class ByteFormatter {
  static String format(int bytes, {int decimals = 1}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedI = i.clamp(0, suffixes.length - 1);
    final size = bytes / pow(1024, clampedI);
    return '${size.toStringAsFixed(decimals)} ${suffixes[clampedI]}';
  }

  static int parse(String sizeStr) {
    final cleaned = sizeStr.trim().toUpperCase();
    if (cleaned.isEmpty) return 0;

    final regex = RegExp(r'^([\d.]+)\s*([KMGTPE]?B?)$');
    final match = regex.firstMatch(cleaned);
    if (match == null) return 0;

    final numVal = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = match.group(2) ?? '';

    if (unit.startsWith('T')) return (numVal * 1024 * 1024 * 1024 * 1024).round();
    if (unit.startsWith('G')) return (numVal * 1024 * 1024 * 1024).round();
    if (unit.startsWith('M')) return (numVal * 1024 * 1024).round();
    if (unit.startsWith('K')) return (numVal * 1024).round();
    return numVal.round();
  }
}
