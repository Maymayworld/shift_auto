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

  /// シフトパターンを追加
  void addShiftPattern(ShiftPattern pattern) {
    if (state.shiftPatterns.any((p) => p.id == pattern.id || p.name == pattern.name)) {
      return; // 重複は追加しない
    }
    state = state.copyWith(
      shiftPatterns: [...state.shiftPatterns, pattern],
    );
    _saveData();
  }

  /// シフトパターンを削除
  void removeShiftPattern(String patternId) {
    // 最後の1つは削除できない
    if (state.shiftPatterns.length <= 1) return;
    
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns.where((p) => p.id != patternId).toList(),
    );
    
    // このパターンを使用しているdailyShiftsを削除
    final newDailyShifts = Map<String, DailyShift>.from(state.dailyShifts);
    newDailyShifts.removeWhere((key, value) => key.contains('-$patternId'));
    
    state = state.copyWith(dailyShifts: newDailyShifts);
    _saveData();
  }

  /// シフトパターンを更新
  void updateShiftPattern(ShiftPattern pattern) {
    state = state.copyWith(
      shiftPatterns: state.shiftPatterns
          .map((p) => p.id == pattern.id ? pattern : p)
          .toList(),
    );
    _saveData();
  }

  /// シフトパターンのデフォルト必要人数を設定
  void setPatternDefaultRequired(String patternId, String skill, int count) {
    final pattern = state.shiftPatterns.firstWhere((p) => p.id == patternId);
    final newDefaultRequired = Map<String, int>.from(pattern.defaultRequiredMap);
    
    if (count > 0) {
      newDefaultRequired[skill] = count;
    } else {
      newDefaultRequired.remove(skill);
    }
    
    updateShiftPattern(pattern.copyWith(defaultRequiredMap: newDefaultRequired));
  }

  /// シフトパターンの順序を更新
  void reorderShiftPatterns(int oldIndex, int newIndex) {
    final patterns = List<ShiftPattern>.from(state.shiftPatterns);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = patterns.removeAt(oldIndex);
    patterns.insert(newIndex, item);
    
    // sortOrderを更新
    final updatedPatterns = patterns.asMap().entries.map((entry) {
      return entry.value.copyWith(sortOrder: entry.key);
    }).toList();
    
    state = state.copyWith(shiftPatterns: updatedPatterns);
    _saveData();
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
      
      final newConstStaff = Map<String, String>.from(shift.constStaff);
      newConstStaff.remove(personId);
      
      newDailyShifts[entry.key] = shift.copyWith(
        wantsMap: newWantsMap,
        constStaff: newConstStaff,
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
      
      final newConstStaff = Map<String, String>.from(shift.constStaff);
      newConstStaff.removeWhere((key, value) => value == skill);
      
      newDailyShifts[entry.key] = shift.copyWith(
        requiredMap: newRequiredMap,
        wantsMap: newWantsMap,
        constStaff: newConstStaff,
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
    
    // 新規作成の場合、デフォルトの必要人数を適用
    if (!state.dailyShifts.containsKey(dailyShift.shiftId) && 
        dailyShift.requiredMap.isEmpty) {
      // shiftIdからパターンIDを取得
      try {
        final parts = dailyShift.shiftId.split('-');
        if (parts.length >= 4) {
          final patternId = parts.sublist(3).join('-');
          final pattern = state.shiftPatterns.firstWhere(
            (p) => p.id == patternId,
            orElse: () => state.shiftPatterns.first,
          );
          // デフォルト値を適用
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
    _saveData();
  }

  /// 特定の日付のシフトを取得または作成
  DailyShift _getOrCreateDailyShift(String shiftId, DateTime date, String shiftType) {
    if (state.dailyShifts.containsKey(shiftId)) {
      return state.dailyShifts[shiftId]!;
    }
    
    // 存在しない場合は新規作成
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
    );
  }

  /// 特定の日付のシフトに希望を設定
  void setDailyWant(String shiftId, String personId, String skill) {
    // shiftIdから日付とシフトタイプを取得
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
    // shiftIdから日付とシフトタイプを取得
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
    
    updateDailyShift(shift.copyWith(requiredMap: newRequiredMap));
  }

  /// 特定の日付のシフトに固定スタッフを設定
  void setDailyConstStaff(String shiftId, String personId, String skill) {
    // shiftIdから日付とシフトタイプを取得
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

  /// シフトを計算
  Future<void> calculateShift(String shiftId) async {
    // shiftIdから日付とシフトタイプを取得
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

    // peopleMapを作成
    final peopleMap = <String, List<String>>{};
    for (final person in state.people) {
      peopleMap[person.id] = person.skills;
    }

    // 固定スタッフを除外したwantsMapを作成
    final filteredWantsMap = Map<String, String>.from(shift.wantsMap);
    for (final personId in shift.constStaff.keys) {
      filteredWantsMap.remove(personId);
    }

    // アルゴリズム実行
    final result = ShiftAutoAlgorithm.run(
      peopleMap: peopleMap,
      wantsMap: filteredWantsMap,
      requiredMap: shift.requiredMap,
      constCustomer: shift.constStaff,
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

  /// 特定の人のシフトをクリア（希望・固定・計算結果を削除）
  void clearPersonShift(String shiftId, String personId) {
    // shiftIdから日付とシフトタイプを取得
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
    
    // 希望を削除
    final newWantsMap = Map<String, String>.from(shift.wantsMap);
    newWantsMap.remove(personId);
    
    // 固定を削除
    final newConstStaff = Map<String, String>.from(shift.constStaff);
    newConstStaff.remove(personId);
    
    // 計算結果からも削除
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
      resultMap: newResultMap,
    ));
  }

  /// 特定の日付のシフトをクリア（全員の希望・固定・計算結果を削除）
  void clearDailyShift(String shiftId) {
    final shift = state.dailyShifts[shiftId];
    if (shift == null) return;
    
    updateDailyShift(shift.copyWith(
      wantsMap: {},
      constStaff: {},
      resultMap: null,
      isCalculated: false,
    ));
  }

  /// 全てのシフトをクリア
  void clearAllShifts() {
    final newDailyShifts = <String, DailyShift>{};
    for (final entry in state.dailyShifts.entries) {
      newDailyShifts[entry.key] = entry.value.copyWith(
        wantsMap: {},
        constStaff: {},
        resultMap: null,
        isCalculated: false,
      );
    }
    state = state.copyWith(dailyShifts: newDailyShifts);
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