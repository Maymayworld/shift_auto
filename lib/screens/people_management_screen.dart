// screens/people_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/shift_data.dart';
import '../theme/app_theme.dart';

class PeopleManagementScreen extends HookConsumerWidget {
  const PeopleManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);

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
                  _showPersonDialog(context, ref);
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
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
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
                  title: Text(person.name),
                  subtitle: Text('スキル: ${person.skills.join(', ')}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          _showPersonDialog(context, ref, person: person);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: () {
                          _showDeleteConfirmDialog(context, ref, person);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showPersonDialog(BuildContext context, WidgetRef ref, {Person? person}) {
    showDialog(
      context: context,
      builder: (context) => _PersonDialog(person: person),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, Person person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('${person.name}を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shiftDataProvider.notifier).removePerson(person.id);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PersonDialog extends HookConsumerWidget {
  final Person? person;

  const _PersonDialog({this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);
    final nameController = useTextEditingController(text: person?.name ?? '');
    final selectedSkills = useState<Set<String>>(
      person?.skills.toSet() ?? {},
    );

    return AlertDialog(
      title: Text(person == null ? 'スタッフ追加' : 'スタッフ編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'スキル選択',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...shiftData.skills.map((skill) {
              final isSelected = selectedSkills.value.contains(skill);
              return CheckboxListTile(
                title: Text(skill),
                value: isSelected,
                onChanged: (value) {
                  final newSet = Set<String>.from(selectedSkills.value);
                  if (value == true) {
                    newSet.add(skill);
                  } else {
                    newSet.remove(skill);
                  }
                  selectedSkills.value = newSet;
                },
              );
            }),
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
            if (nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('名前を入力してください')),
              );
              return;
            }

            if (selectedSkills.value.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('少なくとも1つのスキルを選択してください')),
              );
              return;
            }

            final newPerson = Person(
              id: person?.id ?? 'id${DateTime.now().millisecondsSinceEpoch}',
              name: nameController.text,
              skills: selectedSkills.value.toList(),
            );

            if (person == null) {
              ref.read(shiftDataProvider.notifier).addPerson(newPerson);
            } else {
              ref.read(shiftDataProvider.notifier).updatePerson(newPerson);
            }

            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('保存'),
        ),
      ],
    );
  }
}