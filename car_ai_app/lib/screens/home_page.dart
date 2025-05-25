import 'package:flutter/material.dart';
import 'camera_page.dart';
import 'brand_collection_page.dart';
import 'history_page.dart';
import '../config/constants.dart';

class HomePage extends StatefulWidget {
  final String langCode;
  const HomePage({super.key, required this.langCode});

  static void switchToHistory(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    if (state != null) {
      state._onItemTapped(2);
    }
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _currentLang;
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentLang = widget.langCode;
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      CameraPage(langCode: _currentLang),
      BrandCollectionPage(langCode: _currentLang),
      HistoryPage(langCode: _currentLang),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 1) {
        // Reload brand collection when switching to collection tab by giving a new key
        _pages[1] = BrandCollectionPage(key: ValueKey(DateTime.now().millisecondsSinceEpoch), langCode: _currentLang);
      }
      if (index == 2) {
        _pages[2] = HistoryPage(key: ValueKey(DateTime.now().millisecondsSinceEpoch), langCode: _currentLang);
      }
    });
  }

  void _toggleLanguage() {
    setState(() {
      _currentLang = _currentLang == 'vi' ? 'en' : 'vi';
      // Tạo lại các trang với key mới để đảm bảo load lại dữ liệu
      _pages = [
        CameraPage(key: ValueKey('camera_${_currentLang}_${DateTime.now().millisecondsSinceEpoch}'), langCode: _currentLang),
        BrandCollectionPage(key: ValueKey('collection_${_currentLang}_${DateTime.now().millisecondsSinceEpoch}'), langCode: _currentLang),
        HistoryPage(key: ValueKey('history_${_currentLang}_${DateTime.now().millisecondsSinceEpoch}'), langCode: _currentLang),
      ];
    });
  }

  void _openCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraPage(langCode: _currentLang)),
    ).then((_) {
      // Refresh history when returning from camera
      if (_selectedIndex == 2) {
        setState(() {
          _pages[2] = HistoryPage(key: ValueKey(DateTime.now().millisecondsSinceEpoch), langCode: _currentLang);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: Text(
          AppConstants.messages[_currentLang]!['appName']!,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _onItemTapped(2),
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _toggleLanguage,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: AppConstants.messages[_currentLang]!['camera']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.collections),
            label: AppConstants.messages[_currentLang]!['collection']!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppConstants.messages[_currentLang]!['history']!,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF2196F3),
        onTap: _onItemTapped,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: const Color(0xFF2196F3), size: 32),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 