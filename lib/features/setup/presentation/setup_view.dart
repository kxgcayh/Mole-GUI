import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/action_button.dart';
import '../../../core/widgets/glass_card.dart';
import 'setup_view_model.dart';

class SetupView extends ConsumerWidget {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupViewModelProvider);
    final viewModel = ref.read(setupViewModelProvider.notifier);

    // Auto-advance if CLI is found
    ref.listen(setupViewModelProvider, (previous, next) {
      if (next.isCliFound || next.isSkipped) {
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header & Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accentCyan],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Center(
                            child: Icon(CupertinoIcons.shield_fill, color: Colors.white, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome to Mole GUI',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Mole CLI Engine is required to perform deep cleaning and optimizations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),

                // Prerequisite Status Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            state.isHomebrewAvailable
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.exclamationmark_triangle_fill,
                            color: state.isHomebrewAvailable ? AppColors.accentGreen : AppColors.accentOrange,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isHomebrewAvailable
                                      ? 'Homebrew Package Manager Detected'
                                      : 'Homebrew Not Found',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.isHomebrewAvailable
                                      ? 'You can install Mole with a single click below.'
                                      : 'You can install via official curl script or install Homebrew first.',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),

                      // One-Click Homebrew Install
                      if (state.isHomebrewAvailable) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Option 1: Recommended (1-Click)',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Runs `brew install mole` automatically',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            ActionButton(
                              label: state.isInstalling ? 'Installing...' : 'Install via Homebrew',
                              icon: CupertinoIcons.arrow_down_circle_fill,
                              gradient: AppColors.cleanGradient,
                              isLoading: state.isInstalling,
                              onPressed: state.isInstalling ? null : () => viewModel.installWithHomebrew(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Curl script install
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.isHomebrewAvailable ? 'Option 2: Direct Script' : 'Option 1: Direct Script',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Runs `curl -fsSL https://mole.fit/install.sh | bash`',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          ActionButton(
                            label: state.isInstalling ? 'Installing...' : 'Install via Curl',
                            icon: CupertinoIcons.chevron_left_slash_chevron_right,
                            gradient: AppColors.cpuGradient,
                            isLoading: state.isInstalling,
                            onPressed: state.isInstalling ? null : () => viewModel.installWithCurl(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Manual Command Copy
                      const Text(
                        'Manual Terminal Command:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.darkBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.darkCardBorder),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: SelectableText(
                                'brew install mole',
                                style: TextStyle(
                                  fontFamily: 'Menlo',
                                  fontSize: 12,
                                  color: AppColors.accentCyan,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 16, color: AppColors.textSecondary),
                              tooltip: 'Copy Command',
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(text: 'brew install mole'));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Command copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Terminal Output Drawer
                if (state.logs.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Installation Terminal Logs',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (state.isInstalling)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.darkCardBorder),
                          ),
                          child: ListView.builder(
                            itemCount: state.logs.length,
                            itemBuilder: (context, index) {
                              final log = state.logs[index];
                              return Text(
                                log,
                                style: const TextStyle(
                                  fontFamily: 'Menlo',
                                  fontSize: 10,
                                  color: AppColors.accentGreen,
                                  height: 1.4,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Bottom actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(CupertinoIcons.arrow_clockwise, size: 14),
                      label: const Text('Check Status Again'),
                      onPressed: state.isInstalling ? null : () => viewModel.checkStatus(),
                    ),
                    TextButton(
                      child: const Text('Continue in GUI-Only Mode →', style: TextStyle(color: AppColors.textSecondary)),
                      onPressed: () {
                        viewModel.skipSetup();
                        context.go('/');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
