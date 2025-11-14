// screens/shift_management_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../theme/app_theme.dart';
import '../models/shift_data.dart';
import '../providers/shift_provider.dart';

class ShiftManagementScreen extends HookConsumerWidget {
  const ShiftManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCalculating = useState(false);
    final shiftData = ref.watch(shiftDataProvider);
    
    // 選択モードかどうか
    final isSelectionMode = useState(false);
    // 選択されたシフトIDを管理
    final selectedShifts = useState<Map<String, bool>>({});

    // 30日分の日付を生成
    final dates = <DateTime>[];
    for (int i = 0; i < 30; i++) {
      dates.add(DateTime.now().add(Duration(days: i)));
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
              
              // 選択モードの場合は「選択解除」ボタン
              if (isSelectionMode.value)
                TextButton(
                  onPressed: () {
                    isSelectionMode.value = false;
                    selectedShifts.value = {};
                  },
                  child: const Text('選択解除'),
                ),
              
              const SizedBox(width: 8),
              
              // 「選択して計算」ボタン
              ElevatedButton.icon(
                onPressed: isCalculating.value
                    ? null
                    : () {
                        if (!isSelectionMode.value) {
                          isSelectionMode.value = true;
                        } else {
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
                          Future(() async {
                            try {
                              await ref
                                  .read(shiftDataProvider.notifier)
                                  .calculateShifts(selected);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${selected.length}件のシフトを計算しました'),
                                ),
                              );
                              isSelectionMode.value = false;
                              selectedShifts.value = {};
                            } finally {
                              isCalculating.value = false;
                            }
                          });
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
                    : Icon(isSelectionMode.value ? Icons.calculate : Icons.check_box_outlined),
                label: Text(isSelectionMode.value ? '選択を計算' : '選択して計算'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelectionMode.value ? Colors.green : primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 「全て計算」ボタン
              ElevatedButton.icon(
                onPressed: isCalculating.value
                    ? null
                    : () async {
                        isCalculating.value = true;
                        try {
                          // 全てのシフトを計算
                          final allShiftIds = <String>[];
                          for (final date in dates) {
                            for (final pattern in shiftData.shiftPatterns) {
                              final shiftId = '${date.year}-${date.month}-${date.day}-${pattern.id}';
                              allShiftIds.add(shiftId);
                            }
                          }
                          
                          await ref
                              .read(shiftDataProvider.notifier)
                              .calculateShifts(allShiftIds);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('全てのシフトを計算しました')),
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
                label: const Text('全て計算'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 「全てクリア」ボタン
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('確認'),
                      content: const Text('全てのシフトの希望・固定・計算結果をクリアしますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('キャンセル'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(shiftDataProvider.notifier).clearAllShifts();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('全てのシフトをクリアしました')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('クリア'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('全てクリア'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
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
                  dates,
                  isSelectionMode,
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
    List<DateTime> dates,
    ValueNotifier<bool> isSelectionMode,
    ValueNotifier<Map<String, bool>> selectedShifts,
  ) {
    const cellWidth = 180.0;
    const headerHeight = 120.0;

    return Table(
      border: TableBorder.all(color: borderColor, width: 1),
      defaultColumnWidth: const FixedColumnWidth(cellWidth),
      children: [
        // ヘッダー行: 日付
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
            // 各日付のヘッダー
            ...dates.map((date) {
              return Container(
                height: headerHeight,
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.month}/${date.day}(${_getWeekday(date)})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 必要人数の概要を表示（スクロール可能）
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: shiftData.shiftPatterns.map((pattern) {
                            final shiftId = '${date.year}-${date.month}-${date.day}-${pattern.id}';
                            final dailyShift = shiftData.getDailyShift(shiftId, date, pattern.name);
                            
                            if (dailyShift.requiredMap.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            
                            // 配置済み人数を計算
                            final assignedCounts = <String, int>{};
                            for (final skill in dailyShift.requiredMap.keys) {
                              int count = 0;
                              // 固定スタッフ
                              count += dailyShift.constStaff.values.where((s) => s == skill).length;
                              // 計算結果配置
                              count += dailyShift.calculatedStaff.values.where((s) => s == skill).length;
                              assignedCounts[skill] = count;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                alignment: WrapAlignment.center,
                                children: dailyShift.requiredMap.entries.map((entry) {
                                  final skill = entry.key;
                                  final required = entry.value;
                                  final assigned = assignedCounts[skill] ?? 0;
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: assigned >= required 
                                          ? Colors.green[100] 
                                          : Colors.blue[50],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '$skill:$assigned/$required',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: assigned >= required 
                                            ? Colors.green[700] 
                                            : primaryColor,
                                        fontWeight: assigned >= required 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
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
              ...dates.map((date) {
                return _buildDateCell(
                  context: context,
                  ref: ref,
                  person: person,
                  date: date,
                  shiftData: shiftData,
                  isSelectionMode: isSelectionMode,
                  selectedShifts: selectedShifts,
                );
              }),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildDateCell({
    required BuildContext context,
    required WidgetRef ref,
    required Person person,
    required DateTime date,
    required ShiftData shiftData,
    required ValueNotifier<bool> isSelectionMode,
    required ValueNotifier<Map<String, bool>> selectedShifts,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Column(
        children: shiftData.shiftPatterns.map((pattern) {
          final shiftId = '${date.year}-${date.month}-${date.day}-${pattern.id}';
          final dailyShift = shiftData.getDailyShift(shiftId, date, pattern.name);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildShiftTile(
              context: context,
              ref: ref,
              person: person,
              pattern: pattern,
              shiftId: shiftId,
              dailyShift: dailyShift,
              isSelectionMode: isSelectionMode,
              selectedShifts: selectedShifts,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShiftTile({
    required BuildContext context,
    required WidgetRef ref,
    required Person person,
    required ShiftPattern pattern,
    required String shiftId,
    required DailyShift dailyShift,
    required ValueNotifier<bool> isSelectionMode,
    required ValueNotifier<Map<String, bool>> selectedShifts,
  }) {
    // 状態を判定
    final isConst = dailyShift.constStaff.containsKey(person.id);
    final isCalculated = dailyShift.calculatedStaff.containsKey(person.id);
    final hasWant = dailyShift.wantsMap.containsKey(person.id);
    
    final constSkill = dailyShift.constStaff[person.id];
    final calculatedSkill = dailyShift.calculatedStaff[person.id];
    final wantSkill = dailyShift.wantsMap[person.id];

    // タイルの色と枠を決定
    Color tileColor = Colors.white;
    Color? borderColor;
    
    if (isCalculated) {
      // 計算結果配置 - 薄い青背景
      tileColor = Colors.blue[50]!;
    } else if (isConst) {
      // 固定 - オレンジ背景
      tileColor = Colors.orange[100]!;
    } else if (hasWant) {
      // 希望 - プライマリカラー枠
      borderColor = primaryColor;
    }

    // 選択状態のチェック
    final isSelected = selectedShifts.value[shiftId] ?? false;

    return InkWell(
      onTap: () {
        if (isSelectionMode.value) {
          // 選択モードでは選択状態を切り替え
          selectedShifts.value = {
            ...selectedShifts.value,
            shiftId: !isSelected,
          };
        } else if (isCalculated) {
          // 計算結果配置の場合は何もしない
          return;
        } else {
          // 状態を切り替え
          if (!hasWant && !isConst) {
            // 未選択 → 希望状態
            ref.read(shiftDataProvider.notifier).setDailyWant(
                  shiftId,
                  person.id,
                  'スキル指定なし',
                );
          } else if (hasWant && !isConst) {
            // 希望状態 → 固定状態
            final skillToUse = wantSkill == 'スキル指定なし' 
                ? (person.skills.isNotEmpty ? person.skills.first : '')
                : wantSkill!;
            
            if (skillToUse.isNotEmpty) {
              ref.read(shiftDataProvider.notifier).setDailyConstStaff(
                    shiftId,
                    person.id,
                    skillToUse,
                  );
            }
          } else if (isConst) {
            // 固定状態 → 未選択状態
            ref.read(shiftDataProvider.notifier).clearPersonShift(shiftId, person.id);
          }
        }
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: tileColor,
          border: Border.all(
            color: borderColor ?? Colors.grey[300]!,
            width: borderColor != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 選択モードのチェックボックス
            if (isSelectionMode.value)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 16,
                  color: primaryColor,
                ),
              ),
            // 左側: パターン名またはスキル
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasWant && !isConst && !isCalculated) ...[
                      // 未選択状態: パターン名のみ
                      Text(
                        pattern.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (hasWant && !isConst && !isCalculated) ...[
                      // 希望状態: パターン名とスキル
                      Text(
                        pattern.name,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      _buildSkillDisplay(wantSkill, person.skills, primaryColor),
                    ] else if (isConst) ...[
                      // 固定状態: パターン名とスキル
                      Text(
                        pattern.name,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        constSkill ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (isCalculated) ...[
                      // 計算結果配置: パターン名とスキル
                      Text(
                        pattern.name,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        calculatedSkill ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // 右側: アイコン
            if (!isSelectionMode.value) ...[
              if (isCalculated) ...[
                // 計算結果配置: ✕アイコン
                InkWell(
                  onTap: () {
                    ref.read(shiftDataProvider.notifier).revertCalculatedToWant(
                          shiftId,
                          person.id,
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.red[400],
                    ),
                  ),
                ),
              ] else if (hasWant || isConst) ...[
                // 希望状態または固定状態: ペンアイコン
                InkWell(
                  onTap: () {
                    _showEditDialog(
                      context,
                      ref,
                      shiftId,
                      person,
                      isConst,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkillDisplay(String? wantSkill, List<String> personSkills, Color color) {
    if (wantSkill == 'スキル指定なし') {
      // 持っている全スキルを表示
      return Text(
        personSkills.join(','),
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      // 特定スキルを表示
      return Text(
        wantSkill ?? '',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    String shiftId,
    Person person,
    bool isConst,
  ) {
    final shiftData = ref.read(shiftDataProvider);
    final dailyShift = shiftData.dailyShifts[shiftId];
    if (dailyShift == null) return;

    final currentWant = dailyShift.wantsMap[person.id];
    final currentConst = dailyShift.constStaff[person.id];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${person.name}のシフト編集'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 削除オプション
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('削除'),
              onTap: () {
                ref.read(shiftDataProvider.notifier).clearPersonShift(shiftId, person.id);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            // スキル指定なし
            if (!isConst)
              ListTile(
                title: const Text('スキル指定なし'),
                leading: Radio<String>(
                  value: 'スキル指定なし',
                  groupValue: currentWant,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(shiftDataProvider.notifier).setDailyWant(shiftId, person.id, value);
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            // 各スキル
            ...shiftData.skills.map((skill) {
              final hasSkill = person.skills.contains(skill);
              return ListTile(
                title: Text(skill),
                trailing: hasSkill ? null : const Text(
                  '未習得',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
                leading: Radio<String>(
                  value: skill,
                  groupValue: isConst ? currentConst : currentWant,
                  onChanged: (value) {
                    if (value != null) {
                      if (isConst) {
                        ref.read(shiftDataProvider.notifier).setDailyConstStaff(
                              shiftId,
                              person.id,
                              value,
                            );
                      } else {
                        ref.read(shiftDataProvider.notifier).setDailyWant(
                              shiftId,
                              person.id,
                              value,
                            );
                      }
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