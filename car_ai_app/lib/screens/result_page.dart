import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:car_ai_app/models/car_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';

class ResultPage extends StatefulWidget {
  final CarModel carModel;
  final String langCode;

  const ResultPage({
    Key? key,
    required this.carModel,
    required this.langCode,
  }) : super(key: key);

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final GlobalKey _shareKey = GlobalKey();

  Future<void> _captureAndShare(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary = _shareKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/car_result.jpg').create();
      await file.writeAsBytes(pngBytes);
      await Share.shareFiles([file.path], text: 'Check out this car!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVi = widget.langCode == 'vi';
    final car = widget.carModel;
    final carName = car.getLocalizedText('carName', widget.langCode);
    final brand = car.getLocalizedText('brand', widget.langCode);
    final year = car.getLocalizedText('year', widget.langCode);
    final price = car.getLocalizedText('price', widget.langCode);
    final numberProduced = car.getLocalizedText('numberProduced', widget.langCode);
    final rarity = car.getLocalizedText('rarity', widget.langCode);
    final desc = car.getLocalizedText('description', widget.langCode);
    final engine = car.getLocalizedText('engine', widget.langCode);
    final interiorText = car.getLocalizedText('interior', widget.langCode);
    final pageTitle = car.pageTitle;
    final logoUrl = car.logoUrl;
    final features = car.features;
    final imagePath = car.imagePath;
    final power = car.power;
    final acceleration = car.acceleration;
    final topSpeed = car.topSpeed;
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
            onPressed: () => _captureAndShare(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: _shareKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Car Image with Logo Overlay
            Stack(
              children: [
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
                if (logoUrl != null && logoUrl!.isNotEmpty)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: buildLogo(logoUrl!),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                          value: CarModel.getAverageValue(power),
                          label: isVi ? 'Công suất' : 'Power',
                          unit: 'hp',
                          color: Colors.blue,
                            align: TextAlign.left,
                          ),
                        ),
                        Expanded(
                          child: _StatBox(
                            value: car.getLocalizedText('acceleration', widget.langCode),
                          label: isVi ? 'Tăng tốc 0-100' : '0-100 km/h',
                          unit: 's',
                          color: Colors.green,
                            align: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: _StatBox(
                          value: CarModel.getAverageValue(topSpeed),
                          label: isVi ? 'Tốc độ tối đa' : 'Top speed',
                          unit: 'km/h',
                          color: Colors.red,
                            align: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Info table (year, price, number produced, rarity)
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isVi ? 'Năm' : 'Year', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(year.isNotEmpty ? year : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                              Text(price.isNotEmpty ? price : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), textAlign: TextAlign.right),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isVi ? 'Số lượng sản xuất' : 'Number produced', style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text((numberProduced != null && numberProduced!.isNotEmpty) ? numberProduced! : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
                              _buildStarRating(rarity),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Description Card
            _SectionCard(
              icon: Icons.description,
              title: isVi ? 'Mô tả' : 'Description',
              child: Text(
                desc.isNotEmpty ? desc : (isVi ? 'Không có mô tả.' : 'No description.'),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 14),
            // Engine Card
            _SectionCard(
              icon: Icons.engineering,
              title: isVi ? 'Động cơ' : 'Engine',
              child: Text(
                engine.isNotEmpty ? engine : (isVi ? 'Không có thông tin động cơ.' : 'No engine information available.'),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 14),
            // Interior Card
            _SectionCard(
              icon: Icons.chair_alt,
              title: isVi ? 'Nội thất & Tính năng' : 'Interior & Features',
              child: Text(
                interiorText.isNotEmpty ? interiorText : (isVi ? 'Không có thông tin nội thất.' : 'No interior information available.'),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating(String? rarity) {
    int filled = 1;
    bool hasHalf = false;
    if (rarity != null && rarity.isNotEmpty) {
      if (rarity.contains('½') || rarity.contains('4.5')) {
        filled = 4;
        hasHalf = true;
      } else if (rarity.contains('★½')) {
        filled = 1;
        hasHalf = true;
      } else if (rarity.contains('★★½')) {
        filled = 2;
        hasHalf = true;
      } else if (rarity.contains('★★★½')) {
        filled = 3;
        hasHalf = true;
      } else {
        filled = rarity.replaceAll(RegExp(r'[^★]'), '').length;
        hasHalf = false;
      }
      if (filled < 1) filled = 1;
      if (filled > 5) filled = 5;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < filled) {
          return Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index == filled && hasHalf) {
          return Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[300], size: 20);
        }
      }),
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