import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/car_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final String langCode;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  const CarCard({super.key, required this.car, required this.langCode, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (car.imagePath.isNotEmpty)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: Image.file(
                          File(car.imagePath),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (car.logoUrl.isNotEmpty)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: ClipOval(
                              child: buildLogo(car.logoUrl),
                            ),
                          ),
                        ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (car.logoUrl.isNotEmpty)
                              Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(3),
                                child: ClipOval(
                                  child: buildLogo(car.logoUrl, width: 18, height: 18),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                car.getLocalizedText('carName', langCode),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Main stats
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isVi ? 'Công suất' : 'Power', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(CarModel.getAverageValue(car.getLocalizedText('power', langCode)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(isVi ? 'Tăng tốc 0-100' : '0-100 km/h', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(car.getLocalizedText('acceleration', langCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(isVi ? 'Tốc độ tối đa' : 'Top speed', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(CarModel.getAverageValue(car.getLocalizedText('topSpeed', langCode)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Info table (year, price, number produced, rarity)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isVi ? 'Năm' : 'Year', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(car.getLocalizedText('year', langCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(isVi ? 'Giá' : 'Price', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(displayPrice(car.getLocalizedText('price', langCode), langCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.right, maxLines: 2, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isVi ? 'Số lượng sản xuất' : 'Number produced', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  Text(car.getLocalizedText('numberProduced', langCode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 32, color: Colors.grey.shade100, margin: const EdgeInsets.symmetric(horizontal: 10)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(isVi ? 'Độ hiếm' : 'Rarity', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 4),
                                  _buildStarRating(car.getLocalizedText('rarity', langCode)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: onDelete,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close, size: 20, color: Colors.black54),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

  String displayPrice(String price, String langCode) {
    if (price.trim().isEmpty || price.trim().toLowerCase() == 'n/a') {
      return langCode == 'vi' ? 'Đang cập nhật' : '-';
    }
    return price;
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