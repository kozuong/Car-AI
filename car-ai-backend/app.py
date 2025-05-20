from flask import Flask, request, jsonify
import logging
from datetime import datetime
from app.config.config import Config
from app.config.translations import get_translation
from app.utils.image_processor import ImageProcessor
from app.services.gemini_service import GeminiService
from app.services.car_analyzer import CarAnalyzer
import re

# Configure logging
logging.basicConfig(
    level=getattr(logging, Config.LOG_LEVEL),
    format=Config.LOG_FORMAT
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
image_processor = ImageProcessor()
gemini_service = GeminiService()
car_analyzer = CarAnalyzer()

@app.route('/analyze_car', methods=['POST'])
def analyze_car():
    try:
        logger.info("Received analyze_car request")
        if not Config.GEMINI_API_KEY:
            logger.error("API key is not configured")
            return jsonify({"error": "API key is not configured"}), 500

        if 'image' not in request.files:
            logger.error("No image file provided")
            return jsonify({"error": get_translation('no_image', lang=request.form.get('lang', 'vi'), category='messages')}), 400
        image_file = request.files['image']
        if not image_file.filename:
            logger.error("No image file selected")
            return jsonify({"error": get_translation('no_image', lang=request.form.get('lang', 'vi'), category='messages')}), 400
        lang = request.form.get('lang', 'vi')
        logger.info(f"Language: {lang}")
        start_time = datetime.now()

        try:
            base64_image = image_processor.encode_image(image_file)
        except Exception as e:
            logger.error(f"Error encoding image: {str(e)}")
            error_msg = {
                'vi': "Lỗi xử lý ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Image processing failed. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400

        # Prompt for Gemini
        if lang == 'vi':
            language_instruction = "Chỉ trả lời bằng tiếng Việt, không dùng tiếng Anh, không giải thích thêm."
        else:
            language_instruction = "Only answer in English, do not use Vietnamese, do not add explanations."
        prompt = f"""Analyze this car image and {language_instruction} Use this EXACT format:\nBrand: (manufacturer name)\nModel: (model name)\nYear: (specific year or year range)\nPrice: (price range in USD)\nPerformance:\n- Power: (exact HP number or range)\n- 0-60 mph: (exact seconds)\n- Top Speed: (exact km/h)\n\nDescription:\nOverview:\n(Write 2-3 sentences about the car's overall characteristics)\n\nEngine Details:\n- Configuration: (engine type and layout)\n- Displacement: (in liters)\n- Turbo/Supercharging: (if applicable)\n- Transmission: (type and speeds)\n\nInterior & Features:\n- Seating: (material and configuration)\n- Dashboard: (key features)\n- Technology: (main tech features)\n- Key Features: (list 3-4 standout features)\n\nNote: Please maintain the exact format with proper line breaks and section headers."""

        try:
            content = gemini_service.analyze_image(base64_image, prompt)
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            error_msg = {
                'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Unable to analyze image. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400

        # Extract fields from response
        car_name, year, price, power, acceleration, top_speed, engine_detail, interior, description = car_analyzer.extract_fields(content)

        # Nếu lang là 'vi', dịch các trường sang tiếng Việt nếu cần
        if lang == 'vi':
            if description:
                print('Trước dịch description:', description)
                description = gemini_service.translate_text(description)
                print('Sau dịch description:', description)
            if engine_detail:
                print('Trước dịch engine_detail:', engine_detail)
                engine_detail = gemini_service.translate_text(engine_detail)
                print('Sau dịch engine_detail:', engine_detail)
            if interior:
                print('Trước dịch interior:', interior)
                interior = gemini_service.translate_text(interior)
                print('Sau dịch interior:', interior)

            # Thay thế nhãn kỹ thuật sang tiếng Việt
            TECH_LABELS = {
                "Configuration": "Cấu hình",
                "Displacement": "Dung tích xy-lanh",
                "Turbo/Supercharging": "Tăng áp/Siêu nạp",
                "Transmission": "Hộp số",
                "Seating": "Ghế ngồi",
                "Dashboard": "Bảng điều khiển",
                "Technology": "Công nghệ",
                "Key Features": "Tính năng chính"
            }
            def replace_labels(text):
                for en, vi in TECH_LABELS.items():
                    # Thay thế ở đầu dòng, có hoặc không có dấu hai chấm, không phân biệt hoa thường
                    text = re.sub(rf'(?im)^\s*{en}\s*:?\s*', vi + ': ', text)
                return text
            description = replace_labels(description)
            engine_detail = replace_labels(engine_detail)
            interior = replace_labels(interior)

        # Extract features
        features = []
        if interior:
            for line in interior.split('\n'):
                if '-' in line:
                    features.append(line.strip('- ').strip())

        # Prepare response data
        response_data = {
            "car_name": car_name,
            "brand": car_name.split(' ')[0] if car_name else '',
            "year": year,
            "price": price,
            "power": power,
            "acceleration": acceleration,
            "top_speed": top_speed,
            "engine_detail": engine_detail,
            "interior": interior,
            "features": features if features else ['Standard features available'],
            "description": description,
            "page_title": get_translation('analysis_result', lang=lang),
            "labels": {
                "car_name": get_translation('car_name', lang=lang, category='labels'),
                "brand": get_translation('brand', lang=lang, category='labels'),
                "year": get_translation('year', lang=lang, category='labels'),
                "price": get_translation('price', lang=lang, category='labels'),
                "power": get_translation('power', lang=lang, category='labels'),
                "acceleration": get_translation('acceleration', lang=lang, category='labels'),
                "top_speed": get_translation('top_speed', lang=lang, category='labels'),
                "engine_details": get_translation('engine_details', lang=lang, category='labels'),
                "interior_details": get_translation('interior_details', lang=lang, category='labels'),
                "features_list": get_translation('features_list', lang=lang, category='labels'),
                "description": get_translation('description', lang=lang, category='labels'),
                "processing_time": get_translation('processing_time', lang=lang, category='labels')
            }
        }

        # Ensure data completeness and language consistency
        response_data = car_analyzer.ensure_complete_data(response_data, car_name, lang)
        response_data = car_analyzer.ensure_language_consistency(response_data, lang)

        # Add processing time
        end_time = datetime.now()
        response_data["processing_time"] = (end_time - start_time).total_seconds()

        logger.info(f"Successfully processed request for {car_name}")
        return jsonify(response_data)

    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        error_msg = {
            'vi': "Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau.",
            'en': "An unexpected error occurred. Please try again later."
        }
        return jsonify({"error": error_msg.get(lang, str(e))}), 500

@app.route('/test_api', methods=['GET'])
def test_api():
    try:
        if not Config.GEMINI_API_KEY:
            return jsonify({"error": "API key is not configured"}), 500

        logger.info(f"Using API key: {Config.GEMINI_API_KEY[:5]}...{Config.GEMINI_API_KEY[-5:]}")
        prompt = "Hello, this is a test message."
        
        response = gemini_service.analyze_image(None, prompt)
        
        return jsonify({
            "status": "success",
            "response": response
        })
        
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=Config.DEBUG, host=Config.HOST, port=Config.PORT)
