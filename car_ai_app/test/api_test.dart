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
        print('Car Name: ${result.carName}');
        print('Year: ${result.year}');
        print('Price: ${result.price}');
        print('Power: ${result.power}');
        print('Acceleration: ${result.acceleration}');
        print('Top Speed: ${result.topSpeed}');
        print('Engine: ${result.engine}');
        print('Interior: ${result.interior}');
        print('Features: ${result.features}');
        print('Description: ${result.description}');
        
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