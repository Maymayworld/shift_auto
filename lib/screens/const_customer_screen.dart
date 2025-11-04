// // screens/const_customer_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../providers/shift_provider.dart';
// import '../theme/app_theme.dart';

// class ConstCustomerScreen extends HookConsumerWidget {
//   const ConstCustomerScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final shiftData = ref.watch(shiftDataProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('固定スタッフ設定'),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: shiftData.people.length,
//         itemBuilder: (context, index) {
//           final person = shiftData.people[index];
//           final constSkill = shiftData.constCustomer[person.id];
//           final isConst = constSkill != null;

//           return Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             decoration: BoxDecoration(
//               color: isConst ? Colors.orange[50] : backgroundColor,
//               border: Border.all(color: borderColor),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: ListTile(
//               title: Text(person.name),
//               subtitle: Text(
//                 isConst ? '固定: $constSkill' : '固定なし',
//                 style: TextStyle(
//                   color: isConst ? Colors.orange[700] : Colors.grey,
//                 ),
//               ),
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (isConst)
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.red),
//                       onPressed: () {
//                         ref.read(shiftDataProvider.notifier).removeConstCustomer(person.id);
//                       },
//                       tooltip: '固定を解除',
//                     ),
//                   IconButton(
//                     icon: Icon(
//                       isConst ? Icons.edit : Icons.add,
//                       color: primaryColor,
//                     ),
//                     onPressed: () {
//                       _showConstDialog(context, ref, person.id, person.name, person.skills);
//                     },
//                     tooltip: isConst ? '固定を編集' : '固定を設定',
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _showConstDialog(
//     BuildContext context,
//     WidgetRef ref,
//     String personId,
//     String personName,
//     List<String> personSkills,
//   ) {
//     final shiftData = ref.read(shiftDataProvider);
//     final currentConst = shiftData.constCustomer[personId];

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('$personNameの固定配置'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (personSkills.isEmpty)
//               const Padding(
//                 padding: EdgeInsets.all(16),
//                 child: Text('このスタッフはスキルを持っていません'),
//               )
//             else
//               ...personSkills.map((skill) {
//                 return ListTile(
//                   title: Text(skill),
//                   leading: Radio<String>(
//                     value: skill,
//                     groupValue: currentConst,
//                     onChanged: (value) {
//                       if (value != null) {
//                         ref.read(shiftDataProvider.notifier).setConstCustomer(personId, value);
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 );
//               }),
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