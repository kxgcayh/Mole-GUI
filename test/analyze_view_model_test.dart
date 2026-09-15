import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mole_gui/features/analyze/domain/disk_node.dart';
import 'package:mole_gui/features/analyze/presentation/analyze_view_model.dart';

void main() {
  test('DiskNode calculates properties and aggregation correctly', () {
    const node = DiskNode(
      path: '/Users/test/Downloads',
      name: 'Downloads',
      sizeBytes: 1024 * 1024 * 500, // 500MB
      isDirectory: true,
    );

    expect(node.name, 'Downloads');
    expect(node.isDirectory, true);
    expect(node.isOtherGroup, false);

    const groupNode = DiskNode(
      path: '',
      name: '53 items',
      sizeBytes: 1024 * 1024 * 200,
      isDirectory: true,
      itemCount: 53,
    );
    expect(groupNode.isOtherGroup, true);
  });

  test('AnalyzeViewModel initializes with default state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(analyzeViewModelProvider);
    expect(state.breadcrumbs.isNotEmpty, true);
    expect(state.currentPath.isNotEmpty, true);
  });
}
