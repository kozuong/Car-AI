import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'config/constants.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Car AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: HomePage(langCode: AppConstants.defaultLanguage), // Default to AppConstants.defaultLanguage
    );
  }
}

void main() {
  runApp(const MyApp());
}
