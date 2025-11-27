// screens/main_layout.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/app_theme.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'shift_management_screen.dart';
import 'shift_edit_screen.dart';
import 'store_settings_screen.dart';
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
                IconButton(
                  onPressed: () {
                    _showProfileMenu(context, ref);
                  },
                  icon: CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Icon(Icons.person, color: primaryColor),
                  ),
                  tooltip: 'プロフィール',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 250,
                  color: primaryColor,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildMenuItem(
                        icon: Icons.home,
                        label: 'ホーム',
                        isSelected: navigationState.screenType == ScreenType.dashboard,
                        onTap: () => ref.read(navigationProvider.notifier).navigateTo(ScreenType.dashboard),
                      ),
                      _buildMenuItem(
                        icon: Icons.edit_calendar,
                        label: 'シフト管理',
                        isSelected: navigationState.screenType == ScreenType.shiftManagement ||
                            navigationState.screenType == ScreenType.shiftEdit,
                        onTap: () => ref.read(navigationProvider.notifier).navigateTo(ScreenType.shiftManagement),
                      ),
                      _buildMenuItem(
                        icon: Icons.people,
                        label: 'スタッフ管理',
                        isSelected: navigationState.screenType == ScreenType.peopleManagement,
                        onTap: () => ref.read(navigationProvider.notifier).navigateTo(ScreenType.peopleManagement),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        label: '店舗情報',
                        isSelected: navigationState.screenType == ScreenType.storeSettings,
                        onTap: () => ref.read(navigationProvider.notifier).navigateTo(ScreenType.storeSettings),
                      ),
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        label: '使い方',
                        isSelected: navigationState.screenType == ScreenType.help,
                        onTap: () => ref.read(navigationProvider.notifier).navigateTo(ScreenType.help),
                      ),
                    ],
                  ),
                ),
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
      case ScreenType.peopleManagement:
        return const PeopleManagementScreen();
      case ScreenType.help:
        return const HelpScreen();
      case ScreenType.skillManagement:
        return const StoreSettingsScreen();
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

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _ProfileDialog(),
    );
  }
}

// プロフィールダイアログ（シンプル版）
class _ProfileDialog extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userInfo = useState<Map<String, dynamic>?>(null);
    final isLoading = useState(true);

    useEffect(() {
      Future<void> loadUserData() async {
        final info = await ref.read(authProvider.notifier).getUserInfo();
        userInfo.value = info;
        isLoading.value = false;
      }
      loadUserData();
      return null;
    }, []);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, color: primaryColor, size: 40),
            ),
            const SizedBox(height: 16),
            if (isLoading.value)
              const CircularProgressIndicator()
            else ...[
              if (userInfo.value?['store_name'] != null)
                Text(
                  userInfo.value!['store_name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                authState?.email ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            
            // ログアウトボタン
            _buildMenuItem(
              icon: Icons.logout,
              label: 'ログアウト',
              color: Colors.red,
              onTap: () async {
                final authNotifier = ref.read(authProvider.notifier);
                Navigator.pop(context);
                
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ログアウト'),
                    content: const Text('ログアウトしますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('ログアウト'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await authNotifier.signOut();
                }
              },
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }
}