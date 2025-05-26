import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'connectivity_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000';

  Future<File> _resizeImageIfNeeded(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) return imageFile;
    if (original.width <= 1024 && original.height <= 1024) return imageFile;
    final resized = img.copyResize(original, width: 1024, height: 1024, interpolation: img.Interpolation.linear);
    final resizedBytes = img.encodeJpg(resized, quality: 85);
    final resizedFile = await imageFile.writeAsBytes(resizedBytes, flush: true);
    return resizedFile;
  }

  Future<CarModel> analyzeCarImage(File imageFile, String langCode) async {
    print('[ApiService] Bắt đầu analyzeCarImage với file: ${imageFile.path}, lang: $langCode');
    if (!await _connectivityService.isConnected()) {
      print('[ApiService] Không có kết nối internet');
      throw Exception(langCode == 'vi' 
          ? 'Không có kết nối internet. Vui lòng kiểm tra lại kết nối của bạn.'
          : 'No internet connection. Please check your connection.');
    }

    int retryCount = 0;
    Exception? lastError;

    while (retryCount <= AppConstants.maxRetries) {
      try {
        // Resize image if needed
        File processedImage = await _resizeImageIfNeeded(imageFile);
        print('[ApiService] Đã resize ảnh (nếu cần), path: ${processedImage.path}');
        
        // Check file size
        final fileSize = await processedImage.length();
        print('[ApiService] Kích thước file: $fileSize bytes');
        if (fileSize > AppConstants.maxImageSizeMB * 1024 * 1024) {
          print('[ApiService] File quá lớn');
          throw Exception(AppConstants.errorMessages[langCode]!['file_too_large']);
        }

        final uri = Uri.parse('$_baseUrl/analyze_car');
        print('[ApiService] Gửi request tới: $uri (Lần thử: ${retryCount + 1})');
        
        // Generate unique request ID
        final requestId = DateTime.now().millisecondsSinceEpoch.toString();
        
        // Create multipart request
        final request = http.MultipartRequest('POST', uri)
          ..fields['lang'] = langCode
          ..headers['X-Request-ID'] = requestId;

        // Add image file
        final contentType = _getImageContentType(processedImage.path);
        if (contentType == null) {
          print('[ApiService] Định dạng file không được hỗ trợ');
          throw Exception(langCode == 'vi'
              ? 'Định dạng file không được hỗ trợ. Vui lòng sử dụng JPG, PNG hoặc GIF.'
              : 'Unsupported file format. Please use JPG, PNG or GIF.');
        }

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          processedImage.path,
          contentType: contentType,
        ));

        print('[ApiService] Request headers: ${request.headers}');
        print('[ApiService] Request fields: ${request.fields}');

        // Send request with timeout
        final streamed = await request.send().timeout(
          Duration(seconds: AppConstants.apiTimeoutSeconds),
          onTimeout: () {
            print('[ApiService] Request timeout');
            throw TimeoutException('Request timed out');
          },
        );

        // Get response with timeout
        final response = await http.Response.fromStream(streamed).timeout(
          Duration(seconds: AppConstants.streamTimeoutSeconds),
          onTimeout: () {
            print('[ApiService] Response timeout');
            throw TimeoutException('Response timed out');
          },
        );

        print('[ApiService] Response status code: ${response.statusCode}');
        print('[ApiService] Response headers: ${response.headers}');
        print('[ApiService] Raw response body: ${response.body}');

        if (response.statusCode == 200) {
          try {
            final data = jsonDecode(response.body);
            print('[ApiService] Parsed JSON data:');
            safePrintResult(data);

            // Validate response structure
            if (data == null) {
              print('[ApiService] Response data is null');
              throw Exception(langCode == 'vi'
                  ? 'Phản hồi không hợp lệ từ máy chủ'
                  : 'Invalid response from server');
            }

            // Check if response has error status
            if (data['status'] == 'error') {
              print('[ApiService] Server returned error: ${data['error']}');
              throw Exception(data['error'] ?? (langCode == 'vi'
                  ? 'Lỗi máy chủ'
                  : 'Server error'));
            }

            // Validate required fields
            if (data['status'] != 'success') {
              print('[ApiService] Invalid status in response: ${data['status']}');
              throw Exception(langCode == 'vi'
                  ? 'Trạng thái phản hồi không hợp lệ'
                  : 'Invalid response status');
            }

            // Check for required result data
            if (data['result_en'] == null && data['result_vi'] == null) {
              print('[ApiService] Missing required fields in response');
              throw Exception(langCode == 'vi'
                  ? 'Không nhận diện được xe trong ảnh'
                  : 'Could not recognize car in image');
            }

            // Create CarModel from response
            final resultEn = data['result_en'] ?? data;
            final resultVi = data['result_vi'] ?? data;

            return CarModel(
              imagePath: imageFile.path,
              carName: resultEn['car_name'] ?? '',
              carNameEn: resultEn['car_name'] ?? '',
              carNameVi: resultVi['car_name_vi'] ?? resultVi['car_name'] ?? '',
              brand: resultEn['brand'] ?? '',
              brandEn: resultEn['brand'] ?? '',
              brandVi: resultVi['brand_vi'] ?? resultVi['brand'] ?? '',
              year: resultVi['year'] ?? resultEn['year'] ?? '',
              yearEn: resultEn['year'] ?? resultVi['year'] ?? '',
              yearVi: resultVi['year'] ?? resultEn['year'] ?? '',
              price: resultEn['price'] ?? '',
              priceEn: resultEn['price'] ?? '',
              priceVi: resultVi['price'] ?? '',
              power: resultEn['power'] ?? '',
              powerEn: resultEn['power'] ?? '',
              powerVi: resultVi['power'] ?? '',
              acceleration: resultEn['acceleration'] ?? '',
              accelerationEn: resultEn['acceleration'] ?? '',
              accelerationVi: resultVi['acceleration'] ?? '',
              topSpeed: resultEn['top_speed'] ?? '',
              topSpeedEn: resultEn['top_speed'] ?? '',
              topSpeedVi: resultVi['top_speed'] ?? '',
              engine: resultEn['engine_detail'] ?? '',
              engineEn: resultEn['engine_detail'] ?? '',
              engineVi: resultVi['engine_detail_vi'] ?? resultVi['engine_detail'] ?? '',
              interior: resultEn['interior'] ?? '',
              interiorEn: resultEn['interior'] ?? '',
              interiorVi: resultVi['interior_vi'] ?? resultVi['interior'] ?? '',
              features: (resultEn['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              featuresEn: (resultEn['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              featuresVi: (resultVi['features_vi'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? (resultVi['features'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
              description: resultEn['description'] ?? '',
              descriptionEn: resultEn['description'] ?? '',
              descriptionVi: resultVi['description_vi'] ?? resultVi['description'] ?? '',
              pageTitle: langCode == 'vi' ? 'Kết quả phân tích' : 'Analysis Result',
              logoUrl: resultEn['logo_url'] ?? '',
              numberProduced: resultEn['number_produced'] ?? '',
              numberProducedEn: resultEn['number_produced'] ?? '',
              numberProducedVi: resultVi['number_produced'] ?? '',
              rarity: resultEn['rarity']?.toString() ?? '',
              rarityEn: resultEn['rarity']?.toString() ?? '',
              rarityVi: resultVi['rarity']?.toString() ?? '',
              engineDetailEn: resultEn['engine_detail_en'] ?? resultEn['engine_detail'] ?? '',
              engineDetailVi: resultVi['engine_detail_vi'] ?? resultVi['engine_detail'] ?? '',
            );
          } catch (e) {
            print('[ApiService] Failed to parse response: $e');
            throw Exception(langCode == 'vi'
                ? 'Lỗi xử lý phản hồi: $e'
                : 'Error processing response: $e');
          }
        } else if (response.statusCode == 429) {
          print('[ApiService] Rate limit exceeded');
          throw Exception(langCode == 'vi'
              ? 'Quá nhiều yêu cầu. Vui lòng đợi một chút.'
              : 'Too many requests. Please wait a moment.');
        } else {
          print('[ApiService] Server error: ${response.statusCode}');
          throw Exception(langCode == 'vi'
              ? 'Lỗi máy chủ: ${response.statusCode}'
              : 'Server error: ${response.statusCode}');
        }
      } catch (e) {
        lastError = e as Exception;
        print('[ApiService] Request failed (Attempt ${retryCount + 1}): $e');
        
        // Only retry on network errors or timeouts
        if (e is TimeoutException || e is SocketException) {
          retryCount++;
          if (retryCount <= AppConstants.maxRetries) {
            print('[ApiService] Retrying in ${AppConstants.retryDelaySeconds} seconds...');
            await Future.delayed(Duration(seconds: AppConstants.retryDelaySeconds));
            continue;
          }
        }
        // Don't retry on other errors
        break;
      }
    }

    print('[ApiService] All retry attempts failed');
    throw lastError ?? Exception(langCode == 'vi'
        ? 'Không thể phân tích ảnh sau nhiều lần thử'
        : 'Failed to analyze image after multiple attempts');
  }

  MediaType? _getImageContentType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return null;
    }
  }

  Future<List<CarModel>> fetchHistory() async {
    final uri = Uri.parse('$_baseUrl/history');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch history: ${response.statusCode}');
    }
  }

  Future<List<CarModel>> fetchCollection([String collectionName = 'Favorites']) async {
    final uri = Uri.parse('$_baseUrl/collection?name=$collectionName');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch collection: \\${response.statusCode}');
    }
  }

  void safePrintResult(dynamic data, {int maxLength = 100}) {
    if (data is Map) {
      data.forEach((key, value) {
        if (value is String && (value.length > maxLength || key.contains('base64') || value.startsWith('data:image'))) {
          print('[33m$key: [omitted][0m');
        } else if (value is Map || value is List) {
          print('[36m$key: {[0m');
          safePrintResult(value, maxLength: maxLength);
          print('[36m}[0m');
        } else {
          print('$key: $value');
        }
      });
    } else if (data is List) {
      for (var item in data) {
        safePrintResult(item, maxLength: maxLength);
      }
    } else {
      print(data);
    }
  }
} 