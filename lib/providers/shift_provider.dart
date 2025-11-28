// providers/shift_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shift_data.dart';
import '../services/supabase_data_service.dart';
import '../services/shift_auto_algorithm.dart';

/// ShiftDataの状態管理
class ShiftDataNotifier extends StateNotifier<ShiftData> {
  ShiftDataNotifier() : super(ShiftData.sample()) {
    _loadData();
  }

  bool _isLoading = false;

  /// データを読み込み
  Future<void> _loadData() async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      final data = await SupabaseDataService.loadAllData();
      state = data;
    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// データを再読み込み
  Future<void> reload() async {
    await _loadData();
  }

  /// シフトパターンを追加
  Future<void> addShiftPattern(ShiftPattern pattern) async {
    if (state.shiftPatterns.any((p) => p.id == pattern.id || p.name == pattern.name)) {
      return;
    }
    
    state = state.copyWith(
      shiftPatterns: [...state.shiftPatterns, pattern],
    );
    
    await SupabaseDataService.addShiftPattern(pattern);
  }

  /// シフトパターンを削除
  Future<void> removeShiftPattern(String patternId) async {
    if (state.shiftPatterns.length <= 1) return;
    
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns.where((p) => p.id != patternId).toList(),
    );
    
    // このパターンを使用しているdailyShiftsを削除
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    final keysToRemove = newDailyShifts.keys.where((key) => key.contains('-$patternId')).toList();
    for (final key in keysToRemove) {
      newDailyShifts.remove(key);
      await SupabaseDataService.removeDailyShift(key);
    }
    
    state = state.copyWith(dailyShifts: newDailyShifts);
    await SupabaseDataService.removeShiftPattern(patternId);
  }

  /// シフトパターンを更新
  Future<void> updateShiftPattern(ShiftPattern pattern) async {
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns
          .map((p) => p.id == pattern.id ? pattern : p)
          .toList(),
    );
    
    await SupabaseDataService.updateShiftPattern(pattern);
  }

  /// シフトパターンのデフォルト必要人数を設定
  Future<void> setPatternDefaultRequired(String patternId, String skill, int count) async {
    final pattern = state.shiftPatterns.firstWhere((p) => p.id == patternId);
    final newDefaultRequired = Map<String, int>.from(pattern.defaultRequiredMap);
    
    if (count > 0) {
      newDefaultRequired[skill] = count;
    } else {
      newDefaultRequired.remove(skill);
    }
    
    await updateShiftPattern(pattern.copyWith(defaultRequiredMap: newDefaultRequired));
  }

  /// シフトパターンの順序を更新
  Future<void> reorderShiftPatterns(int oldIndex, int newIndex) async {
    final patterns = List<ShiftPattern>.from(state.shiftPatterns);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = patterns.removeAt(oldIndex);
    patterns.insert(newIndex, item);
    
    final updatedPatterns = patterns.asMap().entries.map((entry) {
      return entry.value.copyWith(sortOrder: entry.key);
    }).toList();
    
    state = state.copyWith(shiftPatterns: updatedPatterns);
    
    // 全パターンを更新
    for (final pattern in updatedPatterns) {
      await SupabaseDataService.updateShiftPattern(pattern);
    }
  }

  /// 人物を追加
  Future<void> addPerson(Person person) async {
    // まずDBに追加してIDを取得
    final newId = await SupabaseDataService.addStaff(person);
    final newPerson = Person(id: newId, name: person.name, skills: person.skills);
    
    state = state.copyWith(
      people: [...state.people, newPerson],
    );
  }

  /// 人物を削除
  Future<void> removePerson(String personId) async {
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
      
      final newConstStaff = Map<String, String>.from(shift.constStaff);
      newConstStaff.remove(personId);
      
      final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
      newCalculatedStaff.remove(personId);
      
      final updatedShift = shift.copyWith(
        wantsMap: newWantsMap,
        constStaff: newConstStaff,
        calculatedStaff: newCalculatedStaff,
      );
      newDailyShifts[entry.key] = updatedShift;
      
      // DBも更新
      await SupabaseDataService.saveDailyShift(updatedShift);
    }
    
    state = state.copyWith(
      sorryScores: newSorryScores,
      dailyShifts: newDailyShifts,
    );
    
    await SupabaseDataService.removeStaff(personId);
    await SupabaseDataService.saveSorryScores(newSorryScores);
  }

  /// 人物を更新
  Future<void> updatePerson(Person person) async {
    state = state.copyWith(
      people: state.people
          .map((p) => p.id == person.id ? person : p)
          .toList(),
    );
    
    await SupabaseDataService.updateStaff(person);
  }

  /// スキルを追加
  Future<void> addSkill(String skill) async {
    if (state.skills.contains(skill)) return;
    
    state = state.copyWith(
      skills: [...state.skills, skill],
    );
    
    await SupabaseDataService.addSkill(skill);
  }

  /// スキルを削除
  Future<void> removeSkill(String skill) async {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
    
    // スタッフのスキルからも削除
    final updatedPeople = <Person>[];
    for (final person in state.people) {
      if (person.skills.contains(skill)) {
        final updated = person.copyWith(
          skills: person.skills.where((s) => s != skill).toList(),
        );
        updatedPeople.add(updated);
        await SupabaseDataService.updateStaff(updated);
      } else {
        updatedPeople.add(person);
      }
    }
    
    // 全ての日付のシフトから削除
    final newDailyShifts = <String, DailyShift>{};
    for (final entry in state.dailyShifts.entries) {
      final shift = entry.value;
      
      final newRequiredMap = Map<String, int>.from(shift.requiredMap);
      newRequiredMap.remove(skill);
      
      final newWantsMap = Map<String, String>.from(shift.wantsMap);
      newWantsMap.removeWhere((key, value) => value == skill);
      
      final newConstStaff = Map<String, String>.from(shift.constStaff);
      newConstStaff.removeWhere((key, value) => value == skill);
      
      final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
      newCalculatedStaff.removeWhere((key, value) => value == skill);
      
      final updatedShift = shift.copyWith(
        requiredMap: newRequiredMap,
        wantsMap: newWantsMap,
        constStaff: newConstStaff,
        calculatedStaff: newCalculatedStaff,
      );
      newDailyShifts[entry.key] = updatedShift;
      
      await SupabaseDataService.saveDailyShift(updatedShift);
    }
    
    state = state.copyWith(
      people: updatedPeople,
      dailyShifts: newDailyShifts,
    );
    
    await SupabaseDataService.removeSkill(skill);
  }

  /// 日付ごとのシフトデータを更新
  Future<void> updateDailyShift(DailyShift dailyShift) async {
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    
    // 新規作成の場合、デフォルトの必要人数を適用
    if (!state.dailyShifts.containsKey(dailyShift.shiftId) && 
        dailyShift.requiredMap.isEmpty) {
      try {
        final parts = dailyShift.shiftId.split('-');
        if (parts.length >= 4) {
          final patternId = parts.sublist(3).join('-');
          final pattern = state.shiftPatterns.firstWhere(
            (p) => p.id == patternId,
            orElse: () => state.shiftPatterns.first,
          );
          dailyShift = dailyShift.copyWith(
            requiredMap: Map<String, int>.from(pattern.defaultRequiredMap),
          );
        }
      } catch (e) {
        // エラーが発生した場合はそのまま保存
      }
    }
    
    newDailyShifts[dailyShift.shiftId] = dailyShift;
    state = state.copyWith(dailyShifts: newDailyShifts);
    
    await SupabaseDataService.saveDailyShift(dailyShift);
  }

  /// 特定の日付のシフトを取得または作成
  DailyShift _getOrCreateDailyShift(String shiftId, DateTime date, String shiftType) {
    if (state.dailyShifts.containsKey(shiftId)) {
      return state.dailyShifts[shiftId]!;
    }
    
    Map<String, int> defaultRequired = {};
    try {
      final parts = shiftId.split('-');
      if (parts.length >= 4) {
        final patternId = parts.sublist(3).join('-');
        final pattern = state.shiftPatterns.firstWhere(
          (p) => p.id == patternId,
          orElse: () => state.shiftPatterns.first,
        );
        defaultRequired = Map<String, int>.from(pattern.defaultRequiredMap);
      }
    } catch (e) {
      defaultRequired = {};
    }
    
    return DailyShift(
      shiftId: shiftId,
      date: date,
      shiftType: shiftType,
      wantsMap: {},
      requiredMap: defaultRequired,
      constStaff: {},
      calculatedStaff: {},
    );
  }

  /// 特定の日付のシフトに希望を設定
  Future<void> setDailyWant(String shiftId, String personId, String skill) async {
    final parts = shiftId.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final patternId = parts.sublist(3).join('-');
    final pattern = state.shiftPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => state.shiftPatterns.first,
    );
    
    final shift = _getOrCreateDailyShift(shiftId, date, pattern.name);
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap[personId] = skill;
    
    await updateDailyShift(shift.copyWith(wantsMap: newWantsMap));
  }

  /// 特定の日付のシフトの希望を削除
  Future<void> removeDailyWant(String shiftId, String personId) async {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap.remove(personId);
    
    await updateDailyShift(shift.copyWith(wantsMap: newWantsMap));
  }

  /// 特定の日付のシフトの必要人数を設定
  Future<void> setDailyRequired(String shiftId, String skill, int count) async {
    final parts = shiftId.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final patternId = parts.sublist(3).join('-');
    final pattern = state.shiftPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => state.shiftPatterns.first,
    );
    
    final shift = _getOrCreateDailyShift(shiftId, date, pattern.name);
    
    final newRequiredMap = Map<String, int>.from(shift.requiredMap);
    if (count > 0) {
      newRequiredMap[skill] = count;
    } else {
      newRequiredMap.remove(skill);
    }
    
    await updateDailyShift(shift.copyWith(requiredMap: newRequiredMap));
  }

  /// 特定の日付のシフトに固定スタッフを設定
  Future<void> setDailyConstStaff(String shiftId, String personId, String skill) async {
    final parts = shiftId.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final patternId = parts.sublist(3).join('-');
    final pattern = state.shiftPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => state.shiftPatterns.first,
    );
    
    final shift = _getOrCreateDailyShift(shiftId, date, pattern.name);
    
    final newConstStaff = Map<String, String>.from(shift.constStaff);
    newConstStaff[personId] = skill;
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap[personId] = skill;
    
    await updateDailyShift(shift.copyWith(
      constStaff: newConstStaff,
      wantsMap: newWantsMap,
    ));
  }

  /// 特定の日付のシフトの固定スタッフを削除
  Future<void> removeDailyConstStaff(String shiftId, String personId) async {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newConstStaff = Map<String, String>.from(shift.constStaff);
    newConstStaff.remove(personId);
    
    await updateDailyShift(shift.copyWith(constStaff: newConstStaff));
  }

  /// 計算結果配置を希望状態に戻す
  Future<void> revertCalculatedToWant(String shiftId, String personId) async {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
    final skill = newCalculatedStaff.remove(personId);
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    if (skill != null) {
      newWantsMap[personId] = skill;
    }
    
    await updateDailyShift(shift.copyWith(
      calculatedStaff: newCalculatedStaff,
      wantsMap: newWantsMap,
    ));
  }

  /// シフトを計算
  Future<void> calculateShift(String shiftId) async {
    final parts = shiftId.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final patternId = parts.sublist(3).join('-');
    final pattern = state.shiftPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => state.shiftPatterns.first,
    );
    
    final shift = _getOrCreateDailyShift(shiftId, date, pattern.name);

    final peopleMap = <String, List<String>>{};
    for (final person in state.people) {
      peopleMap[person.id] = person.skills;
    }

    final allConstStaff = <String, String>{};
    allConstStaff.addAll(shift.constStaff);
    allConstStaff.addAll(shift.calculatedStaff);

    final filteredWantsMap = Map<String, String>.from(shift.wantsMap);
    for (final personId in allConstStaff.keys) {
      filteredWantsMap.remove(personId);
    }

    final result = ShiftAutoAlgorithm.run(
      peopleMap: peopleMap,
      wantsMap: filteredWantsMap,
      requiredMap: shift.requiredMap,
      constCustomer: allConstStaff,
      sorryScores: state.sorryScores,
      allDailyShifts: state.dailyShifts,
    );

    final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
    final newlyAssigned = <String>{};
    
    for (final entry in result.resultMap.entries) {
      final skill = entry.key;
      for (final personId in entry.value) {
        newCalculatedStaff[personId] = skill;
        newlyAssigned.add(personId);
      }
    }

    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    for (final personId in newlyAssigned) {
      newWantsMap.remove(personId);
    }

    await updateDailyShift(shift.copyWith(
      calculatedStaff: newCalculatedStaff,
      wantsMap: newWantsMap,
      resultMap: result.resultMap,
      isCalculated: true,
    ));

    state = state.copyWith(sorryScores: result.newSorryScores);
    await SupabaseDataService.saveSorryScores(result.newSorryScores);
  }

  /// 複数のシフトを計算
  Future<void> calculateShifts(List<String> shiftIds) async {
    for (final shiftId in shiftIds) {
      await calculateShift(shiftId);
    }
  }

  /// 不公平スコアを更新
  Future<void> updateSorryScores(Map<String, int> newScores) async {
    state = state.copyWith(sorryScores: newScores);
    await SupabaseDataService.saveSorryScores(newScores);
  }

  /// 特定の人のシフトをクリア
  Future<void> clearPersonShift(String shiftId, String personId) async {
    final parts = shiftId.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final patternId = parts.sublist(3).join('-');
    final pattern = state.shiftPatterns.firstWhere(
      (p) => p.id == patternId,
      orElse: () => state.shiftPatterns.first,
    );
    
    final shift = _getOrCreateDailyShift(shiftId, date, pattern.name);
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap.remove(personId);
    
    final newConstStaff = Map<String, String>.from(shift.constStaff);
    newConstStaff.remove(personId);
    
    final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
    newCalculatedStaff.remove(personId);
    
    Map<String, List<String>>? newResultMap;
    if (shift.resultMap != null) {
      newResultMap = {};
      for (final entry in shift.resultMap!.entries) {
        newResultMap[entry.key] = entry.value.where((id) => id != personId).toList();
      }
    }
    
    await updateDailyShift(shift.copyWith(
      wantsMap: newWantsMap,
      constStaff: newConstStaff,
      calculatedStaff: newCalculatedStaff,
      resultMap: newResultMap,
    ));
  }

  /// 特定の日付のシフトをクリア
  Future<void> clearDailyShift(String shiftId) async {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    await updateDailyShift(shift.copyWith(
      wantsMap: {},
      constStaff: {},
      calculatedStaff: {},
      resultMap: null,
      isCalculated: false,
    ));
  }

  /// 全てのシフトをクリア
  Future<void> clearAllShifts() async {
    final newDailyShifts = <String, DailyShift>{};
    for (final entry in state.dailyShifts.entries) {
      final cleared = entry.value.copyWith(
        wantsMap: {},
        constStaff: {},
        calculatedStaff: {},
        resultMap: null,
        isCalculated: false,
      );
      newDailyShifts[entry.key] = cleared;
      await SupabaseDataService.saveDailyShift(cleared);
    }
    state = state.copyWith(dailyShifts: newDailyShifts);
  }

  /// データをリセット
  Future<void> reset() async {
    state = ShiftData.sample();
    // 注意: DBのデータは削除しない（必要なら別途実装）
  }
}

/// ShiftDataプロバイダー
final shiftDataProvider =
    StateNotifierProvider<ShiftDataNotifier, ShiftData>((ref) {
  return ShiftDataNotifier();
});