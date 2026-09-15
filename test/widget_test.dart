import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mole_gui/core/services/system_info_service.dart';
import 'package:mole_gui/main.dart';

void main() {
  testWidgets('Mole App initial smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        systemInfoServiceProvider.overrideWithValue(SystemInfoService(autoStart: false)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MoleApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(MoleApp), findsOneWidget);
  });
}
