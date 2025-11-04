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
    final filterIndex = useState(0); // 0: 全て, 1: 未確定, 2: 確定済み
    final isSelectionMode = useState(false);
    final selectedShifts = useState<Set<String>>({});
    final isCalculating = useState(false);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 上部コントロール
          Row(
            children: [
              // フィルター
              _buildFilterButton('全て', 0, filterIndex),
              const SizedBox(width: 8),
              _buildFilterButton('未確定', 1, filterIndex),
              const SizedBox(width: 8),
              _buildFilterButton('確定済み', 2, filterIndex),
              const Spacer(),
              // ボタン群
              if (isSelectionMode.value)
                OutlinedButton.icon(
                  onPressed: () {
                    isSelectionMode.value = false;
                    selectedShifts.value = {};
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('キャンセル'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    isSelectionMode.value = true;
                  },
                  icon: const Icon(Icons.check_box_outlined),
                  label: const Text('選択して計算'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: isCalculating.value
                    ? null
                    : () async {
                        if (isSelectionMode.value && selectedShifts.value.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('シフトを選択してください')),
                          );
                          return;
                        }

                        isCalculating.value = true;

                        try {
                          if (isSelectionMode.value) {
                            // 選択したシフトを計算
                            await ref
                                .read(shiftDataProvider.notifier)
                                .calculateShifts(selectedShifts.value.toList());
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${selectedShifts.value.length}件のシフトを計算しました')),
                            );
                            selectedShifts.value = {};
                            isSelectionMode.value = false;
                          } else {
                            // 全てのシフトを計算（60日 × 2シフト = 120シフト）
                            final allShiftIds = <String>[];
                            for (int i = 0; i < 60; i++) {
                              final date = DateTime.now().add(Duration(days: i));
                              // 早番
                              allShiftIds.add('${date.year}-${date.month}-${date.day}-early');
                              // 遅番
                              allShiftIds.add('${date.year}-${date.month}-${date.day}-late');
                            }
                            await ref
                                .read(shiftDataProvider.notifier)
                                .calculateShifts(allShiftIds);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('全てのシフトを計算しました')),
                            );
                          }
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
                label: Text(isSelectionMode.value ? '選択したものを計算' : '全て計算'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // シフトリスト
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final shiftData = ref.watch(shiftDataProvider);
                
                return ListView.builder(
                  itemCount: 120, // 60日 × 2シフト（早番・遅番）
                  itemBuilder: (context, index) {
                    // index / 2 で日付を計算、index % 2 でシフトタイプを決定
                    final dayIndex = index ~/ 2; // 整数除算
                    final isEarlyShift = index % 2 == 0; // 偶数: 早番、奇数: 遅番
                    
                    final date = DateTime.now().add(Duration(days: dayIndex));
                    final shiftType = isEarlyShift ? '早番' : '遅番';
                    final shiftId = '${date.year}-${date.month}-${date.day}-${isEarlyShift ? 'early' : 'late'}';
                    
                    final dailyShift = shiftData.getDailyShift(shiftId, date, shiftType);

                    // フィルタリング
                    if (filterIndex.value == 1 && dailyShift.isCalculated) {
                      return const SizedBox.shrink();
                    }
                    if (filterIndex.value == 2 && !dailyShift.isCalculated) {
                      return const SizedBox.shrink();
                    }

                    return _buildShiftTile(
                      context: context,
                      ref: ref,
                      date: date,
                      isEarlyShift: isEarlyShift,
                      isSelectionMode: isSelectionMode.value,
                      shiftId: shiftId,
                      dailyShift: dailyShift,
                      isSelected: selectedShifts.value.contains(shiftId),
                      onCheckboxChanged: (value) {
                        final newSet = Set<String>.from(selectedShifts.value);
                        if (value == true) {
                          newSet.add(shiftId);
                        } else {
                          newSet.remove(shiftId);
                        }
                        selectedShifts.value = newSet;
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, int index, ValueNotifier<int> filterIndex) {
    final isSelected = filterIndex.value == index;
    return InkWell(
      onTap: () => filterIndex.value = index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildShiftTile({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime date,
    required bool isEarlyShift,
    required bool isSelectionMode,
    required String shiftId,
    required DailyShift dailyShift,
    required bool isSelected,
    required Function(bool?) onCheckboxChanged,
  }) {
    final dateStr = '${date.month}/${date.day}(${_getWeekday(date)})';
    final shiftType = isEarlyShift ? '早番' : '遅番';
    final shiftData = ref.read(shiftDataProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: onCheckboxChanged,
              )
            : InkWell(
                onTap: () {
                  // ナビゲーションプロバイダーを使用
                  ref.read(navigationProvider.notifier).navigateTo(
                        ScreenType.shiftEdit,
                        params: {
                          'shiftId': shiftId,
                          'date': date,
                          'shiftType': shiftType,
                        },
                      );
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: backgroundColor,
                  ),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateStr $shiftType',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '希望者: ${dailyShift.wantsCount}人 / 必要: ${dailyShift.totalRequired}人',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: _buildResultDisplay(shiftData, dailyShift),
      ),
    );
  }

  Widget _buildResultDisplay(ShiftData shiftData, DailyShift dailyShift) {
    if (!dailyShift.isCalculated || dailyShift.resultMap == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          '未設定',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    // 結果を表示
    final resultMap = dailyShift.resultMap!;
    final resultText = <String>[];

    for (final entry in resultMap.entries) {
      final skill = entry.key;
      final personIds = entry.value;
      if (personIds.isNotEmpty) {
        final names = personIds.map((id) {
          try {
            final person = shiftData.people.firstWhere((p) => p.id == id);
            return person.name;
          } catch (e) {
            return '?';
          }
        }).join(',');
        resultText.add('$skill:$names');
      }
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        resultText.isEmpty ? '配置なし' : resultText.join(' '),
        style: TextStyle(
          fontSize: 12,
          color: Colors.green[700],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }
}