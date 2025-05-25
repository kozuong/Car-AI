import 'package:flutter/material.dart';
import '../models/car_brand.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';
import 'car_detail_page.dart';
import 'dart:io';
import '../widgets/page_title.dart';
import '../widgets/car_card.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';

class BrandCollectionPage extends StatefulWidget {
  final String langCode;
  const BrandCollectionPage({super.key, required this.langCode});

  @override
  State<BrandCollectionPage> createState() => _BrandCollectionPageState();
}

class _BrandCollectionPageState extends State<BrandCollectionPage> {
  List<String> brandNames = [];
  bool isLoading = true;
  final _storageService = StorageService();

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
    if (!mounted) return;
    setState(() => isLoading = true);
    final brands = await _storageService.getAllBrandCollections();
    if (mounted) {
      setState(() {
        brandNames = brands;
        isLoading = false;
      });
    }
  }

  void _openBrandCollection(String brand) async {
    final cars = await _storageService.getCollection(brand);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _BrandCarsPage(
          brand: brand,
          cars: cars,
          langCode: widget.langCode,
          onCollectionDeleted: () {
            _loadBrands(); // Reload when collection is deleted
          },
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
          child: PageTitle(AppConstants.messages[widget.langCode]!['collectionTitle'] ?? 'Car Brands'),
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
                        return FutureBuilder<List<CarModel>>(
                          future: _storageService.getCollection(brand),
                          builder: (context, snapshot) {
                            String logoUrl = '';
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              logoUrl = snapshot.data!.first.logoUrl;
                            }
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
                                    if (logoUrl.isNotEmpty)
                                      buildLogo(logoUrl)
                                    else
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
  final VoidCallback onCollectionDeleted;
  
  const _BrandCarsPage({
    required this.brand, 
    required this.cars, 
    required this.langCode,
    required this.onCollectionDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    return Scaffold(
      appBar: AppBar(title: Text(brand)),
      body: cars.isEmpty
          ? Center(child: Text(isVi ? 'Chưa có xe nào.' : 'No cars yet.'))
          : _BrandCarsList(
              brand: brand, 
              cars: cars, 
              langCode: langCode,
              onCollectionDeleted: onCollectionDeleted,
            ),
    );
  }
}

class _BrandCarsList extends StatefulWidget {
  final String brand;
  final List<CarModel> cars;
  final String langCode;
  final VoidCallback onCollectionDeleted;
  
  const _BrandCarsList({
    required this.brand, 
    required this.cars, 
    required this.langCode,
    required this.onCollectionDeleted,
  });

  @override
  State<_BrandCarsList> createState() => _BrandCarsListState();
}

class _BrandCarsListState extends State<_BrandCarsList> {
  late List<CarModel> cars;

  @override
  void initState() {
    super.initState();
    cars = List<CarModel>.from(widget.cars);
  }

  @override
  Widget build(BuildContext context) {
    return cars.isEmpty
        ? Center(child: Text(widget.langCode == 'vi' ? 'Chưa có xe nào.' : 'No cars yet.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            itemBuilder: (context, index) {
              final car = cars[index];
              return CarCard(
                car: car,
                langCode: widget.langCode,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CarDetailPage(car: car, langCode: widget.langCode),
                    ),
                  );
                },
                onDelete: () async {
                  await StorageService().removeFromCollection(car, widget.brand);
                  setState(() {
                    cars.removeAt(index);
                  });
                  if (cars.isEmpty) {
                    await StorageService().removeCollection(widget.brand);
                    if (mounted) {
                      Navigator.pop(context);
                      widget.onCollectionDeleted(); // Call the callback to reload parent
                    }
                  }
                },
              );
            },
          );
  }
}

Widget buildLogo(String logoUrl, {double width = 48, double height = 48}) {
  if (logoUrl.startsWith('data:image/')) {
    try {
      final base64Str = logoUrl.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
      );
    } catch (e) {
      return Icon(Icons.error);
    }
  } else {
    return Image.network(
      logoUrl,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
    );
  }
} 