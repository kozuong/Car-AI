import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ResultPage extends StatelessWidget {
  final String imagePath;
  final String carName;
  final String brand;
  final String year;
  final String price;
  final String power;
  final String acceleration;
  final String topSpeed;
  final String? description;
  final List<String>? features;
  final String? engineDetail;
  final String? interior;
  final String pageTitle;
  final Map<String, String> labels;

  const ResultPage({
    super.key,
    required this.imagePath,
    required this.carName,
    required this.brand,
    required this.year,
    required this.price,
    required this.power,
    required this.acceleration,
    required this.topSpeed,
    this.description,
    this.features,
    this.engineDetail,
    this.interior,
    required this.pageTitle,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final desc = description ?? '';
    final engine = engineDetail ?? '';
    final interiorText = interior ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              child: Image.file(
                File(imagePath),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car name and brand (căn trái tuyệt đối)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (brand.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              brand,
                              style: const TextStyle(
                                color: Color(0xFF2196F3),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        Text(
                          carName,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Main stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          value: power,
                          label: isVi ? 'Công suất' : 'Power',
                          unit: 'hp',
                          color: Colors.blue,
                          align: TextAlign.left,
                        ),
                      ),
                      Expanded(
                        child: _StatBox(
                          value: acceleration,
                          label: isVi ? 'Tăng tốc 0-100' : '0-100 km/h',
                          unit: 's',
                          color: Colors.green,
                          align: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: _StatBox(
                          value: topSpeed,
                          label: isVi ? 'Tốc độ tối đa' : 'Top speed',
                          unit: 'km/h',
                          color: Colors.red,
                          align: TextAlign.right,
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
                                year.isNotEmpty ? year : '-',
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
                                price.isNotEmpty ? price : '-',
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
                  // Description Card
                  _SectionCard(
                    icon: Icons.description,
                    title: labels['description'] ?? (isVi ? 'Mô tả' : 'Description'),
                    child: Text(
                      desc.isNotEmpty ? desc : (isVi ? 'Không có mô tả.' : 'No description.'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Engine Card
                  _SectionCard(
                    icon: Icons.engineering,
                    title: labels['engine_details'] ?? (isVi ? 'Động cơ' : 'Engine'),
                    child: Text(
                      engine.isNotEmpty ? engine : (isVi ? 'Không có thông tin động cơ.' : 'No engine information available.'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Interior Card
                  _SectionCard(
                    icon: Icons.chair_alt,
                    title: labels['interior_details'] ?? (isVi ? 'Nội thất & Tính năng' : 'Interior & Features'),
                    child: Text(
                      interiorText.isNotEmpty ? interiorText : (isVi ? 'Không có thông tin nội thất.' : 'No interior information available.'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
  final TextAlign align;
  const _StatBox({required this.value, required this.label, required this.unit, required this.color, this.align = TextAlign.left});

  List<String> _splitValueAndUnit(String value, String fallbackUnit) {
    final regex = RegExp(r'([\d.,]+)\s*([a-zA-Z%/]+)?');
    final match = regex.firstMatch(value);
    if (match != null) {
      final number = match.group(1) ?? value;
      final unit = match.group(2) ?? fallbackUnit;
      return [number, unit];
    }
    return [value, fallbackUnit];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> parts = _splitValueAndUnit(value, unit);
    final String number = parts[0];
    final String unitStr = parts[1];
    CrossAxisAlignment colAlign = CrossAxisAlignment.start;
    MainAxisAlignment rowAlign = MainAxisAlignment.start;
    if (align == TextAlign.center) {
      colAlign = CrossAxisAlignment.center;
      rowAlign = MainAxisAlignment.center;
    } else if (align == TextAlign.right) {
      colAlign = CrossAxisAlignment.end;
      rowAlign = MainAxisAlignment.end;
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: colAlign,
      children: [
        Row(
          mainAxisAlignment: rowAlign,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              number,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color, height: 1.0),
            ),
            if (unitStr.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unitStr,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color.withOpacity(0.85), height: 1.0),
              ),
            ]
          ],
        ),
        const SizedBox(height: 2),
        if (unitStr.isNotEmpty)
          Text(
            unitStr,
            style: TextStyle(fontSize: 13, color: color.withOpacity(0.5)),
            textAlign: align,
          ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black54),
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.visible,
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