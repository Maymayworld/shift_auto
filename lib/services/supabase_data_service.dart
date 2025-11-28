// services/supabase_data_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_data.dart';

class SupabaseDataService {
  static final _supabase = Supabase.instance.client;

  static String? get _userId => _supabase.auth.currentUser?.id;

  // ============ スキル ============

  /// スキル一覧を取得
  static Future<List<String>> getSkills() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('skills')
        .select('name')
        .eq('user_id', _userId!)
        .order('created_at');

    return (response as List).map((e) => e['name'] as String).toList();
  }

  /// スキルを追加
  static Future<void> addSkill(String name) async {
    if (_userId == null) return;

    await _supabase.from('skills').upsert({
      'user_id': _userId,
      'name': name,
    }, onConflict: 'user_id,name');
  }

  /// スキルを削除
  static Future<void> removeSkill(String name) async {
    if (_userId == null) return;

    await _supabase
        .from('skills')
        .delete()
        .eq('user_id', _userId!)
        .eq('name', name);
  }

  // ============ スタッフ ============

  /// スタッフ一覧を取得
  static Future<List<Person>> getStaff() async {
    if (_userId == null) return [];

    final response = await _supabase
        .from('staff')
        .select()
        .eq('user_id', _userId!)
        .order('created_at');

    return (response as List).map((e) => Person(
      id: e['id'] as String,
      name: e['name'] as String,
      skills: List<String>.from(e['skills'] ?? []),
    )).toList();
  }

  /// スタッフを追加
  static Future<String> addStaff(Person person) async {
    if (_userId == null) throw Exception('Not logged in');

    final response = await _supabase.from('staff').insert({
      'user_id': _userId,
      'name': person.name,
      'skills': person.skills,
    }).select().single();

    return response['id'] as String;
  }

  /// スタッフを更新
  static Future<void> updateStaff(Person person) async {
    if (_userId == null) return;

    await _supabase.from('staff').update({
      'name': person.name,
      'skills': person.skills,
    }).eq('id', person.id).eq('user_id', _userId!);
  }

  /// スタッフを削除
  static Future<void> removeStaff(String staffId) async {
    if (_userId == null) return;

    await _supabase
        .from('staff')
        .delete()
        .eq('id', staffId)
        .eq('user_id', _userId!);
  }

  // ============ シフトパターン ============

  /// シフトパターン一覧を取得
  static Future<List<ShiftPattern>> getShiftPatterns() async {
    if (_userId == null) return [ShiftPattern(id: 'through', name: '通し', sortOrder: 0)];

    final response = await _supabase
        .from('shift_patterns')
        .select()
        .eq('user_id', _userId!)
        .order('sort_order');

    if ((response as List).isEmpty) {
      // デフォルトパターンを作成
      await addShiftPattern(ShiftPattern(id: 'through', name: '通し', sortOrder: 0));
      return [ShiftPattern(id: 'through', name: '通し', sortOrder: 0)];
    }

    return response.map((e) => ShiftPattern(
      id: e['pattern_id'] as String,
      name: e['name'] as String,
      sortOrder: e['sort_order'] as int? ?? 0,
      defaultRequiredMap: Map<String, int>.from(e['default_required'] ?? {}),
    )).toList();
  }

  /// シフトパターンを追加
  static Future<void> addShiftPattern(ShiftPattern pattern) async {
    if (_userId == null) return;

    await _supabase.from('shift_patterns').upsert({
      'user_id': _userId,
      'pattern_id': pattern.id,
      'name': pattern.name,
      'sort_order': pattern.sortOrder,
      'default_required': pattern.defaultRequiredMap,
    }, onConflict: 'user_id,pattern_id');
  }

  /// シフトパターンを更新
  static Future<void> updateShiftPattern(ShiftPattern pattern) async {
    if (_userId == null) return;

    await _supabase.from('shift_patterns').update({
      'name': pattern.name,
      'sort_order': pattern.sortOrder,
      'default_required': pattern.defaultRequiredMap,
    }).eq('user_id', _userId!).eq('pattern_id', pattern.id);
  }

  /// シフトパターンを削除
  static Future<void> removeShiftPattern(String patternId) async {
    if (_userId == null) return;

    await _supabase
        .from('shift_patterns')
        .delete()
        .eq('user_id', _userId!)
        .eq('pattern_id', patternId);
  }

  // ============ 日別シフト ============

  /// 日別シフト一覧を取得
  static Future<Map<String, DailyShift>> getDailyShifts() async {
    if (_userId == null) return {};

    final response = await _supabase
        .from('daily_shifts')
        .select()
        .eq('user_id', _userId!);

    final Map<String, DailyShift> result = {};
    for (final e in response as List) {
      final shiftId = e['shift_id'] as String;
      
      Map<String, List<String>>? resultMap;
      if (e['result_map'] != null) {
        resultMap = (e['result_map'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, List<String>.from(value as List)),
        );
      }

      result[shiftId] = DailyShift(
        shiftId: shiftId,
        date: DateTime.parse(e['date'] as String),
        shiftType: e['shift_type'] as String,
        wantsMap: Map<String, String>.from(e['wants_map'] ?? {}),
        requiredMap: Map<String, int>.from(e['required_map'] ?? {}),
        constStaff: Map<String, String>.from(e['const_staff'] ?? {}),
        calculatedStaff: Map<String, String>.from(e['calculated_staff'] ?? {}),
        resultMap: resultMap,
        isCalculated: e['is_calculated'] as bool? ?? false,
      );
    }

    return result;
  }

  /// 日別シフトを保存（upsert）
  static Future<void> saveDailyShift(DailyShift shift) async {
    if (_userId == null) return;

    await _supabase.from('daily_shifts').upsert({
      'user_id': _userId,
      'shift_id': shift.shiftId,
      'date': shift.date.toIso8601String().split('T')[0],
      'shift_type': shift.shiftType,
      'wants_map': shift.wantsMap,
      'required_map': shift.requiredMap,
      'const_staff': shift.constStaff,
      'calculated_staff': shift.calculatedStaff,
      'result_map': shift.resultMap,
      'is_calculated': shift.isCalculated,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,shift_id');
  }

  /// 日別シフトを削除
  static Future<void> removeDailyShift(String shiftId) async {
    if (_userId == null) return;

    await _supabase
        .from('daily_shifts')
        .delete()
        .eq('user_id', _userId!)
        .eq('shift_id', shiftId);
  }

  // ============ 不公平スコア ============

  /// 不公平スコアを取得
  static Future<Map<String, int>> getSorryScores() async {
    if (_userId == null) return {};

    final response = await _supabase
        .from('sorry_scores')
        .select('scores')
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return {};
    return Map<String, int>.from(response['scores'] ?? {});
  }

  /// 不公平スコアを保存
  static Future<void> saveSorryScores(Map<String, int> scores) async {
    if (_userId == null) return;

    await _supabase.from('sorry_scores').upsert({
      'user_id': _userId,
      'scores': scores,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // ============ 全データ読み込み ============

  /// 全てのシフトデータを読み込み
  static Future<ShiftData> loadAllData() async {
    if (_userId == null) {
      return ShiftData.sample();
    }

    try {
      final results = await Future.wait([
        getSkills(),
        getStaff(),
        getShiftPatterns(),
        getDailyShifts(),
        getSorryScores(),
      ]);

      return ShiftData(
        skills: results[0] as List<String>,
        people: results[1] as List<Person>,
        shiftPatterns: results[2] as List<ShiftPattern>,
        dailyShifts: results[3] as Map<String, DailyShift>,
        sorryScores: results[4] as Map<String, int>,
      );
    } catch (e) {
      print('❌ Error loading data: $e');
      return ShiftData.sample();
    }
  }
}