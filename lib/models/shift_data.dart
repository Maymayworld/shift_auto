// models/shift_data.dart
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
  final String shiftId; // 例: "2025-11-03-early"
  final DateTime date;
  final String shiftType; // "早番" or "遅番"
  final Map<String, String> wantsMap; // personId -> skill or 'SA'
  final Map<String, int> requiredMap; // skill -> count
  final Map<String, String> constCustomer; // personId -> skill
  final Map<String, List<String>>? resultMap; // skill -> [personIds]
  final bool isCalculated; // 計算済みかどうか

  DailyShift({
    required this.shiftId,
    required this.date,
    required this.shiftType,
    required this.wantsMap,
    required this.requiredMap,
    required this.constCustomer,
    this.resultMap,
    this.isCalculated = false,
  });

  Map<String, dynamic> toJson() => {
        'shiftId': shiftId,
        'date': date.toIso8601String(),
        'shiftType': shiftType,
        'wantsMap': wantsMap,
        'requiredMap': requiredMap,
        'constCustomer': constCustomer,
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
      constCustomer: Map<String, String>.from(json['constCustomer'] as Map? ?? {}),
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
    Map<String, String>? constCustomer,
    Map<String, List<String>>? resultMap,
    bool? isCalculated,
  }) {
    return DailyShift(
      shiftId: shiftId ?? this.shiftId,
      date: date ?? this.date,
      shiftType: shiftType ?? this.shiftType,
      wantsMap: wantsMap ?? this.wantsMap,
      requiredMap: requiredMap ?? this.requiredMap,
      constCustomer: constCustomer ?? this.constCustomer,
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
  final Map<String, int> sorryScores; // personId -> score
  final Map<String, DailyShift> dailyShifts; // shiftId -> DailyShift

  ShiftData({
    required this.people,
    required this.skills,
    required this.sorryScores,
    required this.dailyShifts,
  });

  Map<String, dynamic> toJson() => {
        'people': people.map((p) => p.toJson()).toList(),
        'skills': skills,
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

    return ShiftData(
      people: json['people'] != null
          ? (json['people'] as List)
              .map((p) => Person.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
      skills: json['skills'] != null 
          ? List<String>.from(json['skills'] as List)
          : [],
      sorryScores: json['sorryScores'] != null
          ? Map<String, int>.from(json['sorryScores'] as Map)
          : {},
      dailyShifts: dailyShifts,
    );
  }

  ShiftData copyWith({
    List<Person>? people,
    List<String>? skills,
    Map<String, int>? sorryScores,
    Map<String, DailyShift>? dailyShifts,
  }) {
    return ShiftData(
      people: people ?? this.people,
      skills: skills ?? this.skills,
      sorryScores: sorryScores ?? this.sorryScores,
      dailyShifts: dailyShifts ?? this.dailyShifts,
    );
  }

  /// サンプルデータを生成（空のデータ）
  static ShiftData sample() {
    return ShiftData(
      people: [],
      skills: [],
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
    return DailyShift(
      shiftId: shiftId,
      date: date,
      shiftType: shiftType,
      wantsMap: {},
      requiredMap: {},
      constCustomer: {},
    );
  }
}