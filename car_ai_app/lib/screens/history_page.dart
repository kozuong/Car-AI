import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/car_brand.dart';
import '../models/car_model.dart';
import '../services/storage_service.dart';
import '../config/constants.dart';
import 'car_detail_page.dart';
import 'package:shimmer/shimmer.dart';

class HistoryPage extends StatefulWidget {
  final String langCode;
  
  const HistoryPage({
    super.key, 
    required this.langCode
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with AutomaticKeepAliveClientMixin {
  List<CarBrand> brands = [];
  List<CarModel> history = [];
  bool isLoading = true;
  CarBrand? selectedBrand;
  final StorageService _storageService = StorageService();
  String? _historyError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.langCode != widget.langCode) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      await Future.wait([
        fetchBrands(),
        _loadHistory(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.langCode == 'vi' 
                ? '❌ Lỗi khi tải dữ liệu: $e'
                : '❌ Error loading data: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadHistory() async {
    try {
      final historyData = await _storageService.getHistory();
      if (mounted) {
        setState(() {
          history = historyData;
          _historyError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _historyError = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.langCode == 'vi' 
                ? '❌ Lỗi khi tải lịch sử: $e'
                : '❌ Error loading history: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchBrands() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.apiBaseUrl}/brands'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            brands = data.map((e) => CarBrand.fromJson(e)).toList();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.langCode == 'vi' 
                  ? '❌ Lỗi khi tải thương hiệu: ${response.statusCode}'
                  : '❌ Error loading brands: ${response.statusCode}'
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.langCode == 'vi' 
                ? '❌ Lỗi khi tải thương hiệu: $e'
                : '❌ Error loading brands: $e'
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  CarBrand? findBrandByName(String brandName) {
    return brands.firstWhere(
      (b) => b.name.toLowerCase() == brandName.toLowerCase(),
      orElse: () => CarBrand(name: '', logoUrl: ''),
    );
  }

  void _onBrandSelected(CarBrand brand) {
    setState(() {
      selectedBrand = brand;
    });
  }

  void _clearBrandSelection() {
    setState(() {
      selectedBrand = null;
    });
  }

  Future<void> _clearHistory() async {
    await _storageService.clearHistory();
    setState(() {
      history.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.messages[widget.langCode]!['clearHistory']!),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _openCarDetail(CarModel car) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CarDetailPage(
          car: car,
          langCode: widget.langCode,
        ),
      ),
    ).then((_) {
      // Reload history when returning from detail page
      _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isVi = widget.langCode == 'vi';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isVi ? 'Lịch sử' : 'History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: isLoading
          ? _buildLoadingShimmer()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandFilter(),
                Expanded(
                  child: history.isEmpty
                      ? _buildEmptyState()
                      : _buildHistoryList(),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 220,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandFilter() {
    final brandNames = history.map((e) => e.brand).toSet().toList();
    final brandCounts = <String, int>{};
    for (var item in history) {
      brandCounts[item.brand] = (brandCounts[item.brand] ?? 0) + 1;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(
              AppConstants.messages[widget.langCode]!['all']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            selected: selectedBrand == null,
            selectedColor: const Color(0xFF2196F3),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selectedBrand == null ? Colors.white : Colors.black,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selectedBrand == null ? const Color(0xFF2196F3) : Colors.grey[300]!,
              ),
            ),
            onSelected: (_) => _clearBrandSelection(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          const SizedBox(width: 8),
          ...brandNames.map((brand) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                '$brand ${brandCounts[brand] ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              selected: selectedBrand?.name == brand,
              selectedColor: const Color(0xFF2196F3),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selectedBrand?.name == brand ? Colors.white : Colors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selectedBrand?.name == brand ? const Color(0xFF2196F3) : Colors.grey[300]!,
                ),
              ),
              onSelected: (_) => _onBrandSelected(findBrandByName(brand)!),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_historyError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 18),
            Text(
              widget.langCode == 'vi'
                ? 'Lỗi khi tải lịch sử:'
                : 'Error loading history:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _historyError!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 18),
          Text(
            widget.langCode == 'vi' 
              ? 'Chưa có lịch sử phân tích xe'
              : 'No car analysis history yet',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.langCode == 'vi'
              ? 'Hãy chụp ảnh xe để bắt đầu'
              : 'Take a car photo to start',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredHistory = selectedBrand != null
        ? history.where((car) => car.brand.toLowerCase() == selectedBrand!.name.toLowerCase()).toList()
        : history;

    return ListView.builder(
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final car = filteredHistory[index];
        final isVi = widget.langCode == 'vi';
        
        // Format power and speed based on language
        final powerText = isVi ? '${car.power} mã lực' : '${car.power} HP';
        final speedText = isVi ? '${car.topSpeed} km/h' : '${car.topSpeed} km/h';
        final yearText = isVi ? 'Năm ${car.year}' : 'Year ${car.year}';

        return GestureDetector(
          onTap: () => _openCarDetail(car),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.file(
                    File(car.imagePath),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$yearText • $powerText • $speedText',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 