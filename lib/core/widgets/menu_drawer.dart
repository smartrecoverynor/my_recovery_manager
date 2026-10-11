import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme_controller.dart';

class MenuDrawer extends StatelessWidget {
  final ThemeController themeController;

  const MenuDrawer({
    super.key,
    required this.themeController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Text(
                'My Recovery Manager',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Utseende',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),

            Column(
              children: [
                Container(
                  width: 186,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: colors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.light,
                        icon: Icons.light_mode_outlined,
                        isSelected:
                        themeController.themeMode == ThemeMode.light,
                      ),
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.system,
                        icon: Icons.brightness_auto_outlined,
                        isSelected:
                        themeController.themeMode == ThemeMode.system,
                      ),
                      _buildThemeOption(
                        context,
                        mode: ThemeMode.dark,
                        icon: Icons.dark_mode_outlined,
                        isSelected:
                        themeController.themeMode == ThemeMode.dark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: 186,
                  child: Row(
                    children: [
                      _buildThemeLabel(
                        context,
                        'Lys',
                        ThemeMode.light,
                        themeController.themeMode,
                      ),
                      _buildThemeLabel(
                        context,
                        'Auto',
                        ThemeMode.system,
                        themeController.themeMode,
                      ),
                      _buildThemeLabel(
                        context,
                        'Mørk',
                        ThemeMode.dark,
                        themeController.themeMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            const Divider(),

            _buildMenuItem(
              context,
              icon: Icons.person_outline,
              title: 'Min profil',
            ),

            _buildMenuItem(
              context,
              icon: Icons.bar_chart_outlined,
              title: 'Statistikk og eksport',
              route: '/statistics-export',
            ),

            _buildMenuItem(
              context,
              icon: Icons.settings_outlined,
              title: 'Innstillinger',
            ),

            _buildMenuItem(
              context,
              icon: Icons.lock_outline,
              title: 'Data og personvern',
              route: '/data-privacy',
            ),

            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Hjelp og informasjon',
            ),

            _buildMenuItem(
              context,
              icon: Icons.info_outline,
              title: 'Om My Recovery Manager',
            ),

            const Spacer(),

            const Divider(),

            _buildMenuItem(
              context,
              icon: Icons.logout,
              title: 'Logg ut',
              isLogout: true,
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
      BuildContext context, {
        required ThemeMode mode,
        required IconData icon,
        required bool isSelected,
      }) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          themeController.setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.secondary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(27),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? Colors.black
                  : colors.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeLabel(
      BuildContext context,
      String label,
      ThemeMode mode,
      ThemeMode selectedMode,
      ) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = mode == selectedMode;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight:
            isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? colors.secondary
                : colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? route,
        bool isLogout = false,
      }) {
    final colors = Theme.of(context).colorScheme;

    final itemColor = isLogout
        ? const Color(0xFFC95C5C)
        : colors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 4,
      ),
      leading: Icon(
        icon,
        color: itemColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isLogout
              ? itemColor
              : colors.onSurface,
        ),
      ),
      onTap: () {
        if (route != null) {
          Navigator.of(context).pop();
          context.go(route);
        }
      },
    );
  }
}