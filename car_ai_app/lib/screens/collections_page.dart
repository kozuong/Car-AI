import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../widgets/car_card.dart';
import '../services/storage_service.dart';
import 'car_detail_page.dart';

class CollectionsPage extends StatefulWidget {
  final String langCode;
  const CollectionsPage({super.key, required this.langCode});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  List<CarModel> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  Future<CarModel> translateCollectionRecord(CarModel car, String lang) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.87:8000/translate_history'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'record': car.toJson(),
        'lang': lang,
      }),
    );
    if (response.statusCode == 200) {
      return CarModel.fromJson(jsonDecode(response.body));
    } else {
      return car;
    }
  }

  Future<void> _loadCollection() async {
    setState(() => isLoading = true);
    try {
      favorites = await StorageService().getCollection('Favorites');
    } catch (e) {
      favorites = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void didUpdateWidget(CollectionsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.langCode != widget.langCode) {
      setState(() {}); // Chỉ cần rebuild UI, không cần load lại data
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Bộ sưu tập' : 'Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCollection,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favorites.isEmpty
              ? Center(child: Text(isVi ? 'Chưa có xe yêu thích.' : 'No favorites yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final car = favorites[index];
                    return CarCard(
                      car: car,
                      langCode: widget.langCode,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CarDetailPage(
                              car: car,
                              langCode: widget.langCode,
                            ),
                          ),
                        );
                      },
                      onDelete: () async {
                        await StorageService().removeFromCollection(car, 'Favorites');
                        setState(() {
                          favorites.removeAt(index);
                        });
                        if (favorites.isEmpty) {
                          await StorageService().removeCollection('Favorites');
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                    );
                  },
                ),
    );
  }

  Widget _buildStarRating(String? rarity) {
    int filled = 1;
    if (rarity != null && rarity.isNotEmpty) {
      filled = rarity.replaceAll(RegExp(r'[^★]'), '').length;
      if (filled < 1) filled = 1;
      if (filled > 5) filled = 5;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < filled ? Icons.star : Icons.star_border,
          color: index < filled ? Colors.amber : Colors.grey[300],
          size: 18,
        );
      }),
    );
  }
} 