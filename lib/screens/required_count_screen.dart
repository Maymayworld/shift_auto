// // screens/required_count_screen.dart
// import 'package:flutter/material.dart';
// import 'package:hooks_riverpod/hooks_riverpod.dart';
// import '../providers/shift_provider.dart';
// import '../theme/app_theme.dart';

// class RequiredCountScreen extends HookConsumerWidget {
//   const RequiredCountScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final shiftData = ref.watch(shiftDataProvider);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('必要人数設定'),
//         backgroundColor: primaryColor,
//         foregroundColor: Colors.white,
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.all(16),
//         itemCount: shiftData.skills.length,
//         itemBuilder: (context, index) {
//           final skill = shiftData.skills[index];
//           final currentCount = shiftData.requiredMap[skill] ?? 0;

//           return Container(
//             margin: const EdgeInsets.only(bottom: 12),
//             decoration: BoxDecoration(
//               color: backgroundColor,
//               border: Border.all(color: borderColor),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       skill,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.remove_circle_outline),
//                     onPressed: currentCount > 0
//                         ? () {
//                             ref
//                                 .read(shiftDataProvider.notifier)
//                                 .setRequired(skill, currentCount - 1);
//                           }
//                         : null,
//                   ),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[50],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       '$currentCount人',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: primaryColor,
//                       ),
//                     ),
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.add_circle_outline),
//                     onPressed: () {
//                       ref
//                           .read(shiftDataProvider.notifier)
//                           .setRequired(skill, currentCount + 1);
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }