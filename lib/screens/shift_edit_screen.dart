// screens/shift_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../providers/shift_provider.dart';
import '../providers/navigation_provider.dart';
import '../models/shift_data.dart';
import '../theme/app_theme.dart';

class ShiftEditScreen extends HookConsumerWidget {
  final String shiftId;
  final DateTime date;
  final String shiftType;

  const ShiftEditScreen({
    Key? key,
    required this.shiftId,
    required this.date,
    required this.shiftType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftData = ref.watch(shiftDataProvider);
    final dailyShift = shiftData.getDailyShift(shiftId, date, shiftType);

    // 初回ロード時にデータがない場合は作成（遅延実行）
    useEffect(() {
      Future.microtask(() {
        if (!shiftData.dailyShifts.containsKey(shiftId)) {
          // デフォルトの必要人数を取得
          Map<String, int> defaultRequired = {};
          try {
            final parts = shiftId.split('-');
            if (parts.length >= 4) {
              final patternId = parts.sublist(3).join('-');
              final pattern = shiftData.shiftPatterns.firstWhere(
                (p) => p.id == patternId,
                orElse: () => shiftData.shiftPatterns.first,
              );
              defaultRequired = Map<String, int>.from(pattern.defaultRequiredMap);
            }
          } catch (e) {
            // エラーが発生した場合は空のマップを使用
            defaultRequired = {};
          }
          
          final newShift = DailyShift(
            shiftId: shiftId,
            date: date,
            shiftType: shiftType,
            wantsMap: {},
            requiredMap: defaultRequired,
            constStaff: {},
          );
          ref.read(shiftDataProvider.notifier).updateDailyShift(newShift);
        }
      });
      return null;
    }, [shiftId]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 戻るボタン、タイトル、保存ボタン
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: primaryColor),
                onPressed: () {
                  ref.read(navigationProvider.notifier).goBack();
                },
              ),
              Text(
                '${date.month}/${date.day} $shiftType の編集',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  ref.read(navigationProvider.notifier).goBack();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('保存しました')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  '保存',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 日付情報と必要人数
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${date.year}年${date.month}月${date.day}日 (${_getWeekday(date)}) $shiftType',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: primaryColor),
                      onPressed: () {
                        _showEditRequiredDialog(context, ref, shiftId, dailyShift);
                      },
                      tooltip: '必要人数を編集',
                    ),
                  ],
                ),
                if (dailyShift.requiredMap.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: dailyShift.requiredMap.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key}: ${entry.value}人'),
                        backgroundColor: Colors.white.withOpacity(0.8),
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 配置結果セクション
          Row(
            children: [
              Text(
                '配置結果',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
              if (dailyShift.isCalculated || dailyShift.constStaff.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_getAssignedCount(dailyShift, shiftData)}人',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAssignmentDisplay(dailyShift, shiftData),
          const SizedBox(height: 32),

          // 希望シフト
          Row(
            children: [
              Text(
                '希望シフト',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                '${dailyShift.wantsMap.length}人が希望',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: shiftData.people.map((person) {
              final currentWant = dailyShift.wantsMap[person.id];
              final constSkill = dailyShift.constStaff[person.id];
              final isConst = constSkill != null;
              final hasWant = currentWant != null || isConst;
              final displayWant = isConst ? constSkill : currentWant;
              
              // 「スキル指定なし」の表示
              final displayText = displayWant == 'スキル指定なし' ? 'スキル指定なし' : displayWant;

              return Container(
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConst
                      ? Colors.orange[50]
                      : (hasWant ? Colors.blue[50] : backgroundColor),
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 名前とアイコン行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            person.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // ピンアイコン（固定スタッフ設定）
                        IconButton(
                          icon: Icon(
                            isConst ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 16,
                          ),
                          color: isConst ? Colors.orange[700] : Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          onPressed: () {
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
                          tooltip: isConst ? '固定を解除' : '固定スタッフに設定',
                        ),
                        // 削除アイコン
                        if (hasWant && !isConst)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              ref
                                  .read(shiftDataProvider.notifier)
                                  .removeDailyWant(shiftId, person.id);
                            },
                            tooltip: '希望を削除',
                          ),
                        // 編集/追加アイコン
                        if (!isConst)
                          IconButton(
                            icon: Icon(
                              hasWant ? Icons.edit : Icons.add,
                              size: 16,
                            ),
                            color: primaryColor,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              _showWantDialog(
                                  context, ref, shiftId, person.id, person.name, person.skills);
                            },
                            tooltip: hasWant ? '希望を編集' : '希望を追加',
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 希望内容
                    Text(
                      isConst
                          ? '固定: $displayText'
                          : (hasWant ? '希望: $displayText' : '希望なし'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isConst
                            ? Colors.orange[700]
                            : (hasWant ? Colors.blue[700] : Colors.grey),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  int _getAssignedCount(DailyShift dailyShift, ShiftData shiftData) {
    final assignedIds = <String>{};
    
    // 固定スタッフを追加
    assignedIds.addAll(dailyShift.constStaff.keys);
    
    // 計算結果を追加
    if (dailyShift.resultMap != null) {
      for (final personIds in dailyShift.resultMap!.values) {
        assignedIds.addAll(personIds);
      }
    }
    
    return assignedIds.length;
  }

  Widget _buildAssignmentDisplay(DailyShift dailyShift, ShiftData shiftData) {
    // 固定スタッフと計算結果を統合
    final assignmentMap = <String, List<Map<String, dynamic>>>{};
    
    // 固定スタッフを追加
    for (final entry in dailyShift.constStaff.entries) {
      final personId = entry.key;
      final skill = entry.value;
      
      if (!assignmentMap.containsKey(skill)) {
        assignmentMap[skill] = [];
      }
      
      try {
        final person = shiftData.people.firstWhere((p) => p.id == personId);
        assignmentMap[skill]!.add({
          'id': personId,
          'name': person.name,
          'isFixed': true,
        });
      } catch (e) {
        // スタッフが見つからない場合はスキップ
      }
    }
    
    // 計算結果を追加
    if (dailyShift.resultMap != null) {
      for (final entry in dailyShift.resultMap!.entries) {
        final skill = entry.key;
        final personIds = entry.value;
        
        if (!assignmentMap.containsKey(skill)) {
          assignmentMap[skill] = [];
        }
        
        for (final personId in personIds) {
          // 固定スタッフとして既に追加されていないかチェック
          final alreadyAdded = assignmentMap[skill]!.any((p) => p['id'] == personId);
          if (!alreadyAdded) {
            try {
              final person = shiftData.people.firstWhere((p) => p.id == personId);
              assignmentMap[skill]!.add({
                'id': personId,
                'name': person.name,
                'isFixed': false,
              });
            } catch (e) {
              // スタッフが見つからない場合はスキップ
            }
          }
        }
      }
    }
    
    // 配置がない場合
    if (assignmentMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '配置されたスタッフがいません',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    // スキルごとに表示
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: assignmentMap.entries.map((entry) {
          final skill = entry.key;
          final assignments = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${assignments.length}人',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: assignments.map((assignment) {
                    final name = assignment['name'] as String;
                    final isFixed = assignment['isFixed'] as bool;
                    
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isFixed ? Colors.orange[100] : Colors.white,
                        border: Border.all(
                          color: isFixed ? Colors.orange[300]! : Colors.green[300]!,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isFixed)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                            ),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isFixed ? Colors.orange[900] : Colors.green[900],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showEditRequiredDialog(
    BuildContext context,
    WidgetRef ref,
    String shiftId,
    DailyShift dailyShift,
  ) {
    final shiftData = ref.read(shiftDataProvider);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('必要人数を編集'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: shiftData.skills.map((skill) {
                  final currentCount = dailyShift.requiredMap[skill] ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: currentCount > 0
                                ? () {
                                    ref
                                        .read(shiftDataProvider.notifier)
                                        .setDailyRequired(shiftId, skill, currentCount - 1);
                                    setState(() {});
                                  }
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$currentCount人',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              ref
                                  .read(shiftDataProvider.notifier)
                                  .setDailyRequired(shiftId, skill, currentCount + 1);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$personNameを$skillの固定スタッフに設定しました')),
                );
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
  ) {
    final shiftData = ref.read(shiftDataProvider);
    final dailyShift = shiftData.getDailyShift(shiftId, DateTime.now(), '');
    final currentWant = dailyShift.wantsMap[personId];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$personNameの希望シフト'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // スキル指定なし
            ListTile(
              title: const Text('スキル指定なし (どのスキルでもOK)'),
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
            const Divider(),
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
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}