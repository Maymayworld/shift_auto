// // screens/home.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../providers/shift_provider.dart';
// import '../services/shift_auto_algorithm.dart';
// import '../theme/app_theme.dart';
// import 'people_management_screen.dart';
// import 'skill_management_screen.dart';
// import 'want_shift_screen.dart';
// import 'required_count_screen.dart';
// import 'const_customer_screen.dart';

// class HomePage extends HookConsumerWidget {
//   const HomePage({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final shiftData = ref.watch(shiftDataProvider);
//     final shiftResult = ref.watch(shiftResultProvider);
//     final isLoading = useState(false);

//     Future<void> runAlgorithm() async {
//       isLoading.value = true;

//       // peopleMapを作成
//       final peopleMap = <String, List<String>>{};
//       for (final person in shiftData.people) {
//         peopleMap[person.id] = person.skills;
//       }

//       // wantsMapから固定カスタマーを除外
//       // 固定カスタマーは既に配置確定なので、アルゴリズムで配置を考える必要がない
//       final filteredWantsMap = Map<String, String>.from(shiftData.wantsMap);
//       for (final personId in shiftData.constCustomer.keys) {
//         filteredWantsMap.remove(personId);
//       }

//       // アルゴリズム実行
//       final result = ShiftAutoAlgorithm.run(
//         peopleMap: peopleMap,
//         wantsMap: filteredWantsMap, // 固定カスタマーを除外したwantsMapを使用
//         requiredMap: shiftData.requiredMap,
//         constCustomer: shiftData.constCustomer,
//         sorryScores: shiftData.sorryScores,
//       );

//       // 結果を保存
//       ref.read(shiftResultProvider.notifier).state = result;

//       // 不公平スコアを更新
//       ref.read(shiftDataProvider.notifier).updateSorryScores(result.newSorryScores);

//       isLoading.value = false;
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('シフトオート'),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               ref.read(shiftDataProvider.notifier).reset();
//               ref.read(shiftResultProvider.notifier).state = null;
//             },
//             tooltip: 'データをリセット',
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // 管理メニュー
//             _buildCard(
//               title: '管理メニュー',
//               child: Column(
//                 children: [
//                   _buildMenuButton(
//                     context,
//                     icon: Icons.people,
//                     label: 'カスタマー管理',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const PeopleManagementScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _buildMenuButton(
//                     context,
//                     icon: Icons.category,
//                     label: 'スキル管理',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const SkillManagementScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _buildMenuButton(
//                     context,
//                     icon: Icons.edit_calendar,
//                     label: '希望シフト入力',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const WantShiftScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _buildMenuButton(
//                     context,
//                     icon: Icons.format_list_numbered,
//                     label: '必要人数設定',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const RequiredCountScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 8),
//                   _buildMenuButton(
//                     context,
//                     icon: Icons.push_pin,
//                     label: '固定カスタマー設定',
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const ConstCustomerScreen(),
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // カスタマー一覧
//             _buildCard(
//               title: 'カスタマー',
//               child: Column(
//                 children: [
//                   if (shiftData.people.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Text('カスタマーがいません'),
//                     )
//                   else
//                     ...shiftData.people.map((person) => ListTile(
//                           title: Text(person.name),
//                           subtitle: Text(
//                             'スキル: ${person.skills.join(', ')}',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                           trailing: Text(
//                             '不公平スコア: ${shiftData.sorryScores[person.id] ?? 0}',
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                         )),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // 希望シフト
//             _buildCard(
//               title: '希望シフト',
//               child: Column(
//                 children: [
//                   if (shiftData.wantsMap.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Text('希望シフトがありません'),
//                     )
//                   else
//                     ...shiftData.wantsMap.entries.map((entry) {
//                       // 削除されたカスタマーの希望は表示しない
//                       try {
//                         final person =
//                             shiftData.people.firstWhere((p) => p.id == entry.key);
//                         return ListTile(
//                           title: Text(person.name),
//                           trailing: Text(entry.value),
//                         );
//                       } catch (e) {
//                         return const SizedBox.shrink();
//                       }
//                     }),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // 必要人数
//             _buildCard(
//               title: '必要人数',
//               child: Column(
//                 children: [
//                   if (shiftData.requiredMap.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Text('必要人数が設定されていません'),
//                     )
//                   else
//                     ...shiftData.requiredMap.entries.map((entry) => ListTile(
//                           title: Text(entry.key),
//                           trailing: Text('${entry.value}人'),
//                         )),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // 固定カスタマー
//             if (shiftData.constCustomer.isNotEmpty)
//               _buildCard(
//                 title: '固定カスタマー',
//                 child: Column(
//                   children: [
//                     ...shiftData.constCustomer.entries.map((entry) {
//                       // 削除されたカスタマーは表示しない
//                       try {
//                         final person = shiftData.people
//                             .firstWhere((p) => p.id == entry.key);
//                         return ListTile(
//                           title: Text(person.name),
//                           trailing: Text(entry.value),
//                         );
//                       } catch (e) {
//                         return const SizedBox.shrink();
//                       }
//                     }),
//                   ],
//                 ),
//               ),
//             const SizedBox(height: 24),

//             // 実行ボタン
//             ElevatedButton(
//               onPressed: isLoading.value ? null : runAlgorithm,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: isLoading.value
//                   ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : const Text(
//                       'シフトを自動生成',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//             ),
//             const SizedBox(height: 24),

//             // 結果表示
//             if (shiftResult != null) ...[
//               _buildCard(
//                 title: '生成結果',
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     ...() {
//                       // resultMapと固定カスタマーをマージ
//                       final mergedMap = <String, List<String>>{};
                      
//                       // resultMapをコピー
//                       for (final entry in shiftResult.resultMap.entries) {
//                         mergedMap[entry.key] = List.from(entry.value);
//                       }
                      
//                       // 固定カスタマーを追加
//                       for (final entry in shiftData.constCustomer.entries) {
//                         final personId = entry.key;
//                         final skill = entry.value;
//                         if (!mergedMap.containsKey(skill)) {
//                           mergedMap[skill] = [];
//                         }
//                         if (!mergedMap[skill]!.contains(personId)) {
//                           mergedMap[skill]!.add(personId);
//                         }
//                       }
                      
//                       // 必要人数が0でないものだけ表示
//                       return mergedMap.entries
//                           .where((entry) => (shiftData.requiredMap[entry.key] ?? 0) > 0)
//                           .map((entry) {
//                         final skill = entry.key;
//                         final personIds = entry.value;
//                         final names = personIds.map((id) {
//                           try {
//                             final person =
//                                 shiftData.people.firstWhere((p) => p.id == id);
//                             final isConst = shiftData.constCustomer[id] == skill;
//                             return isConst ? '${person.name}[固定]' : person.name;
//                           } catch (e) {
//                             return '（削除済み）';
//                           }
//                         }).join(', ');

//                         return Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 skill,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 names.isEmpty ? '（配置なし）' : names,
//                                 style: const TextStyle(fontSize: 14),
//                               ),
//                             ],
//                           ),
//                         );
//                       });
//                     }(),
//                     const Divider(height: 24),
//                     Text(
//                       '処理時間: ${shiftResult.elapsedTime.inMilliseconds}ms',
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                     Text(
//                       'パターン数: ${shiftResult.patternsV1Count} → ${shiftResult.patternsV5Count}',
//                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuButton(
//     BuildContext context, {
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.blue[50],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: primaryColor.withOpacity(0.3)),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: primaryColor),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: primaryColor,
//                 ),
//               ),
//             ),
//             Icon(Icons.chevron_right, color: primaryColor),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard({required String title, required Widget child}) {
//     return Card(
//       color: cardColor,
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 8),
//             child,
//           ],
//         ),
//       ),
//     );
//   }
// }