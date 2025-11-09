// screens/store_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/shift_provider.dart';
import '../models/shift_data.dart';
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
            // スキルパターンセクション
            Row(
              children: [
                Text(
                  'スキルパターン',
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
            const SizedBox(height: 16),
            
            // スキルリスト（直接表示）
            shiftData.skills.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'スキルが登録されていません',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: shiftData.skills.map((skill) {
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
                            child: Icon(Icons.work, color: primaryColor, size: 20),
                          ),
                          title: Text(
                            skill,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                            onPressed: () {
                              _showDeleteSkillConfirmDialog(context, ref, skill);
                            },
                            tooltip: '削除',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            
            const SizedBox(height: 40),

            // シフトパターンセクション
            Row(
              children: [
                Text(
                  'シフトパターン',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddShiftPatternDialog(context, ref);
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
            const SizedBox(height: 16),
            
            // シフトパターンリスト（ボックスなし）
            shiftData.shiftPatterns.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'シフトパターンが登録されていません',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: shiftData.shiftPatterns.map((pattern) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          border: Border.all(color: borderColor, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            // パターン名と操作ボタン
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.05),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: primaryColor),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      pattern.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      _showEditShiftPatternDialog(context, ref, pattern);
                                    },
                                    tooltip: '名前を編集',
                                  ),
                                  if (shiftData.shiftPatterns.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                      onPressed: () {
                                        _showDeletePatternConfirmDialog(context, ref, pattern);
                                      },
                                      tooltip: '削除',
                                    ),
                                ],
                              ),
                            ),
                            // デフォルト必要人数
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'デフォルト必要人数',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ...shiftData.skills.map((skill) {
                                    final count = pattern.defaultRequiredMap[skill] ?? 0;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: backgroundColor,
                                        border: Border.all(color: borderColor),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              skill,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: count > 0
                                                ? () {
                                                    ref
                                                        .read(shiftDataProvider.notifier)
                                                        .setPatternDefaultRequired(
                                                            pattern.id, skill, count - 1);
                                                  }
                                                : null,
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '$count人',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            onPressed: () {
                                              ref
                                                  .read(shiftDataProvider.notifier)
                                                  .setPatternDefaultRequired(
                                                      pattern.id, skill, count + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  if (shiftData.skills.isEmpty)
                                    Text(
                                      'スキルを登録してください',
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
          ],
        ),
      ),
    );
  }

  // スキル追加ダイアログ
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

  // スキル削除確認ダイアログ
  void _showDeleteSkillConfirmDialog(
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

  // シフトパターン追加ダイアログ
  void _showAddShiftPatternDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シフトパターンを追加'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'パターン名',
            hintText: '例: 早番、遅番、通し',
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final pattern = ShiftPattern(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  sortOrder: ref.read(shiftDataProvider).shiftPatterns.length,
                );
                ref.read(shiftDataProvider.notifier).addShiftPattern(pattern);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('「$name」を追加しました')),
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

  // シフトパターン編集ダイアログ
  void _showEditShiftPatternDialog(
      BuildContext context, WidgetRef ref, ShiftPattern pattern) {
    final nameController = TextEditingController(text: pattern.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('シフトパターンを編集'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'パターン名',
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
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(shiftDataProvider.notifier).updateShiftPattern(
                      pattern.copyWith(name: name),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('更新しました')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('更新'),
          ),
        ],
      ),
    );
  }

  // シフトパターン削除確認ダイアログ
  void _showDeletePatternConfirmDialog(
      BuildContext context, WidgetRef ref, ShiftPattern pattern) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${pattern.name}」を削除してもよろしいですか？\n\nこのパターンを使用しているシフトデータも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(shiftDataProvider.notifier).removeShiftPattern(pattern.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${pattern.name}」を削除しました')),
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