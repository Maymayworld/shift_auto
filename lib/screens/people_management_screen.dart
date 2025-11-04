// screens/people_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/shift_data.dart';
import '../theme/app_theme.dart';

class PeopleManagementScreen extends HookConsumerWidget {
  const PeopleManagementScreen({Key? key}) : super(key: key);

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
                'スタッフ管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  _showAddPersonDialog(context, ref);
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
          // スタッフリスト
          Expanded(
            child: shiftData.people.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'スタッフが登録されていません',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '右上の「追加」ボタンからスタッフを登録してください',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: shiftData.people.length,
                    itemBuilder: (context, index) {
                      final person = shiftData.people[index];
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
                            child: Icon(Icons.person, color: primaryColor),
                          ),
                          title: Text(
                            person.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            'スキル: ${person.skills.isEmpty ? "未設定" : person.skills.join(', ')}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {
                                  _showEditPersonDialog(context, ref, person);
                                },
                                tooltip: '編集',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    size: 20, color: Colors.red),
                                onPressed: () {
                                  _showDeleteConfirmDialog(
                                      context, ref, person);
                                },
                                tooltip: '削除',
                              ),
                            ],
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

  void _showAddPersonDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final shiftData = ref.read(shiftDataProvider);
    final selectedSkills = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('スタッフを追加'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名前',
                    hintText: '例: 山田太郎',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'スキル',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (shiftData.skills.isEmpty)
                  Text(
                    '先にスキルを登録してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: shiftData.skills.map((skill) {
                      final isSelected = selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSkills.add(skill);
                            } else {
                              selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
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
                  final person = Person(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    skills: selectedSkills.toList(),
                  );
                  ref.read(shiftDataProvider.notifier).addPerson(person);
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
      ),
    );
  }

  void _showEditPersonDialog(
      BuildContext context, WidgetRef ref, Person person) {
    final nameController = TextEditingController(text: person.name);
    final shiftData = ref.read(shiftDataProvider);
    final selectedSkills = Set<String>.from(person.skills);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('スタッフを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '名前',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'スキル',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (shiftData.skills.isEmpty)
                  Text(
                    '先にスキルを登録してください',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: shiftData.skills.map((skill) {
                      final isSelected = selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedSkills.add(skill);
                            } else {
                              selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
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
                  ref.read(shiftDataProvider.notifier).updatePerson(
                        person.copyWith(
                          name: name,
                          skills: selectedSkills.toList(),
                        ),
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
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, WidgetRef ref, Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text(
            '「${person.name}」を削除してもよろしいですか？\n\nこのスタッフに関連するシフトデータも削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(shiftDataProvider.notifier).removePerson(person.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('「${person.name}」を削除しました')),
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