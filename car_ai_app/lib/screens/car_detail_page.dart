import 'dart:io';
import 'package:flutter/material.dart';
import '../models/car_model.dart';

class CarDetailPage extends StatelessWidget {
  final CarModel car;
  final String langCode;

  const CarDetailPage({
    super.key,
    required this.car,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);

    // Tách mô tả tổng quan, loại bỏ động cơ và nội thất nếu có
    String overview = isVi ? (car.descriptionVi.isNotEmpty ? car.descriptionVi : car.description) : (car.descriptionEn.isNotEmpty ? car.descriptionEn : car.description);
    final engine = isVi ? (car.engineDetailVi.isNotEmpty ? car.engineDetailVi : car.engine) : (car.engineDetailEn.isNotEmpty ? car.engineDetailEn : car.engine);
    final interior = isVi ? (car.interiorVi.isNotEmpty ? car.interiorVi : car.interior) : (car.interiorEn.isNotEmpty ? car.interiorEn : car.interior);
    final engineIndex = overview.toLowerCase().indexOf('chi tiết động cơ');
    final engineIndexEn = overview.toLowerCase().indexOf('engine details');
    final interiorIndex = overview.toLowerCase().indexOf('nội thất');
    final interiorIndexEn = overview.toLowerCase().indexOf('interior & features');
    int cutIndex = overview.length;
    if (engineIndex != -1) cutIndex = engineIndex;
    if (engineIndexEn != -1 && engineIndexEn < cutIndex) cutIndex = engineIndexEn;
    if (interiorIndex != -1 && interiorIndex < cutIndex) cutIndex = interiorIndex;
    if (interiorIndexEn != -1 && interiorIndexEn < cutIndex) cutIndex = interiorIndexEn;
    overview = overview.substring(0, cutIndex).trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Car Image + Back button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Image.file(
                    File(car.imagePath),
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 240,
                      color: Colors.grey[200],
                      child: const Icon(Icons.directions_car, size: 120, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand tag
                    if (car.brand.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          car.brand,
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    Text(
                      car.carName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
                    ),
                    const SizedBox(height: 8),
                    // Main stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _StatBox(
                          value: car.power,
                          label: isVi ? 'Công suất' : 'Power',
                          unit: 'hp',
                          color: Colors.blue,
                        ),
                        ),
                        Flexible(
                          child: _StatBox(
                          value: car.acceleration,
                          label: isVi ? 'Tăng tốc 0-100' : '0-100 km/h',
                          unit: 's',
                          color: Colors.green,
                        ),
                        ),
                        Flexible(
                          child: _StatBox(
                          value: car.topSpeed,
                          label: isVi ? 'Tốc độ tối đa' : 'Top speed',
                          unit: 'km/h',
                          color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Info table
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVi ? 'Năm' : 'Year',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  car.year.isNotEmpty ? car.year : '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.grey.shade200,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isVi ? 'Giá' : 'Price',
                                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  car.price.isNotEmpty ? car.price : '-',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Description Card (overview only)
                    _SectionCard(
                      icon: Icons.description,
                      title: isVi ? 'Mô tả' : 'Description',
                      child: Text(
                        overview.isNotEmpty ? overview : (isVi ? 'Không có mô tả.' : 'No description.'),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Engine Card (always show if has data)
                    if (engine.isNotEmpty)
                      _SectionCard(
                        icon: Icons.engineering,
                        title: isVi ? 'Chi tiết động cơ' : 'Engine Details',
                        child: Text(
                          engine,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    if (engine.isNotEmpty)
                      const SizedBox(height: 14),
                    // Interior Card (always show if has data)
                    if (interior.isNotEmpty)
                      _SectionCard(
                        icon: Icons.chair_alt,
                        title: isVi ? 'Nội thất & Tính năng' : 'Interior & Features',
                        child: Text(
                          interior,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value, label, unit;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.isNotEmpty ? value : '-',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          unit,
          style: TextStyle(fontSize: 13, color: color.withOpacity(0.7)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: const Color(0xFF2196F3), size: 28),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
} 