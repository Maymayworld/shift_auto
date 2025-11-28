// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../models/shift_data.dart';

// class StorageService {
//   static const String _keyShiftData = 'shift_data';

//   /// ShiftDataを保存
//   static Future<void> saveShiftData(ShiftData data) async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = jsonEncode(data.toJson());
//     await prefs.setString(_keyShiftData, jsonString);
//   }

//   /// ShiftDataを読み込み
//   static Future<ShiftData?> loadShiftData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final jsonString = prefs.getString(_keyShiftData);

//     if (jsonString == null) return null;

//     try {
//       final json = jsonDecode(jsonString) as Map<String, dynamic>;
//       return ShiftData.fromJson(json);
//     } catch (e) {
//       print('データ読み込みエラー: $e');
//       return null;
//     }
//   }

//   /// データをクリア
//   static Future<void> clearData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_keyShiftData);
//   }
// }