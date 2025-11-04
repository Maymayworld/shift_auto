// screens/store_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class StoreSettingsScreen extends HookConsumerWidget {
  const StoreSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // スキル情報セクション
            Row(
              children: [
                Text(
                  'スキル情報',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigator.pushの代わりにナビゲーションプロバイダーを使用
                    ref
                        .read(navigationProvider.notifier)
                        .navigateTo(ScreenType.skillManagement);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: shiftData.skills.isEmpty
                  ? const Text('スキルが登録されていません')
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: shiftData.skills.map((skill) {
                        return Chip(
                          label: Text(skill),
                          backgroundColor: primaryColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 40),
            // スタッフ情報セクション
            Row(
              children: [
                Text(
                  'スタッフ情報',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigator.pushの代わりにナビゲーションプロバイダーを使用
                    ref
                        .read(navigationProvider.notifier)
                        .navigateTo(ScreenType.peopleManagement);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('編集'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: shiftData.people.isEmpty
                  ? const Text('スタッフが登録されていません')
                  : Column(
                      children: shiftData.people.map((person) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: primaryColor.withOpacity(0.1),
                                child: Icon(Icons.person, color: primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      person.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'スキル: ${person.skills.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}