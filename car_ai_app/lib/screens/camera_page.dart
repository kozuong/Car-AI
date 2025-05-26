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
import '../services/ad_service.dart';
import 'premium_page.dart';

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
  final AdService _adService = AdService();
  bool _isAnalyzing = false;
  String? _lastRequestId;
  DateTime? _lastRequestTime;

  @override
  void initState() {
    super.initState();
    _adsService.initialize();
  }

  Future<void> _checkPermissionAndGetImage(ImageSource source) async {
    // Kiểm tra số lần quét
    bool shouldShowPremium = await _adService.shouldShowPremium();
    if (shouldShowPremium) {
      if (!mounted) return;
      final continueWithAds = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PremiumPage(
          langCode: widget.langCode,
          onContinueWithAds: () {
            Navigator.pop(context, true);
          },
          onPurchasePremium: () async {
            final success = await _adService.purchasePremium();
            Navigator.pop(context, false);
            if (success) {
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
              return; // Không cho phép tiếp tục nếu mua Premium thất bại
            }
          },
        ),
      );
      if (continueWithAds == true) {
        await _adService.showAd();
        // Sau khi xem quảng cáo mới cho phép chọn ảnh
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
      // Nếu chọn nâng cấp premium thì không cho chọn ảnh nữa (chờ mua xong)
      return;
    }
    // Nếu chưa đến lượt hiện Premium, cho phép chọn ảnh bình thường
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

  Future<void> _getImage(ImageSource source, {bool showAd = false}) async {
    try {
      // Ẩn mọi SnackBar cũ trước khi thao tác mới
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
      setState(() => _isLoading = true);
      
      print('\n📸 [ImagePicker] Starting image selection:');
      print('   ├─ Source: ${source == ImageSource.camera ? 'Camera' : 'Gallery'}');
      print('   └─ Show ad: $showAd');
      
      // Kiểm tra kết nối mạng
      if (!await ErrorHandler.checkInternetConnection()) {
        print('🌐 [ImagePicker] No internet connection');
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Không có kết nối mạng. Vui lòng kiểm tra lại.');
        return;
      }

      // Nếu cần hiện quảng cáo thì chạy song song với việc chọn ảnh
      if (showAd) {
        print('📺 [ImagePicker] Showing ad in background');
        _adService.showAd(); // Bỏ await để chạy song song
      }

      print('📸 [ImagePicker] Requesting image from picker...');
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ [ImagePicker] Image picker timeout after 30s');
          throw TimeoutException('Image picker timed out');
        },
      );

      if (image == null) {
        print('❌ [ImagePicker] No image selected or picker cancelled');
        if (!mounted) return;
        ErrorHandler.showErrorSnackBar(context, 'Không thể lấy ảnh. Vui lòng thử lại.');
        return;
      }

      print('✅ [ImagePicker] Image selected successfully:');
      print('   ├─ Path: ${image.path}');
      print('   ├─ Name: ${image.name}');
      print('   └─ Size: ${(await image.length() / 1024 / 1024).toStringAsFixed(2)}MB');

      // Kiểm tra xem có cần hiện Premium page không
      bool shouldShowPremium = await _adService.shouldShowPremium();
      
      if (shouldShowPremium) {
        print('💎 [ImagePicker] Showing premium page');
        if (!mounted) return;
        final continueWithAds = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => PremiumPage(
            langCode: widget.langCode,
            onContinueWithAds: () {
              Navigator.pop(context, true);
            },
            onPurchasePremium: () {
              Navigator.pop(context, false);
            },
          ),
        );

        if (continueWithAds == true) {
          print('📺 [ImagePicker] User chose to continue with ads');
          // Nếu chọn tiếp tục với quảng cáo
          await _adService.showAd(); // Phải xem hết quảng cáo 30s
          await _adService.setPremiumShown();
        } else {
          print('💎 [ImagePicker] User chose to purchase premium');
          // Nếu chọn nâng cấp Premium
          final success = await _adService.purchasePremium();
          if (success) {
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
            return; // Không cho phép tiếp tục nếu mua Premium thất bại
          }
        }
      }

      // Tiếp tục xử lý ảnh
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

      print('🔄 [ImagePicker] Resizing image for API...');
      // Resize ảnh để gửi API, giữ ảnh gốc cho UI
      final resizedPath = await _resizeAndSaveTemp(image.path);
      print('✅ [ImagePicker] Image resized successfully:');
      print('   └─ Resized path: $resizedPath');
      
      // Chỉ gửi 1 request với ngôn ngữ hiện tại
      print('🚀 [ImagePicker] Starting image analysis...');
      final result = await _analyzeImage(resizedPath, widget.langCode)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        print('⏰ [ImagePicker] Analysis timeout after 30s');
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

      // Nếu backend trả về song ngữ
      final resultEn = result['result_en'] ?? result;
      final resultVi = result['result_vi'] ?? result;

      if ((resultEn['car_name'] ?? result['car_name']) == 'API error' || 
          (resultEn['car_name'] ?? result['car_name']) == 'Exception' || 
          (resultEn['car_name'] ?? result['car_name']) == 'Timeout' ||
          (resultEn['car_name'] ?? result['car_name']) == 'Connection Error' ||
          (resultEn['car_name'] ?? result['car_name']) == 'No internet') {
        print('❌ [ImagePicker] Analysis failed: ${result[widget.langCode]}');
        ErrorHandler.showErrorSnackBar(context, result[widget.langCode] ?? 'Error');
        return;
      }

      print('✅ [ImagePicker] Analysis completed successfully');
      // Tạo CarModel duy nhất theo langCode hiện tại (đã đồng bộ acceleration, description, ...)
      final isVi = widget.langCode == 'vi';
      final resultData = isVi ? resultVi : resultEn;
      final carModel = CarModel(
        imagePath: image.path,
        carName: resultData['car_name'] ?? '',
        carNameEn: resultEn['car_name'] ?? '',
        carNameVi: resultVi['car_name'] ?? '',
        brand: resultData['brand'] ?? '',
        year: resultData['year'] ?? '',
        yearEn: resultEn['year'] ?? '',
        yearVi: resultVi['year'] ?? '',
        price: resultData['price'] ?? '',
        priceEn: resultEn['price'] ?? '',
        priceVi: resultVi['price'] ?? '',
        power: resultData['power'] ?? '',
        powerEn: resultEn['power'] ?? '',
        powerVi: resultVi['power'] ?? '',
        acceleration: resultData['acceleration'] ?? '',
        accelerationEn: resultEn['acceleration'] ?? '',
        accelerationVi: resultVi['acceleration'] ?? '',
        topSpeed: resultData['top_speed'] ?? '',
        topSpeedEn: resultEn['top_speed'] ?? '',
        topSpeedVi: resultVi['top_speed'] ?? '',
        engine: resultData['engine_detail'] ?? '',
        engineEn: resultEn['engine_detail'] ?? '',
        engineVi: resultVi['engine_detail'] ?? '',
        engineDetailEn: resultEn['engine_detail_en'] ?? resultEn['engine_detail'] ?? '',
        engineDetailVi: resultVi['engine_detail_vi'] ?? resultVi['engine_detail'] ?? '',
        interior: resultData['interior'] ?? '',
        interiorEn: resultEn['interior'] ?? '',
        interiorVi: resultVi['interior_vi'] ?? resultVi['interior'] ?? '',
        features: resultData['features'] != null ? List<String>.from(resultData['features']) : [],
        featuresEn: resultEn['features'] != null ? List<String>.from(resultEn['features']) : [],
        featuresVi: resultVi['features_vi'] != null ? List<String>.from(resultVi['features_vi']) : (resultVi['features'] != null ? List<String>.from(resultVi['features']) : []),
        description: resultData['description'] ?? '',
        descriptionEn: resultEn['description'] ?? '',
        descriptionVi: resultVi['description_vi'] ?? resultVi['description'] ?? '',
        pageTitle: isVi ? 'Kết quả phân tích' : 'Analysis Result',
        logoUrl: resultData['logo_url'] ?? '',
        numberProduced: resultData['number_produced'] ?? '',
        numberProducedEn: resultEn['number_produced'] ?? '',
        numberProducedVi: resultVi['number_produced'] ?? '',
        rarity: resultData['rarity']?.toString() ?? '',
        rarityEn: resultEn['rarity']?.toString() ?? '',
        rarityVi: resultVi['rarity']?.toString() ?? '',
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

      // Chuyển đến trang kết quả, truyền đúng object CarModel vừa lưu vào history
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(
            carModel: carModel,
            langCode: widget.langCode,
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
      print('❌ [ImagePicker] Error: $e');
      // Kiểm tra xem lỗi xảy ra ở bước nào
      if (e is TimeoutException) {
        ErrorHandler.showErrorSnackBar(context, 'Quá thời gian chờ. Vui lòng thử lại.');
      } else if (e.toString().contains('permission')) {
        ErrorHandler.showErrorSnackBar(context, 'Cần quyền truy cập để sử dụng tính năng này.');
      } else if (e.toString().contains('connection')) {
        ErrorHandler.showErrorSnackBar(context, 'Không có kết nối mạng. Vui lòng kiểm tra lại.');
      } else {
        ErrorHandler.showErrorSnackBar(context, 'Đã xảy ra lỗi. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeImage(String imagePath, String lang) async {
    // Prevent duplicate requests
    if (_isAnalyzing) {
      print('🚫 [Analyze] Request blocked: Already analyzing another image');
      return {
        "car_name": "Already analyzing",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Đang phân tích ảnh khác. Vui lòng đợi.",
        "en": "⚠️ Already analyzing another image. Please wait."
      };
    }

    // Generate unique request ID
    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Check if we're making requests too quickly
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!).inSeconds;
      if (timeSinceLastRequest < 5) {
        print('⏱️ [Analyze] Request blocked: Too many requests (${timeSinceLastRequest}s since last request)');
        return {
          "car_name": "Too many requests",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Vui lòng đợi ít nhất 5 giây giữa các lần phân tích.",
          "en": "⚠️ Please wait at least 5 seconds between analyses."
        };
      }
    }

    // Check internet connection
    if (!await ErrorHandler.checkInternetConnection()) {
      print('🌐 [Analyze] Request blocked: No internet connection');
      return {
        "car_name": "No internet",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Không có kết nối mạng",
        "en": "⚠️ No internet connection"
      };
    }

    // Check image size
    final file = File(imagePath);
    final fileSize = await file.length();
    if (fileSize > 5 * 1024 * 1024) { // 5MB
      print('📁 [Analyze] Request blocked: Image too large (${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB)');
      return {
        "car_name": "Image too large",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Ảnh quá lớn (>5MB). Vui lòng chọn ảnh nhỏ hơn.",
        "en": "⚠️ Image too large (>5MB). Please choose a smaller image."
      };
    }

    _isAnalyzing = true;
    _lastRequestId = requestId;
    _lastRequestTime = DateTime.now();

    try {
      final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.analyzeEndpoint}');
      
      print('\n🚀 [Analyze] Starting new request:');
      print('   ├─ Request ID: $requestId');
      print('   ├─ Language: $lang');
      print('   ├─ Image size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      print('   └─ Endpoint: $uri');
      
      // Add request ID to headers
      final request = http.MultipartRequest('POST', uri)
        ..fields['lang'] = lang
        ..headers['X-Request-ID'] = requestId
        ..files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏰ [Analyze] Request timeout after 30s');
          throw TimeoutException('Request timed out');
        },
      );

      final response = await http.Response.fromStream(streamed).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ [Analyze] Response timeout after 10s');
          throw TimeoutException('Response timed out');
        },
      );

      print('\n📥 [Analyze] Received response:');
      print('   ├─ Status code: ${response.statusCode}');
      print('   ├─ Content type: ${response.headers['content-type']}');
      print('   └─ Content length: ${response.headers['content-length']} bytes');

      // Only process response if this is still the latest request
      if (requestId != _lastRequestId) {
        print('🔄 [Analyze] Request cancelled: New request started');
        return {
          "car_name": "Request cancelled",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Yêu cầu đã bị hủy do có yêu cầu mới.",
          "en": "⚠️ Request cancelled due to new request."
        };
      }

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          
          // Validate response structure
          if (data == null) {
            print('❌ [Analyze] Invalid response: Data is null');
            return {
              "car_name": "Invalid response",
              "year": "",
              "price": "",
              "interior": "",
              "engine": "",
              "vi": "⚠️ Phản hồi không hợp lệ từ máy chủ",
              "en": "⚠️ Invalid response from server"
            };
          }

          // Check if response has error status
          if (data['status'] == 'error') {
            print('❌ [Analyze] Server error: ${data['error']}');
            return {
              "car_name": "Server error",
              "year": "",
              "price": "",
              "interior": "",
              "engine": "",
              "vi": "⚠️ ${data['error'] ?? 'Lỗi máy chủ'}",
              "en": "⚠️ ${data['error'] ?? 'Server error'}"
            };
          }

          // Validate required fields
          if (data['status'] != 'success') {
            print('❌ [Analyze] Invalid status: ${data['status']}');
            return {
              "car_name": "Invalid status",
              "year": "",
              "price": "",
              "interior": "",
              "engine": "",
              "vi": "⚠️ Trạng thái phản hồi không hợp lệ",
              "en": "⚠️ Invalid response status"
            };
          }

          // Kiểm tra format response song ngữ
          if (data['result_en'] == null && data['result_vi'] == null && data['car_name'] == null) {
            print('❌ [Analyze] Missing required fields in response');
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

          // Nếu là response song ngữ
          if (data['result_en'] != null && data['result_vi'] != null) {
            print('✅ [Analyze] Successfully parsed bilingual response');
            print('   ├─ Processing time: ${data['processing_time']?.toStringAsFixed(2)}s');
            print('   └─ Car name: ${data['result_en']['car_name']}');
            return data;
          }

          // Nếu là response cũ (không có song ngữ)
          print('ℹ️ [Analyze] Using legacy response format');
          return {
            'result_en': data,
            'result_vi': data
          };
        } catch (e) {
          print('❌ [Analyze] Failed to parse response: $e');
          return {
            "car_name": "Parse error",
            "year": "",
            "price": "",
            "interior": "",
            "engine": "",
            "vi": "⚠️ Lỗi xử lý phản hồi: $e",
            "en": "⚠️ Error processing response: $e"
          };
        }
      } else if (response.statusCode == 429) {
        print('⏳ [Analyze] Rate limit exceeded');
        return {
          "car_name": "Too many requests",
          "year": "",
          "price": "",
          "interior": "",
          "engine": "",
          "vi": "⚠️ Quá nhiều yêu cầu. Vui lòng đợi một chút.",
          "en": "⚠️ Too many requests. Please wait a moment."
        };
      } else {
        print('❌ [Analyze] Server error: ${response.statusCode}');
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
    } catch (e) {
      print('❌ [Analyze] Request failed: $e');
      return {
        "car_name": "Error",
        "year": "",
        "price": "",
        "interior": "",
        "engine": "",
        "vi": "⚠️ Lỗi: ${e.toString()}",
        "en": "⚠️ Error: ${e.toString()}"
      };
    } finally {
      // Only reset if this is still the latest request
      if (requestId == _lastRequestId) {
        _isAnalyzing = false;
      }
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
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    widget.langCode == 'vi' 
                      ? 'Đang phân tích ảnh...'
                      : 'Analyzing image...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 