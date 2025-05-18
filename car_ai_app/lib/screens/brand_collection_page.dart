import 'package:flutter/material.dart';
import '../models/car_brand.dart';
import '../config/theme.dart';
import '../config/constants.dart';

class BrandCollectionPage extends StatefulWidget {
  final String langCode;
  const BrandCollectionPage({super.key, required this.langCode});

  @override
  State<BrandCollectionPage> createState() => _BrandCollectionPageState();
}

class _BrandCollectionPageState extends State<BrandCollectionPage> {
  final List<CarBrand> carBrands = [
    CarBrand(name: 'Toyota', logoUrl: 'assets/images/brands/toyota.png'),
    CarBrand(name: 'Honda', logoUrl: 'assets/images/brands/honda.png'),
    CarBrand(name: 'BMW', logoUrl: 'assets/images/brands/bmw.png'),
    CarBrand(name: 'Mercedes', logoUrl: 'assets/images/brands/mercedes.png'),
    CarBrand(name: 'Audi', logoUrl: 'assets/images/brands/audi.png'),
  ];

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
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: carBrands.length,
            itemBuilder: (context, index) {
              final brand = carBrands[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // Handle brand selection
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        brand.logoUrl,
                        height: 80,
                        width: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.directions_car, size: 80);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        brand.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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