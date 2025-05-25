class AppConstants {
  static const String apiBaseUrl = 'http://192.168.1.87:5000';
  static const String analyzeEndpoint = '/analyze_car';
  static const double maxImageSizeMB = 10.0;
  static const String historyKey = 'history';
  static const String languageKey = 'language';
  static const String defaultLanguage = 'en';
  static const String collectionKey = 'collection';
  static const String collectionsKey = 'collections';
  static const int maxRetries = 2;
  static const int apiTimeoutSeconds = 20;
  static const int streamTimeoutSeconds = 20;
  static const int retryDelaySeconds = 2;

  static const Map<String, Map<String, String>> errorMessages = {
    'vi': {
      'no_internet': 'Không có kết nối internet. Vui lòng kiểm tra lại kết nối của bạn.',
      'file_too_large': 'Ảnh quá lớn. Vui lòng chọn ảnh nhỏ hơn 10MB.',
      'invalid_response': 'Không thể phân tích ảnh. Vui lòng thử lại.',
      'server_error': 'Lỗi máy chủ. Vui lòng thử lại sau.',
      'timeout': 'Quá thời gian chờ. Vui lòng thử lại.',
      'rate_limit': 'Quá nhiều yêu cầu. Vui lòng đợi một chút.',
      'invalid_format': 'Định dạng file không được hỗ trợ. Vui lòng sử dụng JPG, PNG hoặc GIF.',
      'retry_failed': 'Không thể phân tích ảnh sau nhiều lần thử. Vui lòng thử lại sau.',
    },
    'en': {
      'no_internet': 'No internet connection. Please check your connection.',
      'file_too_large': 'Image too large. Please choose an image smaller than 10MB.',
      'invalid_response': 'Could not analyze image. Please try again.',
      'server_error': 'Server error. Please try again later.',
      'timeout': 'Request timed out. Please try again.',
      'rate_limit': 'Too many requests. Please wait a moment.',
      'invalid_format': 'Unsupported file format. Please use JPG, PNG or GIF.',
      'retry_failed': 'Failed to analyze image after multiple attempts. Please try again later.',
    },
  };

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
      'noHistory': 'No analysis history',
      'clearHistory': '✅ History cleared',
      'error': 'An error occurred',
      'noInternet': 'No internet connection',
      'analyzing': 'Analyzing...',
      'takePhoto': 'Take Car Photo',
      'selectFromGallery': 'Select from Gallery',
      'carDetails': 'Car Details',
      'specifications': 'Specifications',
      'features': 'Features',
      'description': 'Description',
      'share': 'Share',
      'collectionTitle': 'Car Collection',
      'addToCollection': 'Add to Collection',
      'removeFromCollection': 'Remove from Collection',
      'saveToCollection': 'Saved to Collection',
      'removeFromCollectionSuccess': 'Removed from Collection',
      'createCollection': 'Create New Collection',
      'collectionName': 'Collection Name',
      'collectionCreated': 'New collection created',
    },
  };
} 