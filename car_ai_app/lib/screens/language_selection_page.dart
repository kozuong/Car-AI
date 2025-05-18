import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'home_page.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Language'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _selectLanguage(context, 'vi'),
              child: const Text('Tiếng Việt'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _selectLanguage(context, 'en'),
              child: const Text('English'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    final storage = StorageService();
    await storage.saveLanguage(langCode);
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage(langCode: langCode)),
      (route) => false,
    );
  }
} 