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
          // 戻るボタン
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
                        if (isConst)
                          Icon(
                            Icons.push_pin,
                            color: Colors.orange[700],
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasWant && !isConst)
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: Colors.red,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              ref
                                  .read(shiftDataProvider.notifier)
                                  .removeDailyWant(shiftId, person.id);
                            },
                            tooltip: '希望を削除',
                          ),
                        if (!isConst)
                          IconButton(
                            icon: Icon(
                              hasWant ? Icons.edit : Icons.add,
                              size: 16,
                            ),
                            color: primaryColor,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () {
                              _showWantDialog(
                                  context, ref, shiftId, person.id, person.name, person.skills);
                            },
                            tooltip: hasWant ? '希望を編集' : '希望を追加',
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // 保存ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(navigationProvider.notifier).goBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('保存しました')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '保存して戻る',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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