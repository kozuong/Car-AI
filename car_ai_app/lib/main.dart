import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final langCode = prefs.getString('language') ?? 'vi';
  runApp(MyApp(langCode: langCode));
}

class MyApp extends StatelessWidget {
  final String langCode;
  const MyApp({super.key, required this.langCode});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car AI Analyzer',
      theme: AppTheme.lightTheme,
      home: HomePage(langCode: langCode),
      debugShowCheckedModeBanner: false,
    );
  }
}
