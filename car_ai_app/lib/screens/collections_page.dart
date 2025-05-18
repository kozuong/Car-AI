import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import '../services/api_service.dart';

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

  Future<void> _loadCollection() async {
    setState(() => isLoading = true);
    try {
      favorites = await ApiService().fetchCollection('Favorites');
    } catch (e) {
      favorites = [];
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.star, color: Colors.amber),
                        title: Text(car.carName),
                        subtitle: Text(car.brand),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Show car details
                        },
                      ),
                    );
                  },
                ),
    );
  }
} 