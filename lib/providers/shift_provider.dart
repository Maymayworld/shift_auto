// providers/shift_provider.dart
import 'dart:async';
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
  
  // 保存待ちのシフトを管理
  final Set<String> _pendingShiftIds = {};
  Timer? _saveTimer;

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

  // ============ 遅延保存の仕組み ============

  /// シフトを保存キューに追加（デバウンス）
  void _queueShiftSave(String shiftId) {
    _pendingShiftIds.add(shiftId);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _flushPendingShifts();
    });
  }

  /// 保存待ちのシフトを一括保存
  Future<void> _flushPendingShifts() async {
    if (_pendingShiftIds.isEmpty) return;
    
    final shiftsToSave = _pendingShiftIds
        .map((id) => state.dailyShifts[id])
        .whereType<DailyShift>()
        .toList();
    
    _pendingShiftIds.clear();
    
    if (shiftsToSave.isNotEmpty) {
      await SupabaseDataService.saveDailyShiftsBatch(shiftsToSave);
    }
  }

  /// 即座に保存（画面離脱時などに呼ぶ）
  Future<void> flushNow() async {
    _saveTimer?.cancel();
    await _flushPendingShifts();
  }

  // ============ シフトパターン ============

  Future<void> addShiftPattern(ShiftPattern pattern) async {
    if (state.shiftPatterns.any((p) => p.id == pattern.id || p.name == pattern.name)) {
      return;
    }
    
    state = state.copyWith(
      shiftPatterns: [...state.shiftPatterns, pattern],
    );
    
    await SupabaseDataService.addShiftPattern(pattern);
  }

  Future<void> removeShiftPattern(String patternId) async {
    if (state.shiftPatterns.length <= 1) return;
    
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns.where((p) => p.id != patternId).toList(),
    );
    
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    final keysToRemove = newDailyShifts.keys.where((key) => key.contains('-$patternId')).toList();
    for (final key in keysToRemove) {
      newDailyShifts.remove(key);
      await SupabaseDataService.removeDailyShift(key);
    }
    
    state = state.copyWith(dailyShifts: newDailyShifts);
    await SupabaseDataService.removeShiftPattern(patternId);
  }

  Future<void> updateShiftPattern(ShiftPattern pattern) async {
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns
          .map((p) => p.id == pattern.id ? pattern : p)
          .toList(),
    );
    
    await SupabaseDataService.updateShiftPattern(pattern);
  }

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
    
    for (final pattern in updatedPatterns) {
      await SupabaseDataService.updateShiftPattern(pattern);
    }
  }

  // ============ スタッフ ============

  Future<void> addPerson(Person person) async {
    final newId = await SupabaseDataService.addStaff(person);
    final newPerson = Person(id: newId, name: person.name, skills: person.skills);
    
    state = state.copyWith(
      people: [...state.people, newPerson],
    );
  }

  Future<void> removePerson(String personId) async {
    state = state.copyWith(
      people: state.people.where((p) => p.id != personId).toList(),
    );
    
    final newSorryScores = Map<String, int>.from(state.sorryScores);
    newSorryScores.remove(personId);
    
    final newDailyShifts = <String, DailyShift>{};
    final modifiedShifts = <DailyShift>[];
    
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
      modifiedShifts.add(updatedShift);
    }
    
    state = state.copyWith(
      sorryScores: newSorryScores,
      dailyShifts: newDailyShifts,
    );
    
    await SupabaseDataService.removeStaff(personId);
    await SupabaseDataService.saveSorryScores(newSorryScores);
    if (modifiedShifts.isNotEmpty) {
      await SupabaseDataService.saveDailyShiftsBatch(modifiedShifts);
    }
  }

  Future<void> updatePerson(Person person) async {
    state = state.copyWith(
      people: state.people
          .map((p) => p.id == person.id ? person : p)
          .toList(),
    );
    
    await SupabaseDataService.updateStaff(person);
  }

  // ============ スキル ============

  Future<void> addSkill(String skill) async {
    if (state.skills.contains(skill)) return;
    
    state = state.copyWith(
      skills: [...state.skills, skill],
    );
    
    await SupabaseDataService.addSkill(skill);
  }

  Future<void> removeSkill(String skill) async {
    state = state.copyWith(
      skills: state.skills.where((s) => s != skill).toList(),
    );
    
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
    
    final newDailyShifts = <String, DailyShift>{};
    final modifiedShifts = <DailyShift>[];
    
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
      modifiedShifts.add(updatedShift);
    }
    
    state = state.copyWith(
      people: updatedPeople,
      dailyShifts: newDailyShifts,
    );
    
    await SupabaseDataService.removeSkill(skill);
    if (modifiedShifts.isNotEmpty) {
      await SupabaseDataService.saveDailyShiftsBatch(modifiedShifts);
    }
  }

  // ============ 日別シフト（ローカル優先 + 遅延保存） ============

  /// 日付ごとのシフトデータを更新（ローカル即時 + 遅延保存）
  /// 日付ごとのシフトデータを更新（ローカル即時 + 遅延保存）
  void updateDailyShift(DailyShift dailyShift) {
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    
    // 新規作成の場合、requiredMapを空にする（デフォルト値は設定しない）
    if (!state.dailyShifts.containsKey(dailyShift.shiftId)) {
      // requiredMapが設定されていない場合は空のまま保存
      // これにより、getDailyShift()で毎回デフォルト値が適用される
      if (dailyShift.wantsMap.isEmpty && 
          dailyShift.constStaff.isEmpty && 
          dailyShift.calculatedStaff.isEmpty) {
        // 完全に空の場合は、requiredMapも空にする
        dailyShift = dailyShift.copyWith(requiredMap: {});
      }
    }
    
    newDailyShifts[dailyShift.shiftId] = dailyShift;
    state = state.copyWith(dailyShifts: newDailyShifts);
    
    // 遅延保存キューに追加
    _queueShiftSave(dailyShift.shiftId);
  }

  /// 特定の日付のシフトを取得または作成
  /// 特定の日付のシフトを取得または作成
  DailyShift _getOrCreateDailyShift(String shiftId, DateTime date, String shiftType) {
    if (state.dailyShifts.containsKey(shiftId)) {
      return state.dailyShifts[shiftId]!;
    }
    
    // 新規作成時は requiredMap を空にする
    // デフォルト値は getDailyShift() で適用される
    return DailyShift(
      shiftId: shiftId,
      date: date,
      shiftType: shiftType,
      wantsMap: {},
      requiredMap: {}, // 空にする！
      constStaff: {},
      calculatedStaff: {},
    );
  }

  /// 特定の日付のシフトに希望を設定
  void setDailyWant(String shiftId, String personId, String skill) {
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
    
    // ユーザーが手動編集したのでカスタマイズフラグをtrueに
    updateDailyShift(shift.copyWith(
      requiredMap: newRequiredMap,
      isRequiredCustomized: true, // ← 追加
    ));
  }

  /// 特定の日付のシフトに固定スタッフを設定
  void setDailyConstStaff(String shiftId, String personId, String skill) {
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
    
    updateDailyShift(shift.copyWith(
      constStaff: newConstStaff,
      wantsMap: newWantsMap,
    ));
  }

  /// 特定の日付のシフトの固定スタッフを削除
  void removeDailyConstStaff(String shiftId, String personId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newConstStaff = Map<String, String>.from(shift.constStaff);
    newConstStaff.remove(personId);
    
    updateDailyShift(shift.copyWith(constStaff: newConstStaff));
  }

  /// 計算結果配置を希望状態に戻す
  void revertCalculatedToWant(String shiftId, String personId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    final newCalculatedStaff = Map<String, String>.from(shift.calculatedStaff);
    final skill = newCalculatedStaff.remove(personId);
    
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    if (skill != null) {
      newWantsMap[personId] = skill;
    }
    
    updateDailyShift(shift.copyWith(
      calculatedStaff: newCalculatedStaff,
      wantsMap: newWantsMap,
    ));
  }

  /// 特定の人のシフトをクリア
  void clearPersonShift(String shiftId, String personId) {
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
    
    updateDailyShift(shift.copyWith(
      wantsMap: newWantsMap,
      constStaff: newConstStaff,
      calculatedStaff: newCalculatedStaff,
      resultMap: newResultMap,
    ));
  }

  /// 特定の日付のシフトをクリア
  void clearDailyShift(String shiftId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    updateDailyShift(shift.copyWith(
      wantsMap: {},
      constStaff: {},
      calculatedStaff: {},
      resultMap: null,
      isCalculated: false,
    ));
  }

  // ============ シフト計算（バッチ保存） ============

  /// シフトを計算（ローカルで計算、最後にまとめて保存）
  void _calculateShiftLocal(String shiftId) {
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

    // ローカル状態を更新（保存はしない）
    final updatedShift = shift.copyWith(
      calculatedStaff: newCalculatedStaff,
      wantsMap: newWantsMap,
      resultMap: result.resultMap,
      isCalculated: true,
    );
    
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    newDailyShifts[shiftId] = updatedShift;

    state = state.copyWith(
      dailyShifts: newDailyShifts,
      sorryScores: result.newSorryScores,
    );
  }

  /// 複数のシフトを計算（バッチ保存）
  Future<void> calculateShifts(List<String> shiftIds) async {
    // 全てローカルで計算
    for (final shiftId in shiftIds) {
      _calculateShiftLocal(shiftId);
    }
    
    // 計算結果をまとめて保存
    final shiftsToSave = shiftIds
        .map((id) => state.dailyShifts[id])
        .whereType<DailyShift>()
        .toList();
    
    await SupabaseDataService.saveDailyShiftsBatch(shiftsToSave);
    await SupabaseDataService.saveSorryScores(state.sorryScores);
  }

  /// 単一シフトを計算
  Future<void> calculateShift(String shiftId) async {
    await calculateShifts([shiftId]);
  }

  /// 全てのシフトをクリア
  Future<void> clearAllShifts() async {
    final newDailyShifts = <String, DailyShift>{};
    final clearedShifts = <DailyShift>[];
    
    for (final entry in state.dailyShifts.entries) {
      final cleared = entry.value.copyWith(
        wantsMap: {},
        constStaff: {},
        calculatedStaff: {},
        resultMap: null,
        isCalculated: false,
      );
      newDailyShifts[entry.key] = cleared;
      clearedShifts.add(cleared);
    }
    
    state = state.copyWith(dailyShifts: newDailyShifts);
    
    // まとめて保存
    if (clearedShifts.isNotEmpty) {
      await SupabaseDataService.saveDailyShiftsBatch(clearedShifts);
    }
  }

  /// 不公平スコアを更新
  Future<void> updateSorryScores(Map<String, int> newScores) async {
    state = state.copyWith(sorryScores: newScores);
    await SupabaseDataService.saveSorryScores(newScores);
  }

  /// データをリセット
  Future<void> reset() async {
    state = ShiftData.sample();
  }
}

/// ShiftDataプロバイダー
final shiftDataProvider =
    StateNotifierProvider<ShiftDataNotifier, ShiftData>((ref) {
  return ShiftDataNotifier();
});