import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import 'dart:async';
import 'package:image/image.dart' as img;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

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
    try {
      // Resize image if needed
      File processedImage = await _resizeImageIfNeeded(imageFile);
      // Check file size
      final fileSize = await processedImage.length();
      if (fileSize > AppConstants.maxImageSizeMB * 1024 * 1024) {
        throw Exception(AppConstants.errorMessages[langCode]!['file_too_large']);
      }

      // Use original file if size is acceptable
      if (fileSize > 1 * 1024 * 1024) { // If larger than 1MB
        print('Large image detected: ${fileSize / 1024}KB');
      }

      final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.analyzeEndpoint}');
      
      int retryCount = 0;
      Exception? lastError;
      
      while (retryCount <= AppConstants.maxRetries) {
        try {
          // Create a new request for each attempt
          final request = http.MultipartRequest('POST', uri)
            ..fields['lang'] = langCode;

          // Add file with explicit content type
          final file = await http.MultipartFile.fromPath(
            'image', 
            processedImage.path,
            contentType: _getImageContentType(processedImage.path),
          );
          request.files.add(file);

          print('Sending request attempt ${retryCount + 1}');
          
          // Send request with timeout
          final streamedResponse = await request.send().timeout(
            Duration(seconds: AppConstants.apiTimeoutSeconds),
            onTimeout: () {
              throw TimeoutException(AppConstants.errorMessages[langCode]!['timeout']);
            },
          );

          // Convert stream to response with shorter timeout
          final response = await http.Response.fromStream(streamedResponse).timeout(
            Duration(seconds: AppConstants.streamTimeoutSeconds),
            onTimeout: () {
              throw TimeoutException(AppConstants.errorMessages[langCode]!['timeout']);
            },
          );

          print('Response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              print('Received data: $data');

              // Extract car name and basic info
              final carName = data['Car Name'] ?? data['car_name'] ?? '';
              if (carName.isEmpty) {
                throw Exception(AppConstants.errorMessages[langCode]!['invalid_response']);
              }

              // Extract other fields with fallbacks and log if missing
              return CarModel(
                imagePath: imageFile.path,
                carName: carName,
                brand: data['Brand'] ?? data['brand'] ?? '',
                year: data['Year'] ?? data['year'] ?? '',
                price: data['Price'] ?? data['price'] ?? '',
                power: data['Power'] ?? data['power'] ?? '',
                acceleration: data['Acceleration'] ?? data['acceleration'] ?? '',
                topSpeed: data['Top Speed'] ?? data['top_speed'] ?? '',
                engine: data['engine_detail'] ?? data['Engine'] ?? data['engine'] ?? 'No information',
                interior: data['interior'] ?? data['Interior & Features'] ?? 'No information',
                features: (data['features'] is List)
                  ? List<String>.from(data['features'])
                  : <String>[],
                description: data['description'] ?? data['Description'] ?? 'No description.',
              );
            } catch (e) {
              print('Error parsing response: $e');
              print('Response body: ${response.body}');
              throw Exception(AppConstants.errorMessages[langCode]!['invalid_response']);
            }
          } else if (response.statusCode >= 500) {
            lastError = Exception('${AppConstants.errorMessages[langCode]!['server_error']}: ${response.statusCode}');
            print('Server error: ${response.statusCode}');
          } else {
            throw Exception('${AppConstants.errorMessages[langCode]!['api_error']}: ${response.statusCode}');
          }
        } on TimeoutException {
          lastError = Exception(AppConstants.errorMessages[langCode]!['timeout']);
          print('Timeout on attempt ${retryCount + 1}');
        } on SocketException {
          lastError = Exception(AppConstants.errorMessages[langCode]!['connection_error']);
          print('Connection error on attempt ${retryCount + 1}');
        } catch (e) {
          lastError = Exception(e.toString());
          print('Error on attempt ${retryCount + 1}: $e');
        }

        retryCount++;
        if (retryCount <= AppConstants.maxRetries) {
          print('Retrying in ${AppConstants.retryDelaySeconds} second...');
          await Future.delayed(Duration(seconds: AppConstants.retryDelaySeconds));
        }
      }

      throw lastError ?? Exception(AppConstants.errorMessages[langCode]!['unknown_error']);
    } catch (e) {
      print('Final error: $e');
      throw Exception(e.toString());
    }
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
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/history');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch history: ${response.statusCode}');
    }
  }

  Future<List<CarModel>> fetchCollection([String collectionName = 'Favorites']) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/collection?name=$collectionName');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CarModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch collection: \\${response.statusCode}');
    }
  }
} 