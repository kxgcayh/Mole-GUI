import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/mole_cli_service.dart';

class SidebarDestination {
  final String route;
  final String title;
  final IconData icon;
  final String? badge;

  const SidebarDestination({
    required this.route,
    required this.title,
    required this.icon,
    this.badge,
  });
}

class MacosSidebar extends ConsumerWidget {
  final String currentRoute;
  final Function(String route) onSelectRoute;

  const MacosSidebar({
    super.key,
    required this.currentRoute,
    required this.onSelectRoute,
  });

  static const List<SidebarDestination> destinations = [
    SidebarDestination(
      route: '/',
      title: 'Dashboard',
      icon: CupertinoIcons.speedometer,
    ),
    SidebarDestination(
      route: '/analyze',
      title: 'Disk Analyzer',
      icon: CupertinoIcons.chart_pie_fill,
    ),
    SidebarDestination(
      route: '/cleaner',
      title: 'System Cleaner',
      icon: CupertinoIcons.sparkles,
    ),
    SidebarDestination(
      route: '/uninstaller',
      title: 'App Uninstaller',
      icon: CupertinoIcons.app_badge,
    ),
    SidebarDestination(
      route: '/purge',
      title: 'Project Purge',
      icon: CupertinoIcons.hammer,
    ),
    SidebarDestination(
      route: '/optimizer',
      title: 'Maintenance',
      icon: CupertinoIcons.slider_horizontal_3,
    ),
    SidebarDestination(
      route: '/installers',
      title: 'Installers',
      icon: CupertinoIcons.arrow_down_doc,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moleService = ref.watch(moleCliServiceProvider);
    final isHomebrew = moleService.isHomebrew;
    final isFound = moleService.isFound;
    final version = moleService.moleVersion;

    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColors.darkSidebarBg,
        border: Border(
          right: BorderSide(
            color: AppColors.darkCardBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Header
          Padding(
            padding: const EdgeInsets.only(top: 40, left: 20, right: 20, bottom: 24),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.accentCyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(CupertinoIcons.shield_fill, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mole GUI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Mac Optimization GUI',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Text(
              'CLEAN & OPTIMIZE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // Navigation Links
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final isSelected = currentRoute == dest.route;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => onSelectRoute(dest.route),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.25) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight.withValues(alpha: 0.4) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              dest.icon,
                              size: 18,
                              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dest.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (dest.badge != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  dest.badge!,
                                  style: const TextStyle(fontSize: 10, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer info with Homebrew Mole indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.darkCardBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkCardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    isFound ? CupertinoIcons.checkmark_shield_fill : CupertinoIcons.exclamationmark_triangle_fill,
                    size: 16,
                    color: isFound ? AppColors.accentGreen : AppColors.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mole Core v$version',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isHomebrew ? 'Homebrew Engine' : (isFound ? 'Local Engine' : 'CLI not found'),
                          style: TextStyle(
                            fontSize: 9,
                            color: isHomebrew ? AppColors.accentCyan : AppColors.textSecondary,
                            fontWeight: isHomebrew ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
