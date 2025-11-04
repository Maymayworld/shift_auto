// screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';
import 'dashboard_screen.dart';
import 'shift_management_screen.dart';
import 'shift_edit_screen.dart';
import 'store_settings_screen.dart';
import 'skill_management_screen.dart';
import 'people_management_screen.dart';
import 'help_screen.dart';

class MainLayout extends HookConsumerWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // AppBar（最上部・固定）
          Container(
            height: 60,
            color: backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'ShiftAuto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Spacer(),
                CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person, color: primaryColor),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // サイドバーとメインコンテンツ
          Expanded(
            child: Row(
              children: [
                // サイドバー（固定）
                Container(
                  width: 250,
                  color: primaryColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // サイドバーメニュー
                      _buildMenuItem(
                        icon: Icons.home,
                        label: 'ホーム',
                        isSelected: navigationState.screenType == ScreenType.dashboard,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .navigateTo(ScreenType.dashboard),
                      ),
                      _buildMenuItem(
                        icon: Icons.edit_calendar,
                        label: 'シフト管理',
                        isSelected: navigationState.screenType == ScreenType.shiftManagement ||
                            navigationState.screenType == ScreenType.shiftEdit,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .navigateTo(ScreenType.shiftManagement),
                      ),
                      _buildMenuItem(
                        icon: Icons.people,
                        label: 'スタッフ管理',
                        isSelected: navigationState.screenType == ScreenType.peopleManagement,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .navigateTo(ScreenType.peopleManagement),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        label: '店舗情報',
                        isSelected: navigationState.screenType == ScreenType.storeSettings ||
                            navigationState.screenType == ScreenType.skillManagement,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .navigateTo(ScreenType.storeSettings),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        label: '使い方',
                        isSelected: navigationState.screenType == ScreenType.help,
                        onTap: () => ref
                            .read(navigationProvider.notifier)
                            .navigateTo(ScreenType.help),
                      ),
                    ],
                  ),
                ),
                // メインコンテンツエリア（切り替わる）
                Expanded(
                  child: _buildMainContent(navigationState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(NavigationState navigationState) {
    switch (navigationState.screenType) {
      case ScreenType.dashboard:
        return const DashboardScreen();
      case ScreenType.shiftManagement:
        return const ShiftManagementScreen();
      case ScreenType.shiftEdit:
        final shiftId = navigationState.params['shiftId'] as String;
        final date = navigationState.params['date'] as DateTime;
        final shiftType = navigationState.params['shiftType'] as String;
        return ShiftEditScreen(
          shiftId: shiftId,
          date: date,
          shiftType: shiftType,
        );
      case ScreenType.storeSettings:
        return const StoreSettingsScreen();
      case ScreenType.skillManagement:
        return const SkillManagementScreen();
      case ScreenType.peopleManagement:
        return const PeopleManagementScreen();
      case ScreenType.help:
        return const HelpScreen();
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}