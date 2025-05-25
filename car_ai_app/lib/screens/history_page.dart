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
import '../widgets/page_title.dart';
import '../widgets/car_card.dart';

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
  String? selectedBrandName;
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
      await _loadHistory();
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

  Future<CarModel> translateHistoryRecord(CarModel car, String lang) async {
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

  CarBrand? findBrandByName(String brandName) {
    return brands.firstWhere(
      (b) => b.name.toLowerCase() == brandName.toLowerCase(),
      orElse: () => CarBrand(name: '', logoUrl: ''),
    );
  }

  void _onBrandSelected(String brand) {
    setState(() {
      selectedBrandName = brand;
    });
  }

  void _clearBrandSelection() {
    setState(() {
      selectedBrandName = null;
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
        title: PageTitle(isVi ? 'Lịch sử' : 'History'),
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
            selected: selectedBrandName == null,
            selectedColor: const Color(0xFF2196F3),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selectedBrandName == null ? Colors.white : Colors.black,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selectedBrandName == null ? const Color(0xFF2196F3) : Colors.grey[300]!,
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
              selected: selectedBrandName == brand,
              selectedColor: const Color(0xFF2196F3),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selectedBrandName == brand ? Colors.white : Colors.black,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: selectedBrandName == brand ? const Color(0xFF2196F3) : Colors.grey[300]!,
                ),
              ),
              onSelected: (_) => _onBrandSelected(brand),
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
    final filteredHistory = selectedBrandName != null
        ? history.where((car) => car.brand.trim().toLowerCase() == selectedBrandName!.trim().toLowerCase()).toList()
        : history;

    return ListView.builder(
      itemCount: filteredHistory.length,
      itemBuilder: (context, index) {
        final car = filteredHistory[index];
        return CarCard(
          car: car,
          langCode: widget.langCode,
          onTap: () => _openCarDetail(car),
          onDelete: () async {
            await _storageService.removeFromHistory(car);
            setState(() {
              history.removeWhere((item) => item.timestamp == car.timestamp);
            });
          },
        );
      },
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