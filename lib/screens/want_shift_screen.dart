// // screens/want_shift_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../providers/shift_provider.dart';
// import '../theme/app_theme.dart';

// class WantShiftScreen extends HookConsumerWidget {
//   const WantShiftScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final shiftData = ref.watch(shiftDataProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('希望シフト入力'),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: shiftData.people.length,
//         itemBuilder: (context, index) {
//           final person = shiftData.people[index];
//           final currentWant = shiftData.wantsMap[person.id];
//           final constSkill = shiftData.constCustomer[person.id];
//           final isConst = constSkill != null;
//           final hasWant = currentWant != null || isConst;
//           final displayWant = isConst ? constSkill : currentWant;

//           return Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             decoration: BoxDecoration(
//               color: isConst 
//                   ? Colors.orange[50] 
//                   : (hasWant ? Colors.blue[50] : backgroundColor),
//               border: Border.all(color: borderColor),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ListTile(
//               title: Text(person.name),
//               subtitle: Text(
//                 isConst
//                     ? '固定配置: $displayWant'
//                     : (hasWant ? '希望: $displayWant' : '希望なし'),
//                 style: TextStyle(
//                   color: isConst
//                       ? Colors.orange[700]
//                       : (hasWant ? Colors.blue[700] : Colors.grey),
//                   fontWeight: isConst ? FontWeight.bold : FontWeight.normal,
//                 ),
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (hasWant && !isConst)
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.red),
//                       onPressed: () {
//                         ref.read(shiftDataProvider.notifier).removeWant(person.id);
//                       },
//                       tooltip: '希望を削除',
//                     ),
//                   if (!isConst)
//                     IconButton(
//                       icon: Icon(
//                         hasWant ? Icons.edit : Icons.add,
//                         color: primaryColor,
//                       ),
//                       onPressed: () {
//                         _showWantDialog(context, ref, person.id, person.name, person.skills);
//                       },
//                       tooltip: hasWant ? '希望を編集' : '希望を追加',
//                     ),
//                   if (isConst)
//                     Tooltip(
//                       message: '固定スタッフとして設定されています',
//                       child: Icon(
//                         Icons.push_pin,
//                         color: Colors.orange[700],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _showWantDialog(
//     BuildContext context,
//     WidgetRef ref,
//     String personId,
//     String personName,
//     List<String> personSkills,
//   ) {
//     final shiftData = ref.read(shiftDataProvider);
//     final currentWant = shiftData.wantsMap[personId];

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('$personNameの希望シフト'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // スキル指定なし
//             ListTile(
//               title: const Text('スキル指定なし (どのスキルでもOK)'),
//               leading: Radio<String>(
//                 value: 'SA',
//                 groupValue: currentWant,
//                 onChanged: (value) {
//                   if (value != null) {
//                     ref.read(shiftDataProvider.notifier).setWant(personId, value);
//                     Navigator.pop(context);
//                   }
//                 },
//               ),
//             ),
//             const Divider(),
//             // 各スキル
//             ...personSkills.map((skill) {
//               return ListTile(
//                 title: Text(skill),
//                 leading: Radio<String>(
//                   value: skill,
//                   groupValue: currentWant,
//                   onChanged: (value) {
//                     if (value != null) {
//                       ref.read(shiftDataProvider.notifier).setWant(personId, value);
//                       Navigator.pop(context);
//                     }
//                   },
//                 ),
//               );
//             }),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('キャンセル'),
//           ),
//         ],
//       ),
//     );
//   }
// }