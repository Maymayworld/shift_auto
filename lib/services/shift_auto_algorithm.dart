// services/shift_auto_algorithm.dart
/// シフトオート - コアアルゴリズム
class ShiftAutoAlgorithm {
  /// 1. playersの作成
  static Map<String, List<String>> createPlayers({
    required Map<String, List<String>> peopleMap,
    required Map<String, String> wantsMap,
    required Map<String, int> fixedRequiredMap,
  }) {
    final players = <String, List<String>>{};

    for (final entry in wantsMap.entries) {
      final personId = entry.key;
      final wantSkill = entry.value;

      if (!peopleMap.containsKey(personId)) continue;

      var personSkills = List<String>.from(peopleMap[personId]!);

      // スキル指定がある場合は、そのスキルのみに絞る
      if (wantSkill != 'スキル指定なし') {
        if (personSkills.contains(wantSkill)) {
          personSkills = [wantSkill];
        } else {
          personSkills = [];
        }
      }

      // fixedRequiredMapに含まれないスキルを削除
      personSkills = personSkills
          .where((skill) => fixedRequiredMap.containsKey(skill))
          .toList();

      if (personSkills.isNotEmpty) {
        players[personId] = personSkills;
      }
    }
    
    return players;
  }

  /// 2. patterns_v1の作成 - 全パターン生成
  static List<Map<String, List<String>>> createPatternsV1({
    required Map<String, List<String>> players,
    required Map<String, int> fixedRequiredMap,
  }) {
    if (players.isEmpty) return [{}];

    final playerIds = players.keys.toList();
    final skillsOrder = fixedRequiredMap.keys.toList();
    final patterns = <Map<String, List<String>>>[];

    void generatePatternsRecursive(
      Map<String, List<String>> currentPattern,
      List<String> remainingPlayers,
      Map<String, int> currentCounts,
    ) {
      if (remainingPlayers.isEmpty) {
        // パターン完成
        patterns.add(Map.from(currentPattern));
        return;
      }

      final personId = remainingPlayers[0];
      final personSkills = players[personId]!;

      // この人を配置しないパターン
      generatePatternsRecursive(
        currentPattern,
        remainingPlayers.sublist(1),
        currentCounts,
      );

      // この人を各スキルに配置するパターン
      for (final skill in personSkills) {
        // 制約チェック：このスキルの枠が空いているか
        if ((currentCounts[skill] ?? 0) < fixedRequiredMap[skill]!) {
          final newPattern = <String, List<String>>{};
          for (final s in skillsOrder) {
            newPattern[s] = List.from(currentPattern[s] ?? []);
          }
          newPattern[skill]!.add(personId);

          final newCounts = Map<String, int>.from(currentCounts);
          newCounts[skill] = (newCounts[skill] ?? 0) + 1;

          generatePatternsRecursive(
            newPattern,
            remainingPlayers.sublist(1),
            newCounts,
          );
        }
      }
    }

    // 初期パターンを作成
    final initialPattern = <String, List<String>>{};
    for (final skill in skillsOrder) {
      initialPattern[skill] = [];
    }
    final initialCounts = <String, int>{};
    for (final skill in skillsOrder) {
      initialCounts[skill] = 0;
    }

    generatePatternsRecursive(initialPattern, playerIds, initialCounts);

    return patterns;
  }

  /// 3. patterns_v2の作成 - 空でないリストの個数が最も多いものを選ぶ
  static List<Map<String, List<String>>> createPatternsV2(
    List<Map<String, List<String>>> patternsV1,
  ) {
    if (patternsV1.isEmpty) return [];

    // 各パターンの空でないリストの個数を計算
    int maxNonEmpty = 0;
    for (final pattern in patternsV1) {
      final nonEmptyCount =
          pattern.values.where((list) => list.isNotEmpty).length;
      if (nonEmptyCount > maxNonEmpty) {
        maxNonEmpty = nonEmptyCount;
      }
    }

    // 最大個数のものを選択
    return patternsV1
        .where((pattern) =>
            pattern.values.where((list) => list.isNotEmpty).length ==
            maxNonEmpty)
        .toList();
  }

  /// 4. patterns_v3の作成 - 先頭から順に空か否かを確認
  static List<Map<String, List<String>>> createPatternsV3({
    required List<Map<String, List<String>>> patternsV2,
    required Map<String, int> fixedRequiredMap,
  }) {
    if (patternsV2.length <= 1) return patternsV2;

    final skillsOrder = fixedRequiredMap.keys.toList();
    var remaining = List<Map<String, List<String>>>.from(patternsV2);

    for (final skill in skillsOrder) {
      if (remaining.length <= 1) break;

      // このスキルが空でないパターンのみを残す
      final nonEmpty = remaining
          .where((pattern) => (pattern[skill] ?? []).isNotEmpty)
          .toList();

      if (nonEmpty.isNotEmpty) {
        remaining = nonEmpty;
      }
    }

    return remaining;
  }

  /// 5. patterns_v4の作成 - 不公平スコアの解消度が高い順に並べる
  static List<Map<String, List<String>>> createPatternsV4({
    required List<Map<String, List<String>>> patternsV3,
    required Map<String, int> sorryScores,
  }) {
    if (patternsV3.length <= 1) return patternsV3;

    // 各パターンの不公平スコア合計を計算
    final patternScores = <_PatternScore>[];
    for (final pattern in patternsV3) {
      int totalScore = 0;
      for (final personIds in pattern.values) {
        for (final personId in personIds) {
          totalScore += sorryScores[personId] ?? 0;
        }
      }
      patternScores.add(_PatternScore(pattern, totalScore));
    }

    // スコアの高い順にソート
    patternScores.sort((a, b) => b.score.compareTo(a.score));

    // 最高スコアのものだけを選択
    final maxScore = patternScores.first.score;
    return patternScores
        .where((ps) => ps.score == maxScore)
        .map((ps) => ps.pattern)
        .toList();
  }

  /// 6. patterns_v5の作成 - 先頭から順にリスト長さを比較
  static List<Map<String, List<String>>> createPatternsV5({
    required List<Map<String, List<String>>> patternsV4,
    required Map<String, int> fixedRequiredMap,
  }) {
    if (patternsV4.length <= 1) return patternsV4;

    final skillsOrder = fixedRequiredMap.keys.toList();
    var remaining = List<Map<String, List<String>>>.from(patternsV4);

    for (final skill in skillsOrder) {
      if (remaining.length <= 1) break;

      // このスキルのリスト長さの最大値を取得
      final maxLength = remaining
          .map((pattern) => (pattern[skill] ?? []).length)
          .reduce((a, b) => a > b ? a : b);

      // 最大長さのものだけを残す
      remaining = remaining
          .where((pattern) => (pattern[skill] ?? []).length == maxLength)
          .toList();
    }

    return remaining;
  }

  /// 7. result_mapの作成
  static Map<String, List<String>> createResultMap(
    List<Map<String, List<String>>> patternsV5,
  ) {
    if (patternsV5.isEmpty) return {};
    return patternsV5.first;
  }

  /// 不公平スコアの更新
  static Map<String, int> updateSorryScores({
    required Map<String, List<String>> players,
    required Map<String, List<String>> resultMap,
    required Map<String, int> sorryScores,
  }) {
    final newScores = Map<String, int>.from(sorryScores);

    // 選ばれた人のIDを収集
    final selectedIds = <String>{};
    for (final personIds in resultMap.values) {
      selectedIds.addAll(personIds);
    }

    // 不公平スコアが1以上で選ばれた人
    final consideredAndSelected = <String>{};
    for (final personId in selectedIds) {
      if ((newScores[personId] ?? 0) >= 1) {
        consideredAndSelected.add(personId);
      }
    }

    // スコア更新
    for (final personId in players.keys) {
      if (consideredAndSelected.contains(personId)) {
        // 考慮されて選ばれた → -1
        newScores[personId] = ((newScores[personId] ?? 0) - 1).clamp(-1, 9999);
      } else if (!selectedIds.contains(personId)) {
        // 選ばれなかった → +1
        newScores[personId] = (newScores[personId] ?? 0) + 1;
      }
    }

    return newScores;
  }

  /// fixed_required_mapを計算
  static Map<String, int> calculateFixedRequiredMap({
    required Map<String, int> requiredMap,
    required Map<String, String> constCustomer,
  }) {
    final fixedMap = Map<String, int>.from(requiredMap);

    // 固定スタッフの分を引く
    for (final skill in constCustomer.values) {
      if (fixedMap.containsKey(skill)) {
        fixedMap[skill] = fixedMap[skill]! - 1;
      }
    }

    // 人数の多い順にソート
    final sortedEntries = fixedMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// アルゴリズム全体を実行
  static ShiftAutoResult run({
    required Map<String, List<String>> peopleMap,
    required Map<String, String> wantsMap,
    required Map<String, int> requiredMap,
    required Map<String, String> constCustomer,
    required Map<String, int> sorryScores,
  }) {
    final startTime = DateTime.now();

    // fixed_required_mapを計算
    final fixedRequiredMap = calculateFixedRequiredMap(
      requiredMap: requiredMap,
      constCustomer: constCustomer,
    );

    // 1. playersの作成
    final players = createPlayers(
      peopleMap: peopleMap,
      wantsMap: wantsMap,
      fixedRequiredMap: fixedRequiredMap,
    );

    // 2. patterns_v1の作成
    final patternsV1 = createPatternsV1(
      players: players,
      fixedRequiredMap: fixedRequiredMap,
    );

    // 3. patterns_v2の作成
    final patternsV2 = createPatternsV2(patternsV1);

    // 4. patterns_v3の作成
    final patternsV3 = createPatternsV3(
      patternsV2: patternsV2,
      fixedRequiredMap: fixedRequiredMap,
    );

    // 5. patterns_v4の作成
    final patternsV4 = createPatternsV4(
      patternsV3: patternsV3,
      sorryScores: sorryScores,
    );

    // 6. patterns_v5の作成
    final patternsV5 = createPatternsV5(
      patternsV4: patternsV4,
      fixedRequiredMap: fixedRequiredMap,
    );

    // 7. result_mapの作成
    final resultMap = createResultMap(patternsV5);

    // 不公平スコア更新
    final newSorryScores = updateSorryScores(
      players: players,
      resultMap: resultMap,
      sorryScores: sorryScores,
    );

    // 不公平スコアを出力
    print('不公平スコア: $newSorryScores');

    final elapsedTime = DateTime.now().difference(startTime);

    return ShiftAutoResult(
      resultMap: resultMap,
      newSorryScores: newSorryScores,
      players: players,
      patternsV1Count: patternsV1.length,
      patternsV2Count: patternsV2.length,
      patternsV3Count: patternsV3.length,
      patternsV4Count: patternsV4.length,
      patternsV5Count: patternsV5.length,
      elapsedTime: elapsedTime,
    );
  }
}

/// パターンとスコアのペア
class _PatternScore {
  final Map<String, List<String>> pattern;
  final int score;

  _PatternScore(this.pattern, this.score);
}

/// アルゴリズム実行結果
class ShiftAutoResult {
  final Map<String, List<String>> resultMap;
  final Map<String, int> newSorryScores;
  final Map<String, List<String>> players;
  final int patternsV1Count;
  final int patternsV2Count;
  final int patternsV3Count;
  final int patternsV4Count;
  final int patternsV5Count;
  final Duration elapsedTime;

  ShiftAutoResult({
    required this.resultMap,
    required this.newSorryScores,
    required this.players,
    required this.patternsV1Count,
    required this.patternsV2Count,
    required this.patternsV3Count,
    required this.patternsV4Count,
    required this.patternsV5Count,
    required this.elapsedTime,
  });
}