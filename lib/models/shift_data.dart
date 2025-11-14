// models/shift_data.dart
/// シフトパターン（通し、早番、遅番など）
class ShiftPattern {
  final String id;
  final String name;
  final int sortOrder;
  final Map<String, int> defaultRequiredMap; // skill -> count のデフォルト値

  ShiftPattern({
    required this.id,
    required this.name,
    required this.sortOrder,
    Map<String, int>? defaultRequiredMap,
  }) : defaultRequiredMap = defaultRequiredMap ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sortOrder': sortOrder,
        'defaultRequiredMap': defaultRequiredMap,
      };

  factory ShiftPattern.fromJson(Map<String, dynamic> json) {
    Map<String, int> defaultRequired = {};
    try {
      if (json['defaultRequiredMap'] != null) {
        defaultRequired = Map<String, int>.from(json['defaultRequiredMap'] as Map);
      }
    } catch (e) {
      // エラーが発生した場合は空のマップを使用
      defaultRequired = {};
    }
    
    return ShiftPattern(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: json['sortOrder'] as int? ?? 0,
      defaultRequiredMap: defaultRequired,
    );
  }

  ShiftPattern copyWith({
    String? id,
    String? name,
    int? sortOrder,
    Map<String, int>? defaultRequiredMap,
  }) {
    return ShiftPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      defaultRequiredMap: defaultRequiredMap ?? this.defaultRequiredMap,
    );
  }
}

/// 人物（スタッフ）
class Person {
  final String id;
  final String name;
  final List<String> skills;

  Person({
    required this.id,
    required this.name,
    required this.skills,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'skills': skills,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        name: json['name'] as String,
        skills: List<String>.from(json['skills'] as List),
      );

  Person copyWith({
    String? id,
    String? name,
    List<String>? skills,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      skills: skills ?? this.skills,
    );
  }
}

/// 日付ごとのシフトデータ
class DailyShift {
  final String shiftId; // 例: "2025-11-03-through"
  final DateTime date;
  final String shiftType; // "通し", "早番", "遅番" など
  final Map<String, String> wantsMap; // personId -> skill or 'スキル指定なし'
  final Map<String, int> requiredMap; // skill -> count
  final Map<String, String> constStaff; // personId -> skill (固定スタッフ)
  final Map<String, String> calculatedStaff; // personId -> skill (計算結果で配置されたスタッフ)
  final Map<String, List<String>>? resultMap; // skill -> [personIds]
  final bool isCalculated; // 計算済みかどうか

  DailyShift({
    required this.shiftId,
    required this.date,
    required this.shiftType,
    required this.wantsMap,
    required this.requiredMap,
    required this.constStaff,
    Map<String, String>? calculatedStaff,
    this.resultMap,
    this.isCalculated = false,
  }) : calculatedStaff = calculatedStaff ?? {};

  Map<String, dynamic> toJson() => {
        'shiftId': shiftId,
        'date': date.toIso8601String(),
        'shiftType': shiftType,
        'wantsMap': wantsMap,
        'requiredMap': requiredMap,
        'constStaff': constStaff,
        'calculatedStaff': calculatedStaff,
        'resultMap': resultMap,
        'isCalculated': isCalculated,
      };

  factory DailyShift.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? resultMap;
    if (json['resultMap'] != null) {
      final map = json['resultMap'] as Map<String, dynamic>;
      resultMap = map.map((key, value) =>
          MapEntry(key, List<String>.from(value as List)));
    }

    return DailyShift(
      shiftId: json['shiftId'] as String,
      date: DateTime.parse(json['date'] as String),
      shiftType: json['shiftType'] as String,
      wantsMap: Map<String, String>.from(json['wantsMap'] as Map? ?? {}),
      requiredMap: Map<String, int>.from(json['requiredMap'] as Map? ?? {}),
      constStaff: Map<String, String>.from(json['constStaff'] as Map? ?? json['constCustomer'] as Map? ?? {}),
      calculatedStaff: Map<String, String>.from(json['calculatedStaff'] as Map? ?? {}),
      resultMap: resultMap,
      isCalculated: json['isCalculated'] as bool? ?? false,
    );
  }

  DailyShift copyWith({
    String? shiftId,
    DateTime? date,
    String? shiftType,
    Map<String, String>? wantsMap,
    Map<String, int>? requiredMap,
    Map<String, String>? constStaff,
    Map<String, String>? calculatedStaff,
    Map<String, List<String>>? resultMap,
    bool? isCalculated,
  }) {
    return DailyShift(
      shiftId: shiftId ?? this.shiftId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      wantsMap: wantsMap ?? this.wantsMap,
      requiredMap: requiredMap ?? this.requiredMap,
      constStaff: constStaff ?? this.constStaff,
      calculatedStaff: calculatedStaff ?? this.calculatedStaff,
      resultMap: resultMap ?? this.resultMap,
      isCalculated: isCalculated ?? this.isCalculated,
    );
  }

  /// 希望者数を取得
  int get wantsCount => wantsMap.length;

  /// 必要人数の合計を取得
  int get totalRequired => requiredMap.values.fold(0, (sum, count) => sum + count);
}

/// シフトデータ
class ShiftData {
  final List<Person> people;
  final List<String> skills;
  final List<ShiftPattern> shiftPatterns;
  final Map<String, int> sorryScores; // personId -> score
  final Map<String, DailyShift> dailyShifts; // shiftId -> DailyShift

  ShiftData({
    required this.people,
    required this.skills,
    required this.shiftPatterns,
    required this.sorryScores,
    required this.dailyShifts,
  });

  Map<String, dynamic> toJson() => {
        'people': people.map((p) => p.toJson()).toList(),
        'skills': skills,
        'shiftPatterns': shiftPatterns.map((p) => p.toJson()).toList(),
        'sorryScores': sorryScores,
        'dailyShifts': dailyShifts.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory ShiftData.fromJson(Map<String, dynamic> json) {
    // dailyShiftsのnullチェックと変換
    final Map<String, DailyShift> dailyShifts;
    if (json['dailyShifts'] != null) {
      final dailyShiftsJson = json['dailyShifts'] as Map<String, dynamic>;
      dailyShifts = dailyShiftsJson.map((key, value) =>
          MapEntry(key, DailyShift.fromJson(value as Map<String, dynamic>)));
    } else {
      dailyShifts = {};
    }

    // shiftPatternsの読み込み（後方互換性のためデフォルト値を設定）
    List<ShiftPattern> shiftPatterns;
    try {
      if (json['shiftPatterns'] != null && json['shiftPatterns'] is List) {
        shiftPatterns = (json['shiftPatterns'] as List)
            .map((p) => ShiftPattern.fromJson(p as Map<String, dynamic>))
            .toList();
      } else {
        // デフォルトは「通し」のみ
        shiftPatterns = [
          ShiftPattern(id: 'through', name: '通し', sortOrder: 0),
        ];
      }
    } catch (e) {
      // エラーが発生した場合もデフォルト値を設定
      shiftPatterns = [
        ShiftPattern(id: 'through', name: '通し', sortOrder: 0),
      ];
    }

    return ShiftData(
      people: json['people'] != null
          ? (json['people'] as List)
              .map((p) => Person.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      skills: json['skills'] != null 
          ? List<String>.from(json['skills'] as List)
          : [],
      shiftPatterns: shiftPatterns,
      sorryScores: json['sorryScores'] != null
          ? Map<String, int>.from(json['sorryScores'] as Map)
          : {},
      dailyShifts: dailyShifts,
    );
  }

  ShiftData copyWith({
    List<Person>? people,
    List<String>? skills,
    List<ShiftPattern>? shiftPatterns,
    Map<String, int>? sorryScores,
    Map<String, DailyShift>? dailyShifts,
  }) {
    return ShiftData(
      people: people ?? this.people,
      skills: skills ?? this.skills,
      shiftPatterns: shiftPatterns ?? this.shiftPatterns,
      sorryScores: sorryScores ?? this.sorryScores,
      dailyShifts: dailyShifts ?? this.dailyShifts,
    );
  }

  /// サンプルデータを生成（デフォルトで「通し」パターンを含む）
  static ShiftData sample() {
    return ShiftData(
      people: [],
      skills: [],
      shiftPatterns: [
        ShiftPattern(id: 'through', name: '通し', sortOrder: 0),
      ],
      sorryScores: {},
      dailyShifts: {},
    );
  }

  /// 特定の日付のシフトを取得（存在しない場合は作成）
  DailyShift getDailyShift(String shiftId, DateTime date, String shiftType) {
    if (dailyShifts.containsKey(shiftId)) {
      return dailyShifts[shiftId]!;
    }
    
    // 存在しない場合は空のシフトを返す
    // shiftIdからパターンIDを取得してデフォルト値を適用
    Map<String, int> defaultRequired = {};
    try {
      // shiftIdの形式: "2025-11-4-through"
      final parts = shiftId.split('-');
      if (parts.length >= 4) {
        final patternId = parts.sublist(3).join('-');
        final pattern = shiftPatterns.firstWhere(
          (p) => p.id == patternId,
          orElse: () => shiftPatterns.first,
        );
        defaultRequired = Map<String, int>.from(pattern.defaultRequiredMap);
      }
    } catch (e) {
      // エラーが発生した場合は空のマップを使用
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
}