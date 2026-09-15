import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/services/mole_cli_service.dart';

class SetupState {
  final bool isCliFound;
  final bool isHomebrewAvailable;
  final String? cliPath;
  final String cliVersion;
  final bool isInstalling;
  final bool isSkipped;
  final String? errorMessage;
  final List<String> logs;

  const SetupState({
    required this.isCliFound,
    required this.isHomebrewAvailable,
    this.cliPath,
    this.cliVersion = '1.51',
    this.isInstalling = false,
    this.isSkipped = false,
    this.errorMessage,
    this.logs = const [],
  });

  SetupState copyWith({
    bool? isCliFound,
    bool? isHomebrewAvailable,
    String? cliPath,
    String? cliVersion,
    bool? isInstalling,
    bool? isSkipped,
    String? errorMessage,
    List<String>? logs,
  }) {
    return SetupState(
      isCliFound: isCliFound ?? this.isCliFound,
      isHomebrewAvailable: isHomebrewAvailable ?? this.isHomebrewAvailable,
      cliPath: cliPath ?? this.cliPath,
      cliVersion: cliVersion ?? this.cliVersion,
      isInstalling: isInstalling ?? this.isInstalling,
      isSkipped: isSkipped ?? this.isSkipped,
      errorMessage: errorMessage,
      logs: logs ?? this.logs,
    );
  }
}

final setupViewModelProvider = NotifierProvider<SetupViewModel, SetupState>(() {
  return SetupViewModel();
});

class SetupViewModel extends Notifier<SetupState> {
  MoleCliService get _cliService => ref.read(moleCliServiceProvider);

  @override
  SetupState build() {
    return _calculateCurrentState();
  }

  SetupState _calculateCurrentState() {
    return SetupState(
      isCliFound: _cliService.isFound,
      isHomebrewAvailable: _cliService.isHomebrewInstalled,
      cliPath: _cliService.molePath,
      cliVersion: _cliService.moleVersion,
      isInstalling: false,
      isSkipped: false,
      logs: [],
    );
  }

  void checkStatus() {
    _cliService.rescan();
    state = state.copyWith(
      isCliFound: _cliService.isFound,
      isHomebrewAvailable: _cliService.isHomebrewInstalled,
      cliPath: _cliService.molePath,
      cliVersion: _cliService.moleVersion,
    );
  }

  void skipSetup() {
    state = state.copyWith(isSkipped: true);
  }

  Future<void> installWithHomebrew() async {
    if (state.isInstalling) return;

    state = state.copyWith(
      isInstalling: true,
      errorMessage: null,
      logs: ['[Mole Setup] Initializing Homebrew installation...'],
    );

    try {
      final success = await _cliService.installViaHomebrew((log) {
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: [...state.logs, log],
        );
      });

      if (!ref.mounted) return;

      if (success) {
        state = state.copyWith(
          isInstalling: false,
          isCliFound: true,
          cliPath: _cliService.molePath,
          cliVersion: _cliService.moleVersion,
          logs: [...state.logs, '✓ Mole CLI installed successfully!'],
        );
      } else {
        state = state.copyWith(
          isInstalling: false,
          errorMessage: 'Homebrew installation was incomplete. Try manual terminal install or curl.',
          logs: [...state.logs, '✗ Installation incomplete.'],
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      LoggerService.e('Failed to install Mole CLI via Homebrew', e);
      state = state.copyWith(
        isInstalling: false,
        errorMessage: 'Failed to install: $e',
        logs: [...state.logs, '✗ Error: $e'],
      );
    }
  }

  Future<void> installWithCurl() async {
    if (state.isInstalling) return;

    state = state.copyWith(
      isInstalling: true,
      errorMessage: null,
      logs: ['[Mole Setup] Downloading and installing via official install script...'],
    );

    try {
      final success = await _cliService.installViaCurl((log) {
        if (!ref.mounted) return;
        state = state.copyWith(
          logs: [...state.logs, log],
        );
      });

      if (!ref.mounted) return;

      if (success) {
        state = state.copyWith(
          isInstalling: false,
          isCliFound: true,
          cliPath: _cliService.molePath,
          cliVersion: _cliService.moleVersion,
          logs: [...state.logs, '✓ Mole CLI installed successfully!'],
        );
      } else {
        state = state.copyWith(
          isInstalling: false,
          errorMessage: 'Curl script installation did not complete. Try running in Terminal.',
          logs: [...state.logs, '✗ Installation incomplete.'],
        );
      }
    } catch (e) {
      if (!ref.mounted) return;
      LoggerService.e('Failed to install Mole CLI via curl', e);
      state = state.copyWith(
        isInstalling: false,
        errorMessage: 'Failed to install: $e',
        logs: [...state.logs, '✗ Error: $e'],
      );
    }
  }
}
