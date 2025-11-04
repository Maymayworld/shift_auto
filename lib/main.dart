// main.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/main_layout.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftAuto',
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        useMaterial3: true,
      ),
      home: const MainLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}