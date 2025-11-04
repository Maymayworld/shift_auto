// screens/skill_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class SkillManagementScreen extends HookConsumerWidget {
  const SkillManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);
    final skillController = useTextEditingController();

    return Column(
      children: [
        // 戻るボタンとタイトル
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryColor),
                onPressed: () {
                  ref.read(navigationProvider.notifier).goBack();
                },
              ),
              Text(
                'スキル管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: skillController,
                  decoration: const InputDecoration(
                    labelText: '新しいスキル',
                    border: OutlineInputBorder(),
                    hintText: '例: ホール、キッチン',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (skillController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('スキル名を入力してください')),
                    );
                    return;
                  }

                  if (shiftData.skills.contains(skillController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('既に存在するスキルです')),
                    );
                    return;
                  }

                  ref.read(shiftDataProvider.notifier).addSkill(skillController.text);
                  skillController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
                child: const Text('追加'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shiftData.skills.length,
            itemBuilder: (context, index) {
              final skill = shiftData.skills[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(skill),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    onPressed: () {
                      _showDeleteConfirmDialog(context, ref, skill);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, String skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('スキル「$skill」を削除しますか？\n\nこのスキルを持つスタッフから削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftDataProvider.notifier).removeSkill(skill);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}