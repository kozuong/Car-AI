import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'result_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import '../config/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/error_handler.dart';
import '../services/storage_service.dart';
import '../models/car_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../services/ads_service.dart';
import '../widgets/premium_popup.dart';

class CameraPage extends StatefulWidget {
  final String langCode;
  const CameraPage({super.key, required this.langCode});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final AdsService _adsService = AdsService();

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      setState(() => _isLoading = true);
      
      // Kiểm tra kết nối mạng
      if (!await ErrorHandler.checkInternetConnection()) {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Không có kết nối mạng. Vui lòng kiểm tra lại.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.langCode == 'vi' 
                ? '⏳ Đang phân tích ảnh...'
                : '⏳ Analyzing image...'
            ),
            duration: const Duration(seconds: 1),
          ),
        );

        // Resize ảnh để gửi API, giữ ảnh gốc cho UI
        final resizedPath = await _resizeAndSaveTemp(image.path);
        
        // Gửi request với timeout
        final resultEn = await _analyzeImageWithLang(resizedPath, 'en')
            .timeout(const Duration(seconds: 30), onTimeout: () {
          return {
            "car_name": "Timeout",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Quá thời gian chờ. Vui lòng thử lại.",
            "en": "⚠️ Request timed out. Please try again."
          };
        });

        final resultVi = await _analyzeImageWithLang(resizedPath, 'vi')
            .timeout(const Duration(seconds: 30), onTimeout: () {
          return {
            "car_name": "Timeout",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Quá thời gian chờ. Vui lòng thử lại.",
            "en": "⚠️ Request timed out. Please try again."
          };
        });
        
        if (!mounted) return;

        if (resultEn['car_name'] == 'API error' || 
            resultEn['car_name'] == 'Exception' || 
            resultEn['car_name'] == 'Timeout' ||
            resultEn['car_name'] == 'Connection Error' ||
            resultEn['car_name'] == 'No internet') {
          ErrorHandler.showErrorSnackBar(context, resultEn[widget.langCode] ?? 'Error');
          return;
        }

        // Lưu vào lịch sử trước
        try {
          final carModel = CarModel(
            imagePath: image.path,
            carName: widget.langCode == 'vi' ? resultVi['car_name'] ?? '' : resultEn['car_name'] ?? '',
            brand: widget.langCode == 'vi' ? resultVi['brand'] ?? '' : resultEn['brand'] ?? '',
            year: widget.langCode == 'vi' ? resultVi['year'] ?? '' : resultEn['year'] ?? '',
            price: widget.langCode == 'vi' ? resultVi['price'] ?? '' : resultEn['price'] ?? '',
            power: widget.langCode == 'vi' ? resultVi['power'] ?? '' : resultEn['power'] ?? '',
            acceleration: widget.langCode == 'vi' ? resultVi['acceleration'] ?? '' : resultEn['acceleration'] ?? '',
            topSpeed: widget.langCode == 'vi' ? resultVi['top_speed'] ?? '' : resultEn['top_speed'] ?? '',
            engine: widget.langCode == 'vi' ? resultVi['engine_detail'] ?? '' : resultEn['engine_detail'] ?? '',
            interior: widget.langCode == 'vi' ? resultVi['interior'] ?? '' : resultEn['interior'] ?? '',
            features: widget.langCode == 'vi' 
              ? (resultVi['features'] != null ? (resultVi['features'] as List).map((e) => e.toString()).toList() : [])
              : (resultEn['features'] != null ? (resultEn['features'] as List).map((e) => e.toString()).toList() : []),
            description: widget.langCode == 'vi' ? resultVi['description'] ?? '' : resultEn['description'] ?? '',
            descriptionEn: resultEn['description'] ?? '',
            descriptionVi: resultVi['description'] ?? '',
            engineDetailEn: resultEn['engine_detail'] ?? '',
            engineDetailVi: resultVi['engine_detail'] ?? '',
            interiorEn: resultEn['interior'] ?? '',
            interiorVi: resultVi['interior'] ?? '',
            pageTitle: widget.langCode == 'vi' ? 'Kết quả phân tích' : 'Analysis Result',
          );

          // Kiểm tra dữ liệu trước khi lưu
          if (carModel.carName.isEmpty) {
            throw Exception('Tên xe không được để trống');
          }

          // Lưu vào lịch sử
          await StorageService().saveCarToHistory(carModel);
          
          // Lưu vào bộ sưu tập theo thương hiệu (nếu brand hợp lệ)
          final brand = carModel.brand.trim();
          if (brand.isNotEmpty && !brand.contains(RegExp(r'[\\/:*?"<>|]'))) {
          try {
              await StorageService().saveCarToCollection(carModel, brand);
          } catch (e) {
              print('Error saving to brand collection: $e');
          }
          }

          // Chuyển đến trang kết quả
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                imagePath: image.path,
                carName: widget.langCode == 'vi' ? resultVi['car_name'] ?? '' : resultEn['car_name'] ?? '',
                brand: widget.langCode == 'vi' ? resultVi['brand'] ?? '' : resultEn['brand'] ?? '',
                year: widget.langCode == 'vi' ? resultVi['year'] ?? '' : resultEn['year'] ?? '',
                price: widget.langCode == 'vi' ? resultVi['price'] ?? '' : resultEn['price'] ?? '',
                power: widget.langCode == 'vi' ? resultVi['power'] ?? '' : resultEn['power'] ?? '',
                acceleration: widget.langCode == 'vi' ? resultVi['acceleration'] ?? '' : resultEn['acceleration'] ?? '',
                topSpeed: widget.langCode == 'vi' ? resultVi['top_speed'] ?? '' : resultEn['top_speed'] ?? '',
                description: widget.langCode == 'vi' ? resultVi['description'] ?? '' : resultEn['description'] ?? '',
                features: widget.langCode == 'vi'
                  ? (resultVi['features'] != null ? List<String>.from(resultVi['features']) : [])
                  : (resultEn['features'] != null ? List<String>.from(resultEn['features']) : []),
                engineDetail: widget.langCode == 'vi' ? resultVi['engine_detail'] ?? '' : resultEn['engine_detail'] ?? '',
                interior: widget.langCode == 'vi' ? resultVi['interior'] ?? '' : resultEn['interior'] ?? '',
                pageTitle: widget.langCode == 'vi' ? 'Kết quả phân tích' : 'Analysis Result',
                labels: widget.langCode == 'vi'
                  ? (resultVi['labels'] != null ? Map<String, String>.from(resultVi['labels']) : <String, String>{})
                  : (resultEn['labels'] != null ? Map<String, String>.from(resultEn['labels']) : <String, String>{}),
              ),
            ),
          );

          // Sau khi hiển thị kết quả, kiểm tra và hiển thị quảng cáo
          if (!mounted) return;
          await _adsService.incrementScanCount();
          
          // Chỉ hiện popup ở lần quét đúng thứ 3
          if (!_adsService.isPremium && _adsService.scanCount == 3) {
            if (!mounted) return;
            final continueWithAds = await _showPremiumPopup();
            // Nếu chọn tiếp tục với quảng cáo thì show ad luôn
            if (continueWithAds == true) {
              await _adsService.showAd();
            }
          }
          
          // Quay về trang chủ và chuyển đến tab lịch sử
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (context.mounted) {
            HomePage.switchToHistory(context);
          }
        } catch (e) {
          if (!mounted) return;
          ErrorHandler.showErrorSnackBar(
            context, 
            widget.langCode == 'vi'
              ? '❌ Không thể lưu vào lịch sử: $e'
              : '❌ Failed to save to history: $e'
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ErrorHandler.showErrorSnackBar(context, 'Không thể lấy ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeImageWithLang(String imagePath, String lang) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.analyzeEndpoint}');
    final file = File(imagePath);
    
    try {
      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        return {
          "car_name": "File too large",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ File ảnh quá lớn (>5MB). Vui lòng chọn ảnh nhỏ hơn.",
          "en": "⚠️ Image file too large (>5MB). Please select a smaller image."
        };
      }

      // Kiểm tra kết nối mạng
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          return {
            "car_name": "No internet",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Không có kết nối mạng. Vui lòng kiểm tra lại.",
            "en": "⚠️ No internet connection. Please check your connection."
          };
        }
      } on SocketException catch (_) {
        return {
          "car_name": "No internet",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Không có kết nối mạng. Vui lòng kiểm tra lại.",
          "en": "⚠️ No internet connection. Please check your connection."
        };
      }

      final request = http.MultipartRequest('POST', uri)
        ..fields['lang'] = lang
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Thêm timeout cho request
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      final response = await http.Response.fromStream(streamed).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Response timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null || data['car_name'] == null) {
          return {
            "car_name": "Invalid response",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Không nhận diện được xe trong ảnh",
            "en": "⚠️ Could not recognize car in image"
          };
        }
        return data;
      } else {
        return {
          "car_name": "API error",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Lỗi máy chủ: ${response.statusCode}",
          "en": "⚠️ Server error: ${response.statusCode}"
        };
      }
    } on TimeoutException {
      return {
        "car_name": "Timeout",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Quá thời gian chờ. Vui lòng thử lại.",
        "en": "⚠️ Request timed out. Please try again."
      };
    } on SocketException {
      return {
        "car_name": "Connection Error",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.",
        "en": "⚠️ Cannot connect to server. Please check your network connection."
      };
    } catch (e) {
      return {
        "car_name": "Error",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Đã xảy ra lỗi: $e",
        "en": "⚠️ An error occurred: $e"
      };
    }
  }

  Future<void> _checkPermissionAndGetImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _getImage(source);
      } else {
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Cần quyền truy cập camera để sử dụng tính năng này');
      }
    } else {
      _getImage(source);
    }
  }

  // Hàm resize ảnh và lưu file tạm
  Future<String> _resizeAndSaveTemp(String originalPath) async {
    final bytes = await File(originalPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return originalPath;
    final resized = img.copyResize(image, width: 512, height: 512, interpolation: img.Interpolation.linear);
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/car_ai_temp.jpg';
    final jpg = img.encodeJpg(resized, quality: 75);
    await File(tempPath).writeAsBytes(jpg);
    return tempPath;
  }

  Future<bool?> _showPremiumPopup() async {
    // Trả về true nếu chọn tiếp tục với quảng cáo, false nếu mua premium hoặc đóng
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PremiumPopup(
        langCode: widget.langCode,
        onContinueWithAds: () {
          Navigator.pop(context, true);
        },
        onPurchase: () async {
          Navigator.pop(context, false);
          final success = await _adsService.purchaseRemoveAds();
          if (success) {
            await _adsService.setPremiumStatus(true);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.langCode == 'vi'
                    ? '✅ Cảm ơn bạn đã nâng cấp lên Premium!'
                    : '✅ Thank you for upgrading to Premium!'
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.langCode == 'vi'
                    ? '❌ Không thể hoàn tất giao dịch. Vui lòng thử lại.'
                    : '❌ Could not complete the transaction. Please try again.'
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVi = widget.langCode == 'vi';
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 80,
                color: Color(0xFF2196F3),
              ),
              const SizedBox(height: 24),
              Text(
                isVi ? 'Chụp ảnh xe' : 'Take Car Photo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isVi 
                  ? 'Đặt xe vào khung hình và chụp ảnh rõ nét'
                  : 'Place the car in frame and take a clear photo',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _checkPermissionAndGetImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(isVi ? 'Máy ảnh' : 'Camera'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _checkPermissionAndGetImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(isVi ? 'Thư viện' : 'Gallery'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
} 