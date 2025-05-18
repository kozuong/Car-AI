class AppConstants {
  static const String apiBaseUrl = 'http://192.168.1.87:8000';
  static const String analyzeEndpoint = '/analyze_car';
  static const double maxImageSizeMB = 10.0;
  static const String historyKey = 'history';
  static const String languageKey = 'language';
  static const String defaultLanguage = 'vi';
  static const String collectionKey = 'collection';
  static const String collectionsKey = 'collections';
  static const int maxRetries = 2;
  static const int apiTimeoutSeconds = 20;
  static const int streamTimeoutSeconds = 20;
  static const int retryDelaySeconds = 2;

  static const Map<String, Map<String, String>> messages = {
    'vi': {
      'appName': 'Car AI Analyzer',
      'camera': 'Chụp ảnh',
      'collection': 'Bộ sưu tập',
      'history': 'Lịch sử',
      'all': 'Tất cả',
      'noHistory': 'Chưa có lịch sử phân tích',
      'clearHistory': '✅ Đã xóa lịch sử',
      'error': 'Có lỗi xảy ra',
      'noInternet': 'Không có kết nối internet',
      'analyzing': 'Đang phân tích...',
      'takePhoto': 'Chụp ảnh xe',
      'selectFromGallery': 'Chọn từ thư viện',
      'carDetails': 'Thông tin xe',
      'specifications': 'Thông số kỹ thuật',
      'features': 'Tính năng',
      'description': 'Mô tả',
      'share': 'Chia sẻ',
      'collectionTitle': 'Bộ sưu tập xe',
      'addToCollection': 'Thêm vào bộ sưu tập',
      'removeFromCollection': 'Xóa khỏi bộ sưu tập',
      'saveToCollection': 'Đã lưu vào bộ sưu tập',
      'removeFromCollectionSuccess': 'Đã xóa khỏi bộ sưu tập',
      'createCollection': 'Tạo bộ sưu tập mới',
      'collectionName': 'Tên bộ sưu tập',
      'collectionCreated': 'Đã tạo bộ sưu tập mới',
    },
    'en': {
      'appName': 'Car AI Analyzer',
      'camera': 'Camera',
      'collection': 'Collection',
      'history': 'History',
      'all': 'All',
      'noHistory': 'No analysis history yet',
      'clearHistory': '✅ History cleared',
      'error': 'An error occurred',
      'noInternet': 'No internet connection',
      'analyzing': 'Analyzing...',
      'takePhoto': 'Take car photo',
      'selectFromGallery': 'Select from gallery',
      'carDetails': 'Car Details',
      'specifications': 'Specifications',
      'features': 'Features',
      'description': 'Description',
      'share': 'Share',
      'collectionTitle': 'Car Collection',
      'addToCollection': 'Add to collection',
      'removeFromCollection': 'Remove from collection',
      'saveToCollection': 'Saved to collection',
      'removeFromCollectionSuccess': 'Removed from collection',
      'createCollection': 'Create new collection',
      'collectionName': 'Collection name',
      'collectionCreated': 'New collection created',
    },
  };

  static const Map<String, Map<String, String>> errorMessages = {
    'vi': {
      'file_too_large': 'File ảnh quá lớn.',
      'timeout': 'Quá thời gian chờ.',
      'invalid_response': 'Phản hồi không hợp lệ.',
      'server_error': 'Lỗi máy chủ',
      'api_error': 'Lỗi API',
      'connection_error': 'Lỗi kết nối',
      'unknown_error': 'Lỗi không xác định',
    },
    'en': {
      'file_too_large': 'Image file too large.',
      'timeout': 'Request timed out.',
      'invalid_response': 'Invalid response.',
      'server_error': 'Server error',
      'api_error': 'API error',
      'connection_error': 'Connection error',
      'unknown_error': 'Unknown error',
    }
  };
} 