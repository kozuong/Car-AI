import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/car_model.dart';
import 'api_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _prefs = SharedPreferences.getInstance();

  Future<void> saveCarToHistory(CarModel car) async {
    try {
      final prefs = await _prefs;
      final historyJson = prefs.getString(AppConstants.historyKey) ?? '[]';
      
      // Validate car data
      if (car.carName.isEmpty) {
        throw Exception('Car name cannot be empty');
      }

      // Parse existing history
      List<Map<String, dynamic>> history;
      try {
        history = List<Map<String, dynamic>>.from(
          jsonDecode(historyJson) as List,
        );
      } catch (e) {
        // If history is invalid, start with empty list
        history = [];
      }

      // Add new car at the beginning of the list
      final carJson = car.toJson();
      history.insert(0, carJson);

      // Keep only the last 50 items
      if (history.length > 50) {
        history.removeRange(50, history.length);
      }

      // Convert to JSON and validate
      final newHistoryJson = jsonEncode(history);
      try {
        jsonDecode(newHistoryJson);
      } catch (e) {
        throw Exception('Invalid JSON format: $e');
      }
      
      // Save to SharedPreferences
      final success = await prefs.setString(AppConstants.historyKey, newHistoryJson);
      if (!success) {
        throw Exception('Failed to save history to SharedPreferences');
      }
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<List<CarModel>> getHistory() async {
    final prefs = await _prefs;
    final historyJson = prefs.getString(AppConstants.historyKey) ?? '[]';
    final List<dynamic> historyList = jsonDecode(historyJson);
    return historyList.map((e) => CarModel.fromJson(e)).toList();
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await _prefs;
      final success = await prefs.remove(AppConstants.historyKey);
      if (!success) {
        throw Exception('Failed to clear history from SharedPreferences');
      }
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> saveLanguage(String langCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(AppConstants.languageKey, langCode);
      if (!success) {
        throw Exception('Failed to save language to SharedPreferences');
      }
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<String> getLanguage() async {
    try {
      final prefs = await _prefs;
      return prefs.getString(AppConstants.languageKey) ?? AppConstants.defaultLanguage;
    } catch (e) {
      return AppConstants.defaultLanguage;
    }
  }

  Future<void> setLanguage(String langCode) async {
    try {
      final prefs = await _prefs;
      await prefs.setString(AppConstants.languageKey, langCode);
    } catch (e) {
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<void> saveCarToCollection(CarModel car, String collectionName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'collection_$collectionName';
    // Lấy collection hiện tại
    final collection = await getCollection(collectionName);
    // Nếu đã có thì ghi đè bằng bản mới nhất (ưu tiên bản mới nhất từ history)
    final existingIndex = collection.indexWhere((c) => c.imagePath == car.imagePath);
    if (existingIndex != -1) {
      collection[existingIndex] = car;
    } else {
      collection.insert(0, car);
    }
    final jsonList = collection.map((c) => c.toJson()).toList();
    await prefs.setString(key, jsonEncode(jsonList));
  }

  Future<List<CarModel>> getCollection(String collectionName) async {
    try {
      final prefs = await _prefs;
      final cleanName = collectionName.trim();
      final collectionKey = '${AppConstants.collectionKey}_$cleanName';
      final collectionJson = prefs.getString(collectionKey) ?? '[]';
      
      // Parse collection
      List<Map<String, dynamic>> collection;
      try {
        collection = List<Map<String, dynamic>>.from(
          jsonDecode(collectionJson) as List,
        );
      } catch (e) {
        return [];
      }

      // Convert to CarModel list
      return collection.map((json) => CarModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFromCollection(CarModel car, String collectionName) async {
    try {
      final prefs = await _prefs;
      final collectionKey = '${AppConstants.collectionKey}_$collectionName';
      final collectionJson = prefs.getString(collectionKey) ?? '[]';
      
      // Parse collection
      List<Map<String, dynamic>> collection;
      try {
        collection = List<Map<String, dynamic>>.from(
          jsonDecode(collectionJson) as List,
        );
      } catch (e) {
        return;
      }

      // Remove car from collection
      collection.removeWhere((item) => 
        item['carName'] == car.carName && 
        item['brand'] == car.brand
      );

      // If collection is empty, remove it completely
      if (collection.isEmpty) {
        // Remove from collections list
        final collectionsJson = prefs.getString(AppConstants.collectionsKey) ?? '[]';
        List<String> collections;
        try {
          collections = List<String>.from(jsonDecode(collectionsJson));
          collections.remove(collectionName);
          await prefs.setString(AppConstants.collectionsKey, jsonEncode(collections));
        } catch (e) {
          return;
        }
        // Remove the collection key itself
        await prefs.remove(collectionKey);
      } else {
        // Save updated collection if not empty
        final newCollectionJson = jsonEncode(collection);
        await prefs.setString(collectionKey, newCollectionJson);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getCollectionNames() async {
    try {
      final prefs = await _prefs;
      final collectionsJson = prefs.getString(AppConstants.collectionsKey) ?? '[]';
      
      List<String> collections;
      try {
        collections = List<String>.from(jsonDecode(collectionsJson));
      } catch (e) {
        collections = [];
      }

      return collections;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addCollection(String collectionName) async {
    try {
      final prefs = await _prefs;
      final collectionsJson = prefs.getString(AppConstants.collectionsKey) ?? '[]';
      List<String> collections;
      try {
        collections = List<String>.from(jsonDecode(collectionsJson));
      } catch (e) {
        collections = [];
      }
      if (!collections.contains(collectionName)) {
        collections.add(collectionName);
        await prefs.setString(AppConstants.collectionsKey, jsonEncode(collections));
      }
      // Đảm bảo luôn có key collection dạng collectionKey_collectionName
      final collectionKey = '${AppConstants.collectionKey}_$collectionName';
      if (!prefs.containsKey(collectionKey)) {
        await prefs.setString(collectionKey, '[]');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getAllBrandCollections() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final brandKeys = keys.where((k) => k.startsWith('${AppConstants.collectionKey}_')).toList();
    return brandKeys
      .map((k) => k.replaceFirst('${AppConstants.collectionKey}_', '').trim())
      .where((name) => name.isNotEmpty && !name.contains(RegExp(r'[\\/:*?"<>|]')))
      .toList();
  }

  Future<void> removeFromHistory(CarModel car) async {
    final prefs = await _prefs;
    final historyJson = prefs.getString(AppConstants.historyKey) ?? '[]';
    List<Map<String, dynamic>> history;
    try {
      history = List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);
    } catch (e) {
      history = [];
    }
    history.removeWhere((item) =>
      (item['timestamp'] != null && car.timestamp != null && item['timestamp'] == car.timestamp) ||
      (item['carName'] == car.carName && item['brand'] == car.brand)
    );
    await prefs.setString(AppConstants.historyKey, jsonEncode(history));
  }

  Future<void> removeCollection(String collectionName) async {
    final prefs = await _prefs;
    final collectionKey = '${AppConstants.collectionKey}_$collectionName';
    await prefs.remove(collectionKey);
  }
} 