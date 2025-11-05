// screens/shift_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/app_theme.dart';
import '../models/shift_data.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';

class ShiftManagementScreen extends HookConsumerWidget {
  const ShiftManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalculating = useState(false);
    final shiftData = ref.watch(shiftDataProvider);
    
    // 選択されたシフトIDを管理
    final selectedShifts = useState<Map<String, bool>>({});

    // 日付とシフトパターンの組み合わせを生成（30日分に変更）
    final datePatternPairs = <Map<String, dynamic>>[];
    for (int i = 0; i < 30; i++) {
      final date = DateTime.now().add(Duration(days: i));
      for (final pattern in shiftData.shiftPatterns) {
        final shiftId = '${date.year}-${date.month}-${date.day}-${pattern.id}';
        datePatternPairs.add({
          'date': date,
          'pattern': pattern,
          'shiftId': shiftId,
        });
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 上部コントロール
          Row(
            children: [
              Text(
                'シフト管理',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              // 「選択して計算」ボタン
              ElevatedButton.icon(
                onPressed: isCalculating.value
                    ? null
                    : () async {
                        // 選択されたシフトIDを取得
                        final selected = selectedShifts.value.entries
                            .where((entry) => entry.value == true)
                            .map((entry) => entry.key)
                            .toList();

                        if (selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('計算するシフトを選択してください'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        isCalculating.value = true;
                        try {
                          await ref
                              .read(shiftDataProvider.notifier)
                              .calculateShifts(selected);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${selected.length}件のシフトを計算しました'),
                            ),
                          );
                        } finally {
                          isCalculating.value = false;
                        }
                      },
                icon: isCalculating.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calculate),
                label: const Text('選択して計算'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // グリッドビュー
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: _buildShiftGrid(
                  context,
                  ref,
                  shiftData,
                  datePatternPairs,
                  selectedShifts,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftGrid(
    BuildContext context,
    WidgetRef ref,
    ShiftData shiftData,
    List<Map<String, dynamic>> datePatternPairs,
    ValueNotifier<Map<String, bool>> selectedShifts,
  ) {
    const cellWidth = 120.0;
    const cellHeight = 80.0;
    const headerHeight = 120.0;

    return Table(
      border: TableBorder.all(color: borderColor, width: 1),
      defaultColumnWidth: const FixedColumnWidth(cellWidth),
      children: [
        // ヘッダー行: 日付とシフトパターン
        TableRow(
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1)),
          children: [
            // 左上のセル（空白）
            Container(
              height: headerHeight,
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  'スタッフ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),
            // 各日付・パターンのヘッダー
            ...datePatternPairs.map((pair) {
              final date = pair['date'] as DateTime;
              final pattern = pair['pattern'] as ShiftPattern;
              final shiftId = pair['shiftId'] as String;
              final dailyShift = shiftData.getDailyShift(shiftId, date, pattern.name);

              return Container(
                height: headerHeight,
                padding: const EdgeInsets.all(8),
                child: Stack(
                  children: [
                    // メインコンテンツ
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20), // チェックボックス分のスペース
                        Text(
                          '${date.month}/${date.day}(${_getWeekday(date)})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          pattern.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 必要人数
                        if (dailyShift.requiredMap.isNotEmpty)
                          Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            alignment: WrapAlignment.center,
                            children: dailyShift.requiredMap.entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${entry.key}:${entry.value}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: primaryColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    // 左上: チェックボックス
                    Positioned(
                      top: 0,
                      left: 0,
                      child: InkWell(
                        onTap: () {
                          final current = selectedShifts.value[shiftId] ?? false;
                          selectedShifts.value = {
                            ...selectedShifts.value,
                            shiftId: !current,
                          };
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            (selectedShifts.value[shiftId] ?? false)
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                    // 右上: ペンアイコン（必要人数編集）
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          _showRequiredEditDialog(
                            context,
                            ref,
                            shiftId,
                            date,
                            pattern,
                            dailyShift,
                            shiftData.skills,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        // スタッフ行
        ...shiftData.people.map((person) {
          return TableRow(
            children: [
              // スタッフ名セル
              Container(
                height: cellHeight,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                ),
                child: Center(
                  child: Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // 各日付のシフトセル
              ...datePatternPairs.map((pair) {
                final date = pair['date'] as DateTime;
                final pattern = pair['pattern'] as ShiftPattern;
                final shiftId = pair['shiftId'] as String;
                final dailyShift = shiftData.getDailyShift(shiftId, date, pattern.name);
                
                final currentWant = dailyShift.wantsMap[person.id];
                final constSkill = dailyShift.constStaff[person.id];
                final isConst = constSkill != null;
                final hasWant = currentWant != null || isConst;
                
                // 配置されているかチェック
                bool isAssigned = isConst;
                if (!isAssigned && dailyShift.resultMap != null) {
                  for (final personIds in dailyShift.resultMap!.values) {
                    if (personIds.contains(person.id)) {
                      isAssigned = true;
                      break;
                    }
                  }
                }

                return _buildShiftCell(
                  context: context,
                  ref: ref,
                  person: person,
                  shiftId: shiftId,
                  date: date,
                  pattern: pattern,
                  dailyShift: dailyShift,
                  hasWant: hasWant,
                  isConst: isConst,
                  isAssigned: isAssigned,
                  currentWant: currentWant,
                  constSkill: constSkill,
                  cellHeight: cellHeight,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildShiftCell({
    required BuildContext context,
    required WidgetRef ref,
    required Person person,
    required String shiftId,
    required DateTime date,
    required ShiftPattern pattern,
    required DailyShift dailyShift,
    required bool hasWant,
    required bool isConst,
    required bool isAssigned,
    required String? currentWant,
    required String? constSkill,
    required double cellHeight,
  }) {
    final displayWant = isConst ? constSkill : currentWant;
    final displayText = displayWant == 'スキル指定なし' ? 'すべて' : displayWant;

    return Container(
      height: cellHeight,
      decoration: BoxDecoration(
        color: isAssigned ? Colors.blue[50] : Colors.white,
      ),
      child: Stack(
        children: [
          // 希望内容表示
          if (hasWant)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isConst)
                    Icon(Icons.push_pin, size: 12, color: Colors.orange[700]),
                  Text(
                    displayText ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isConst ? Colors.orange[700] : Colors.blue[700],
                      fontWeight: isConst ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          // アイコンボタン
          Positioned(
            top: 2,
            right: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ピンアイコン
                InkWell(
                  onTap: () {
                    if (isConst) {
                      // 固定解除
                      ref
                          .read(shiftDataProvider.notifier)
                          .removeDailyConstStaff(shiftId, person.id);
                    } else {
                      // 固定設定
                      _showConstStaffDialog(
                          context, ref, shiftId, person.id, person.name, person.skills);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      isConst ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 14,
                      color: isConst ? Colors.orange[700] : Colors.grey[400],
                    ),
                  ),
                ),
                // ＋アイコン（希望追加/編集）
                if (!isConst)
                  InkWell(
                    onTap: () {
                      _showWantDialog(
                          context, ref, shiftId, person.id, person.name, person.skills, currentWant);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        hasWant ? Icons.edit : Icons.add,
                        size: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  // 必要人数編集ダイアログ
  void _showRequiredEditDialog(
    BuildContext context,
    WidgetRef ref,
    String shiftId,
    DateTime date,
    ShiftPattern pattern,
    DailyShift dailyShift,
    List<String> skills,
  ) {
    showDialog(
      context: context,
      builder: (context) => _RequiredEditDialog(
        shiftId: shiftId,
        date: date,
        pattern: pattern,
        dailyShift: dailyShift,
        skills: skills,
      ),
    );
  }

  void _showConstStaffDialog(
    BuildContext context,
    WidgetRef ref,
    String shiftId,
    String personId,
    String personName,
    List<String> personSkills,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$personNameを固定スタッフに設定'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: personSkills.map((skill) {
            return ListTile(
              title: Text(skill),
              onTap: () {
                ref.read(shiftDataProvider.notifier).setDailyConstStaff(
                      shiftId,
                      personId,
                      skill,
                    );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _showWantDialog(
    BuildContext context,
    WidgetRef ref,
    String shiftId,
    String personId,
    String personName,
    List<String> personSkills,
    String? currentWant,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$personNameの希望シフト'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 削除オプション
            if (currentWant != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('希望を削除'),
                onTap: () {
                  ref.read(shiftDataProvider.notifier).removeDailyWant(shiftId, personId);
                  Navigator.pop(context);
                },
              ),
            const Divider(),
            // スキル指定なし
            ListTile(
              title: const Text('スキル指定なし'),
              leading: Radio<String>(
                value: 'スキル指定なし',
                groupValue: currentWant,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(shiftDataProvider.notifier).setDailyWant(shiftId, personId, value);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            // 各スキル
            ...personSkills.map((skill) {
              return ListTile(
                title: Text(skill),
                leading: Radio<String>(
                  value: skill,
                  groupValue: currentWant,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(shiftDataProvider.notifier).setDailyWant(shiftId, personId, value);
                      Navigator.pop(context);
                    }
                  },
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

// 必要人数編集ダイアログ（StatefulWidget）
class _RequiredEditDialog extends HookConsumerWidget {
  final String shiftId;
  final DateTime date;
  final ShiftPattern pattern;
  final DailyShift dailyShift;
  final List<String> skills;

  const _RequiredEditDialog({
    required this.shiftId,
    required this.date,
    required this.pattern,
    required this.dailyShift,
    required this.skills,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 各スキルの必要人数を管理
    final requiredCounts = useState<Map<String, int>>(
      Map<String, int>.from(dailyShift.requiredMap),
    );

    return AlertDialog(
      title: Text('${date.month}/${date.day} ${pattern.name} - 必要人数'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: skills.map((skill) {
              final count = requiredCounts.value[skill] ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // マイナスボタン
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: count > 0
                          ? () {
                              requiredCounts.value = {
                                ...requiredCounts.value,
                                skill: count - 1,
                              };
                            }
                          : null,
                      iconSize: 24,
                    ),
                    // 数字表示
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // プラスボタン
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () {
                        requiredCounts.value = {
                          ...requiredCounts.value,
                          skill: count + 1,
                        };
                      },
                      iconSize: 24,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () {
            // 必要人数を保存
            for (final entry in requiredCounts.value.entries) {
              ref.read(shiftDataProvider.notifier).setDailyRequired(
                    shiftId,
                    entry.key,
                    entry.value,
                  );
            }
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('必要人数を更新しました')),
            );
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