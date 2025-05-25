import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../lib/services/api_service.dart';
import '../lib/config/constants.dart';

void main() {
  group('API Performance Test', () {
    test('Test API response time with test_car.jpg', () async {
      // Load test image
      final imageFile = File('test_car.jpg');
      if (!await imageFile.exists()) {
        fail('Test image file not found');
      }

      // Measure API call time
      final stopwatch = Stopwatch()..start();
      
      try {
        final api = ApiService();
        final result = await api.analyzeCarImage(imageFile, 'en');
        
        stopwatch.stop();
        print('API Response Time: ${stopwatch.elapsedMilliseconds}ms');
        print('Response Data:');
        safePrintResult(result);
        
        // Verify response time is within acceptable range
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Less than 10 seconds
      } catch (e) {
        stopwatch.stop();
        print('Error occurred after ${stopwatch.elapsedMilliseconds}ms');
        print('Error: $e');
        rethrow;
      }
    });
  });
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