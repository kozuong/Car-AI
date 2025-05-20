"""
Translation strings for the application
"""

TRANSLATIONS = {
    'vi': {
        'page_titles': {
            'analysis_result': 'Kết quả phân tích',
            'history': 'Lịch sử phân tích',
            'description': 'Mô tả',
            'engine': 'Động cơ',
            'interior': 'Nội thất',
            'features': 'Tính năng',
            'description_engine_interior_features': 'Mô tả, động cơ, nội thất & tính năng'
        },
        'labels': {
            'car_name': 'Tên xe',
            'brand': 'Hãng sản xuất',
            'year': 'Năm sản xuất',
            'price': 'Giá',
            'power': 'Công suất',
            'acceleration': 'Tăng tốc 0-100',
            'top_speed': 'Tốc độ tối đa',
            'engine_details': 'Chi tiết động cơ',
            'interior_details': 'Chi tiết nội thất',
            'features_list': 'Danh sách tính năng',
            'description': 'Mô tả',
            'processing_time': 'Thời gian xử lý'
        },
        'messages': {
            'no_image': 'Vui lòng chọn ảnh',
            'processing': 'Đang xử lý...',
            'error': 'Có lỗi xảy ra',
            'no_history': 'Chưa có lịch sử phân tích'
        }
    },
    'en': {
        'page_titles': {
            'analysis_result': 'Analysis Result',
            'history': 'Analysis History',
            'description': 'Description',
            'engine': 'Engine',
            'interior': 'Interior',
            'features': 'Features',
            'description_engine_interior_features': 'Description, Engine, Interior & Features'
        },
        'labels': {
            'car_name': 'Car Name',
            'brand': 'Brand',
            'year': 'Year',
            'price': 'Price',
            'power': 'Power',
            'acceleration': '0-100 Acceleration',
            'top_speed': 'Top Speed',
            'engine_details': 'Engine Details',
            'interior_details': 'Interior Details',
            'features_list': 'Features List',
            'description': 'Description',
            'processing_time': 'Processing Time'
        },
        'messages': {
            'no_image': 'Please select an image',
            'processing': 'Processing...',
            'error': 'An error occurred',
            'no_history': 'No analysis history'
        }
    }
}

def get_translation(key, lang='vi', category='page_titles'):
    """
    Get translation for a given key and language
    
    Args:
        key (str): Translation key
        lang (str): Language code ('vi' or 'en')
        category (str): Translation category ('page_titles', 'labels', or 'messages')
        
    Returns:
        str: Translated string or key if translation not found
    """
    try:
        return TRANSLATIONS.get(lang, TRANSLATIONS['en'])[category][key]
    except KeyError:
        return key 