// screens/skill_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class SkillManagementScreen extends HookConsumerWidget {
  const SkillManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
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
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddSkillDialog(context, ref);
                },
                icon: const Icon(Icons.add),
                label: const Text('追加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // スキルリスト
          Expanded(
            child: shiftData.skills.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'スキルが登録されていません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '右上の「追加」ボタンからスキルを登録してください',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: shiftData.skills.length,
                    itemBuilder: (context, index) {
                      final skill = shiftData.skills[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(Icons.work, color: primaryColor),
                          ),
                          title: Text(
                            skill,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                size: 20, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmDialog(context, ref, skill);
                            },
                            tooltip: '削除',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddSkillDialog(BuildContext context, WidgetRef ref) {
    final skillController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('スキルを追加'),
        content: TextField(
          controller: skillController,
          decoration: const InputDecoration(
            labelText: 'スキル名',
            hintText: '例: ホール、キッチン',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final skill = skillController.text.trim();
              if (skill.isNotEmpty) {
                ref.read(shiftDataProvider.notifier).addSkill(skill);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「$skill」を追加しました')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, String skill) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text(
            '「$skill」を削除してもよろしいですか？\n\nこのスキルを持つスタッフやシフトデータからも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(shiftDataProvider.notifier).removeSkill(skill);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「$skill」を削除しました')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}