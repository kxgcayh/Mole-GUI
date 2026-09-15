import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mole_gui/features/setup/presentation/setup_view_model.dart';

void main() {
  test('SetupViewModel initializes and allows skipping setup', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(setupViewModelProvider);
    expect(state.isInstalling, false);
    expect(state.isSkipped, false);

    container.read(setupViewModelProvider.notifier).skipSetup();
    final updatedState = container.read(setupViewModelProvider);
    expect(updatedState.isSkipped, true);
  });
}
