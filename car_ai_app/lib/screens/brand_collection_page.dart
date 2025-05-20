import 'package:flutter/material.dart';
import '../models/car_brand.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';
import 'car_detail_page.dart';
import 'dart:io';

class BrandCollectionPage extends StatefulWidget {
  final String langCode;
  const BrandCollectionPage({super.key, required this.langCode});

  @override
  State<BrandCollectionPage> createState() => _BrandCollectionPageState();
}

class _BrandCollectionPageState extends State<BrandCollectionPage> {
  List<String> brandNames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrands();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() => isLoading = true);
    final brands = await StorageService().getAllBrandCollections();
    setState(() {
      brandNames = brands;
      isLoading = false;
    });
  }

  void _openBrandCollection(String brand) async {
    final cars = await StorageService().getCollection(brand);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BrandCarsPage(
          brand: brand,
          cars: cars,
          langCode: widget.langCode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            AppConstants.messages[widget.langCode]!['collectionTitle'] ?? 'Car Brands',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : brandNames.isEmpty
                  ? Center(child: Text('Chưa có bộ sưu tập xe.'))
                  : GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
                        childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
                      itemCount: brandNames.length,
            itemBuilder: (context, index) {
                        final brand = brandNames[index];
              return Card(
                          elevation: 4,
                shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                ),
                child: InkWell(
                            onTap: () => _openBrandCollection(brand),
                            borderRadius: BorderRadius.circular(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                                Icon(Icons.directions_car, size: 48, color: Colors.blue[400]),
                                const SizedBox(height: 16),
                      Text(
                                  brand,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                                    fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrandCarsPage extends StatelessWidget {
  final String brand;
  final List<CarModel> cars;
  final String langCode;
  const _BrandCarsPage({required this.brand, required this.cars, required this.langCode});

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    return Scaffold(
      appBar: AppBar(title: Text(brand)),
      body: cars.isEmpty
          ? Center(child: Text(isVi ? 'Chưa có xe nào.' : 'No cars yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: car.imagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(car.imagePath),
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                            ),
                          )
                        : const Icon(Icons.directions_car, size: 40, color: Colors.grey),
                    title: Text(car.carName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(car.year),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CarDetailPage(car: car, langCode: langCode),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
} 