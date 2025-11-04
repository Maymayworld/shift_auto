// screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'shift_management_screen.dart';
import 'store_settings_screen.dart';
import 'help_screen.dart';

class MainLayout extends HookConsumerWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = useState(0);

    final screens = [
      const DashboardScreen(),
      const ShiftManagementScreen(),
      const StoreSettingsScreen(),
      const HelpScreen(),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // AppBar（最上部）
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
                // サイドバー
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
                        isSelected: selectedIndex.value == 0,
                        onTap: () => selectedIndex.value = 0,
                      ),
                      _buildMenuItem(
                        icon: Icons.edit_calendar,
                        label: 'シフト管理',
                        isSelected: selectedIndex.value == 1,
                        onTap: () => selectedIndex.value = 1,
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        label: '店舗情報',
                        isSelected: selectedIndex.value == 2,
                        onTap: () => selectedIndex.value = 2,
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        label: '使い方',
                        isSelected: selectedIndex.value == 3,
                        onTap: () => selectedIndex.value = 3,
                      ),
                    ],
                  ),
                ),
                // メインコンテンツエリア
                Expanded(
                  child: screens[selectedIndex.value],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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