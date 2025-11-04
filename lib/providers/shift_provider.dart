// providers/shift_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift_data.dart';
import '../services/storage_service.dart';
import '../services/shift_auto_algorithm.dart';

/// ShiftDataの状態管理
class ShiftDataNotifier extends StateNotifier<ShiftData> {
  ShiftDataNotifier() : super(ShiftData.sample()) {
    _loadData();
  }

  /// データを読み込み
  Future<void> _loadData() async {
    final data = await StorageService.loadShiftData();
    if (data != null) {
      state = data;
    }
  }

  /// データを保存
  Future<void> _saveData() async {
    await StorageService.saveShiftData(state);
  }

  /// 人物を追加
  void addPerson(Person person) {
    state = state.copyWith(
      people: [...state.people, person],
    );
    _saveData();
  }

  /// 人物を削除
  void removePerson(String personId) {
    state = state.copyWith(
      people: state.people.where((p) => p.id != personId).toList(),
    );
    
    // 不公平スコアから削除
    final newSorryScores = Map<String, int>.from(state.sorryScores);
    newSorryScores.remove(personId);
    
    // 全ての日付のシフトから削除
    final newDailyShifts = <String, DailyShift>{};
    for (final entry in state.dailyShifts.entries) {
      final shift = entry.value;
      final newWantsMap = Map<String, String>.from(shift.wantsMap);
      newWantsMap.remove(personId);
      
      final newConstCustomer = Map<String, String>.from(shift.constCustomer);
      newConstCustomer.remove(personId);
      
      newDailyShifts[entry.key] = shift.copyWith(
        wantsMap: newWantsMap,
        constCustomer: newConstCustomer,
      );
    }
    
    state = state.copyWith(
      sorryScores: newSorryScores,
      dailyShifts: newDailyShifts,
    );
    _saveData();
  }

  /// 人物を更新
  void updatePerson(Person person) {
    state = state.copyWith(
      people: state.people
          .map((p) => p.id == person.id ? person : p)
          .toList(),
    );
    _saveData();
  }

  /// スキルを追加
  void addSkill(String skill) {
    if (state.skills.contains(skill)) return;
    state = state.copyWith(
      skills: [...state.skills, skill],
    );
    _saveData();
  }

  /// スキルを削除
  void removeSkill(String skill) {
    // スキルリストから削除
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
    
    // スタッフのスキルからも削除
    final updatedPeople = state.people.map((person) {
      if (person.skills.contains(skill)) {
        return person.copyWith(
          skills: person.skills.where((s) => s != skill).toList(),
        );
      }
      return person;
    }).toList();
    
    // 全ての日付のシフトから削除
    final newDailyShifts = <String, DailyShift>{};
    for (final entry in state.dailyShifts.entries) {
      final shift = entry.value;
      
      final newRequiredMap = Map<String, int>.from(shift.requiredMap);
      newRequiredMap.remove(skill);
      
      final newWantsMap = Map<String, String>.from(shift.wantsMap);
      newWantsMap.removeWhere((key, value) => value == skill);
      
      final newConstCustomer = Map<String, String>.from(shift.constCustomer);
      newConstCustomer.removeWhere((key, value) => value == skill);
      
      newDailyShifts[entry.key] = shift.copyWith(
        requiredMap: newRequiredMap,
        wantsMap: newWantsMap,
        constCustomer: newConstCustomer,
      );
    }
    
    state = state.copyWith(
      people: updatedPeople,
      dailyShifts: newDailyShifts,
    );
    _saveData();
  }

  /// 日付ごとのシフトデータを更新
  void updateDailyShift(DailyShift dailyShift) {
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    newDailyShifts[dailyShift.shiftId] = dailyShift;
    state = state.copyWith(dailyShifts: newDailyShifts);
    _saveData();
  }

  /// 特定の日付のシフトに希望を設定
  void setDailyWant(String shiftId, String personId, String skill) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap[personId] = skill;
    
    updateDailyShift(shift.copyWith(wantsMap: newWantsMap));
  }

  /// 特定の日付のシフトの希望を削除
  void removeDailyWant(String shiftId, String personId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap.remove(personId);
    
    updateDailyShift(shift.copyWith(wantsMap: newWantsMap));
  }

  /// 特定の日付のシフトの必要人数を設定
  void setDailyRequired(String shiftId, String skill, int count) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newRequiredMap = Map<String, int>.from(shift.requiredMap);
    newRequiredMap[skill] = count;
    
    updateDailyShift(shift.copyWith(requiredMap: newRequiredMap));
  }

  /// 特定の日付のシフトに固定スタッフを設定
  void setDailyConstCustomer(String shiftId, String personId, String skill) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newConstCustomer = Map<String, String>.from(shift.constCustomer);
    newConstCustomer[personId] = skill;
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap[personId] = skill;
    
    updateDailyShift(shift.copyWith(
      constCustomer: newConstCustomer,
      wantsMap: newWantsMap,
    ));
  }

  /// 特定の日付のシフトの固定スタッフを削除
  void removeDailyConstCustomer(String shiftId, String personId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newConstCustomer = Map<String, String>.from(shift.constCustomer);
    newConstCustomer.remove(personId);
    
    updateDailyShift(shift.copyWith(constCustomer: newConstCustomer));
  }

  /// シフトを計算
  Future<void> calculateShift(String shiftId) async {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;

    // peopleMapを作成
    final peopleMap = <String, List<String>>{};
    for (final person in state.people) {
      peopleMap[person.id] = person.skills;
    }

    // 固定スタッフを除外したwantsMapを作成
    final filteredWantsMap = Map<String, String>.from(shift.wantsMap);
    for (final personId in shift.constCustomer.keys) {
      filteredWantsMap.remove(personId);
    }

    // アルゴリズム実行
    final result = ShiftAutoAlgorithm.run(
      peopleMap: peopleMap,
      wantsMap: filteredWantsMap,
      requiredMap: shift.requiredMap,
      constCustomer: shift.constCustomer,
      sorryScores: state.sorryScores,
    );

    // 結果を保存
    updateDailyShift(shift.copyWith(
      resultMap: result.resultMap,
      isCalculated: true,
    ));

    // 不公平スコアを更新
    state = state.copyWith(sorryScores: result.newSorryScores);
    _saveData();
  }

  /// 複数のシフトを計算
  Future<void> calculateShifts(List<String> shiftIds) async {
    for (final shiftId in shiftIds) {
      await calculateShift(shiftId);
    }
  }

  /// 不公平スコアを更新
  void updateSorryScores(Map<String, int> newScores) {
    state = state.copyWith(sorryScores: newScores);
    _saveData();
  }

  /// データをリセット
  void reset() {
    state = ShiftData.sample();
    _saveData();
  }
}

/// ShiftDataプロバイダー
final shiftDataProvider =
    StateNotifierProvider<ShiftDataNotifier, ShiftData>((ref) {
  return ShiftDataNotifier();
});