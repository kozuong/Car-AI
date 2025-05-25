from flask import Flask, request, jsonify
from flask_cors import CORS
import logging
from datetime import datetime
from app.config.config import Config
from app.config.translations import get_translation
from app.utils.image_processor import ImageProcessor
from app.services.gemini_service import GeminiService
from app.services.car_analyzer import CarAnalyzer
from app.services.google_custom_search_service import GoogleCustomSearchService
import re
import io
import sys
from PIL import Image
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from app.utils.car_utils import get_default_logo, average_year, average_price
import requests
import time
import copy
from concurrent.futures import ThreadPoolExecutor

# Configure logging
logging.basicConfig(
    level=getattr(logging, Config.LOG_LEVEL),
    format=Config.LOG_FORMAT,
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('app.log', encoding='utf-8')
    ]
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

# Initialize rate limiter
limiter = Limiter(
    app=app,
    key_func=get_remote_address,
    default_limits=["200 per day", "50 per hour"]
)

# Enable CORS with more specific configuration
CORS(app, resources={
    r"/*": {
        "origins": ["*"],  # In production, replace with specific origins
        "methods": ["GET", "POST", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Request-ID"],
        "expose_headers": ["Content-Type", "X-Request-ID"],
        "supports_credentials": True,
        "max_age": 3600
    }
})

# Set default encoding for the application
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

# Define prompts
PROMPT_EN = '''Analyze this car image and Only answer in English, do not use Vietnamese, do not add explanations. Use this EXACT format:
Brand: (manufacturer name)
Model: (model name)
Year: (specific year or year range)
Price: (price range in USD)
Performance:
- Power: (exact HP number or range)
- 0-60 mph: (exact seconds)
- Top Speed: (exact km/h)

Description:
Overview:
(Write a DETAILED and comprehensive overview of the car, at least 3-5 sentences, including design, driving experience, technology, and unique selling points. DO NOT leave this blank.)

Engine Details:
- Configuration: (engine type and layout)
- Displacement: (in liters)
- Turbo/Supercharging: (if applicable)
- Transmission: (type and speeds)
(Write a DETAILED paragraph about the engine, including technology, fuel type, performance, and any special features. DO NOT leave this blank.)

Interior & Features:
- Seating: (material and configuration)
- Dashboard: (key features)
- Technology: (main tech features)
- Key Features: (list 3-4 standout features)
(Write a DETAILED paragraph about the interior, comfort, technology, and features. DO NOT leave this blank.)

Note: Please maintain the exact format with proper line breaks and section headers. If any section is missing, REPEAT the prompt and DO NOT answer until all sections are filled in detail.'''

PROMPT_VI = '''Phân tích ảnh xe này và chỉ trả lời bằng tiếng Việt, không dùng tiếng Anh, không giải thích thêm. Trả về đúng format này:
Hãng: (tên hãng)
Mẫu xe: (tên mẫu xe)
Năm sản xuất: (năm hoặc khoảng năm)
Giá: (khoảng giá USD)
Hiệu năng:
- Công suất: (số HP hoặc khoảng)
- Tăng tốc 0-100 km/h: (số giây)
- Tốc độ tối đa: (km/h)

Mô tả:
Tổng quan:
(Viết một đoạn tổng quan CHI TIẾT, tối thiểu 3-5 câu, về thiết kế, trải nghiệm lái, công nghệ, điểm nổi bật. KHÔNG được để trống.)

Chi tiết động cơ:
- Cấu hình: (loại động cơ, bố trí)
- Dung tích: (lít)
- Tăng áp/Supercharge: (nếu có)
- Hộp số: (loại và số cấp)
(Viết một đoạn văn CHI TIẾT về động cơ, công nghệ, nhiên liệu, hiệu suất, điểm đặc biệt. KHÔNG được để trống.)

Nội thất & Tính năng:
- Ghế ngồi: (chất liệu, cấu hình)
- Taplo: (tính năng chính)
- Công nghệ: (tính năng công nghệ chính)
- Tính năng nổi bật: (liệt kê 3-4 tính năng nổi bật)
(Viết một đoạn văn CHI TIẾT về nội thất, tiện nghi, công nghệ, cảm giác sử dụng, các tính năng nổi bật. KHÔNG được để trống.)

Lưu ý: Nếu thiếu bất kỳ section nào, hãy LẶP LẠI prompt và KHÔNG trả lời cho đến khi điền đủ, đúng format, đúng hướng dẫn.'''

# Initialize services
try:
    image_processor = ImageProcessor()
    gemini_service = GeminiService()
    car_analyzer = CarAnalyzer()
    google_search_service = GoogleCustomSearchService()
    logger.info("Successfully initialized all services")
except Exception as e:
    logger.error(f"Failed to initialize services: {str(e)}")
    raise

# Validate configuration
try:
    Config.validate()
    logger.info("Configuration validated successfully")
except ValueError as e:
    logger.error(f"Configuration validation failed: {str(e)}")
    raise

# Simple in-memory cache for logo and number_produced
logo_cache = {}
number_produced_cache = {}

def build_result(fields, lang, price=None, number_produced=None, rarity=None, engine_detail=None, interior=None, features=None, description=None, logo_url=None, fallback_fields=None):
    """Build the result dictionary from extracted fields"""
    try:
        # Lấy car_name từ fields hoặc tạo từ brand và model
        car_name = fields.get('car_name', '')
        if not car_name:
            brand = fields.get('brand', '')
            model = fields.get('model', '')
            if brand and model:
                car_name = f"{brand} {model}"
                logger.info(f"[Car Name] Created car_name from brand and model: {car_name}")
        # Cải thiện việc trích xuất brand name
        brand = ''
        if car_name:
            parts = car_name.split()
            if parts:
                if len(parts) > 1 and parts[0].lower() in ['mercedes', 'alfa']:
                    brand = f"{parts[0]}-{parts[1]}"
                else:
                    brand = parts[0]
                brand = brand.title()
                logger.info(f"[Brand] Successfully extracted brand name: {brand} from car_name: {car_name}")
            else:
                logger.warning(f"[Brand] Failed to extract brand name from empty car_name")
        else:
            logger.warning("[Brand] No car_name provided in fields")
        year = fields.get('year', '')
        year = average_year(year)
        power = fields.get('power', '')
        acceleration = fields.get('acceleration', '')
        top_speed = fields.get('top_speed', '')
        translations = get_translation(lang)
        # Cải thiện logic xử lý description
        logger.info(f"[Description] Starting description processing for {car_name}")
        desc = description
        if not desc or len(desc.strip()) < 50:
            desc = fields.get('description', '')
        if isinstance(desc, list):
            desc = ' '.join(desc)
            logger.debug(f"[Description] Joined list description, length: {len(desc)}")
        # Kiểm tra và lấy description từ các nguồn khác nhau
        if not desc or len(desc.strip()) < 100:  # Đảm bảo description có độ dài tối thiểu
            logger.info("[Description] Description too short or empty, trying alternative sources")
            # Thử lấy đoạn văn dài nhất trong text nếu có
            paragraphs = [p.strip() for p in fields.get('raw_text', '').split('\n') if len(p.strip()) >= 100 and ':' not in p]
            if paragraphs:
                desc = max(paragraphs, key=len)
                logger.info("[Description] Using longest paragraph from raw_text")
            # Thử lấy từ overview
            if (not desc or len(desc.strip()) < 100) and 'overview' in fields:
                overview = fields.get('overview', '')
                if isinstance(overview, list):
                    overview = ' '.join(overview)
                if overview and len(overview.strip()) >= 100:
                    desc = overview
                    logger.info("[Description] Using overview as description")
            # Nếu vẫn không có, thử lấy từ final_description
            if (not desc or len(desc.strip()) < 100) and 'final_description' in fields:
                final_description = fields.get('final_description', '')
                if final_description and len(final_description.strip()) >= 100:
                    desc = final_description
                    logger.info("[Description] Using final_description")
            # Nếu vẫn không có, tạo description mặc định
            if not desc or len(desc.strip()) < 100:
                if car_name and year and power and top_speed:
                    desc = f"The {car_name} ({year}) is a remarkable vehicle known for its performance and features. With {power} of power and a top speed of {top_speed}, it offers an impressive driving experience. This model combines advanced technology with sophisticated design, making it a standout in its class."
                    logger.info("[Description] Using generated default description with available data")
                else:
                    desc = "A detailed description is not available for this vehicle at the moment."
                    logger.warning("[Description] Using minimal default description due to missing data")
        
        logger.info(f"[Description] Final description length: {len(desc)}")
        
        # Xử lý logo - tối ưu hóa để đảm bảo luôn có logo
        if not logo_url and brand:
            try:
                # Kiểm tra cấu hình Google Search API
                if not hasattr(Config, 'GOOGLE_SEARCH_API_KEY') or not hasattr(Config, 'GOOGLE_SEARCH_CX'):
                    logger.error("[Logo] Google Search API configuration missing")
                    logo_url = None
                else:
                    # Thử lấy logo với cache
                    logo_key = brand.lower().strip()
                    if logo_key in logo_cache:
                        logo_url = logo_cache[logo_key]
                        logger.info(f"[Logo][Cache] Hit for {logo_key}: {logo_url}")
                    else:
                        max_retries = 3
                        for attempt in range(max_retries):
                            logo_url = get_default_logo(brand)
                            if logo_url:
                                logger.info(f"[Logo] Successfully found logo URL for {brand} on attempt {attempt + 1}")
                                logo_cache[logo_key] = logo_url
                                break
                            logger.warning(f"[Logo] Failed to find logo URL for {brand} on attempt {attempt + 1}")
                            if attempt < max_retries - 1:
                                time.sleep(1)  # Wait before retry
            except Exception as e:
                error_msg = str(e)
                logger.error(f"[Logo] Error during logo search: {error_msg}")
                logo_url = None
        elif not brand:
            logger.warning("[Logo] Skipping logo search due to missing brand name")
        
        # Giá trung bình cộng nếu là khoảng
        price_val = price or fields.get('price', '')
        price_val = average_price(price_val)
        
        # Xử lý đơn vị number_produced theo ngôn ngữ
        number_produced_val = number_produced or fields.get('number_produced', '')
        if lang == 'vi' and number_produced_val:
            number_produced_val = number_produced_val.replace('units/year', 'xe/năm').replace('units', 'xe').replace('unit', 'xe').replace('per year', 'xe/năm')
        elif lang == 'en' and number_produced_val:
            number_produced_val = number_produced_val.replace('xe/năm', 'units/year').replace('xe', 'units')
        
        # Tạo kết quả
        result = {
            "car_name": car_name,
            "brand": brand,
            "year": year,
            "price": price_val,
            "power": power,
            "acceleration": acceleration,
            "top_speed": top_speed,
            "description": desc if lang == 'en' else (description if description else "Mô tả chưa khả dụng bằng tiếng Việt."),
            "engine_detail": engine_detail if engine_detail is not None else fields.get('engine_detail', ''),
            "interior": interior if interior is not None else fields.get('interior', ''),
            "features": features or fields.get('features', []),
            "number_produced": number_produced_val,
            "rarity": rarity or fields.get('rarity', ''),
            "logo_url": logo_url
        }
        
        # Thêm các trường bổ sung
        if lang == 'vi':
            result.update({
                "car_name_vi": fields.get('car_name', ''),
                "brand_vi": fields.get('brand', ''),
                "model_vi": fields.get('model', ''),
                "description_vi": fields.get('description', ''),
                "engine_detail_vi": fields.get('engine_detail', ''),
                "interior_vi": fields.get('interior', ''),
                "features_vi": fields.get('features', [])
            })
        
        return result
        
    except Exception as e:
        logger.error(f"Error in build_result: {str(e)}", exc_info=True)
        raise

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Check if services are initialized
        if not all([image_processor, gemini_service, car_analyzer, google_search_service]):
            return jsonify({"status": "error", "message": "Services not initialized"}), 500
            
        # Check if API keys are configured
        if not Config.GEMINI_API_KEY:
            return jsonify({"status": "error", "message": "GEMINI_API_KEY not configured"}), 500
            
        return jsonify({
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "services": {
                "image_processor": "initialized",
                "gemini_service": "initialized",
                "car_analyzer": "initialized",
                "google_search_service": "initialized"
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({"status": "error", "message": str(e)}), 500

@app.route('/analyze_car', methods=['POST'])
@limiter.limit("10 per minute")
def analyze_car():
    try:
        logger.info("=== Starting analyze_car request ===")
        start_time = datetime.now()
        logger.info(f"Request method: {request.method}")
        logger.info(f"Request headers: {dict(request.headers)}")
        logger.info(f"Request files: {list(request.files.keys())}")
        logger.info(f"Request form: {request.form}")
        
        # Kiểm tra API key
        if not Config.GEMINI_API_KEY:
            logger.error("API key is not configured")
            return jsonify({
                "status": "error",
                "message": "API key is not configured",
                "error": "Vui lòng cấu hình API key"
            }), 500

        # Kiểm tra file ảnh
        if 'image' not in request.files:
            logger.error("No image file provided in request")
            return jsonify({
                "status": "error",
                "message": "No image provided",
                "error": "Vui lòng chọn ảnh để phân tích"
            }), 400
        
        image_file = request.files['image']
        logger.info(f"Received image file: {image_file.filename}")
        logger.info(f"Image file content type: {image_file.content_type}")
        
        # Đọc kích thước file
        try:
            file_size = len(image_file.read())
            image_file.seek(0)  # Reset file pointer
            logger.info(f"Image file size: {file_size} bytes")
        except Exception as e:
            logger.error(f"Error reading file size: {str(e)}")
            return jsonify({
                "status": "error",
                "message": "Error reading file",
                "error": "Không thể đọc file ảnh"
            }), 400
        
        # Kiểm tra file trống
        if not image_file or not image_file.filename:
            logger.error("Empty image file received")
            return jsonify({
                "status": "error",
                "message": "Empty file",
                "error": "File ảnh trống"
            }), 400
            
        # Kiểm tra định dạng file
        allowed_extensions = {'png', 'jpg', 'jpeg', 'gif'}
        file_ext = image_file.filename.rsplit('.', 1)[1].lower() if '.' in image_file.filename else ''
        logger.info(f"File extension: {file_ext}")
        
        if file_ext not in allowed_extensions:
            logger.error(f"Invalid file type: {image_file.filename}")
            return jsonify({
                "status": "error",
                "message": "Invalid file type",
                "error": "Định dạng file không hợp lệ. Vui lòng sử dụng ảnh PNG, JPG, JPEG hoặc GIF."
            }), 400

        # Kiểm tra kích thước file
        if file_size > 10 * 1024 * 1024:  # 10MB
            logger.error(f"File too large: {file_size} bytes")
            return jsonify({
                "status": "error",
                "message": "File too large",
                "error": "Kích thước file quá lớn. Vui lòng sử dụng ảnh nhỏ hơn 10MB."
            }), 400

        # Xử lý ảnh
        try:
            logger.info("Starting image processing...")
            # Resize ảnh trước khi encode (max 800px)
            image_file.seek(0)
            img = Image.open(image_file)
            img.thumbnail((800, 800))
            buf = io.BytesIO()
            img.save(buf, format=img.format or 'JPEG')
            buf.seek(0)
            base64_image, error_message = image_processor.encode_image(buf)
            if not base64_image:
                logger.error(f"Image processing failed: {error_message}")
                return jsonify({
                    "status": "error",
                    "message": "Image processing failed",
                    "error": error_message or "Không thể xử lý ảnh"
                }), 400
            logger.info("Successfully processed image")
        except Exception as e:
            logger.error(f"Error processing image: {str(e)}", exc_info=True)
            return jsonify({
                "status": "error",
                "message": "Error processing image",
                "error": "Lỗi xử lý ảnh. Vui lòng thử lại."
            }), 400
        t_gemini_start = time.time()
        # Phân tích ảnh với Gemini
        try:
            logger.info("Starting image analysis...")
            with ThreadPoolExecutor(max_workers=2) as executor:
                future_en = executor.submit(gemini_service.analyze_image, base64_image, PROMPT_EN)
                future_vi = executor.submit(gemini_service.analyze_image, base64_image, PROMPT_VI)
                content_en = future_en.result()
                content_vi = future_vi.result()
            logger.info("Successfully analyzed image")
        except Exception as e:
            logger.error(f"Error analyzing image: {str(e)}")
            return jsonify({
                "status": "error",
                "message": "Error analyzing image",
                "error": "Không thể phân tích ảnh. Vui lòng thử lại."
            }), 400
        t_gemini_end = time.time()
        # Trích xuất thông tin
        try:
            logger.info("Extracting fields...")
            t_extract_start = time.time()
            fields_en = car_analyzer.extract_fields(content_en)
            fields_vi = car_analyzer.extract_fields(content_vi)
            logger.info("Successfully extracted fields")
            t_extract_end = time.time()
            logger.info(f"[PERF] Extract fields: {t_extract_end - t_extract_start:.2f}s")
            
            # Trích xuất fields từ raw text
            def extract_from_text(text):
                import re  # Import re ở đây để đảm bảo có thể sử dụng trong hàm
                fields = {}
                # Bắt các trường dạng markdown hoặc bullet cho tiếng Việt, có hoặc không có ngoặc
                vi_patterns = [
                    (r'-?\s*\*\*Hãng( \(Brand\))?\*\*:?\s*([\w\s-]+)', 'brand'),
                    (r'-?\s*\*\*Tên mẫu xe( \(Model\))?\*\*:?\s*([\w\s-]+)', 'model'),
                    (r'-?\s*\*\*Năm sản xuất( \(Year\))?\*\*:?\s*([\w\s-]+)', 'year'),
                    (r'-?\s*\*\*Giá( \(Price\))?\*\*:?\s*([\w\s\$\-,]+)', 'price'),
                    (r'-?\s*\*\*Công suất( \(Power\))?\*\*:?\s*([\w\s-]+)', 'power'),
                    (r'-?\s*\*\*Tăng tốc( \(Acceleration\))?\*\*:?\s*([\w\s-]+)', 'acceleration'),
                    (r'-?\s*\*\*Tốc độ tối đa( \(Top speed\))?\*\*:?\s*([\w\s-]+)', 'top_speed'),
                ]
                for pattern, key in vi_patterns:
                    m = re.search(pattern, text, re.IGNORECASE)
                    if m:
                        # Lấy group cuối cùng, loại bỏ ký tự thừa
                        value = m.groups()[-1].strip('* ').strip()
                        fields[key] = value
                lines = text.split('\n')
                current_key = None
                buffer = []
                section_headers = []
                for idx, line in enumerate(lines):
                    line = line.strip()
                    if not line:
                        continue
                    # Section headers (EN & VI)
                    if line.lower().startswith('engine details:') or line.lower().startswith('chi tiết động cơ:'):
                        current_key = 'engine_detail'
                        buffer = []
                        section_headers.append(idx)
                        continue
                    elif line.lower().startswith('interior & features:') or line.lower().startswith('nội thất & tính năng:'):
                        if current_key and buffer:
                            fields[current_key] = ' '.join(buffer).strip()
                        current_key = 'interior'
                        buffer = []
                        section_headers.append(idx)
                        continue
                    elif re.match(r'^[A-Za-zÀ-ỹ ]+:$', line):
                        # Gặp section mới, lưu lại section trước
                        if current_key and buffer:
                            fields[current_key] = ' '.join(buffer).strip()
                        current_key = None
                        buffer = []
                        section_headers.append(idx)
                    # Key-value
                    if ':' in line and not line.startswith('- '):
                        key, value = line.split(':', 1)
                        key = key.strip().lower()
                        value = value.strip()
                        if key in ['brand', 'hãng', 'tên hãng']:
                            fields['brand'] = value
                        elif key in ['model', 'mẫu xe', 'tên mẫu xe']:
                            fields['model'] = value
                        elif key in ['year', 'năm']:
                            fields['year'] = value
                        elif key in ['price', 'giá']:
                            fields['price'] = value
                        elif key in ['overview', 'tổng quan', 'mô tả']:
                            fields['description'] = value
                        elif key in ['power', 'công suất']:
                            fields['power'] = value
                        elif key in ['acceleration', '0-100 km/h', 'tăng tốc']:
                            fields['acceleration'] = value
                        elif key in ['top speed', 'tốc độ tối đa']:
                            fields['top_speed'] = value
                        elif key in ['number produced', 'số lượng sản xuất']:
                            fields['number_produced'] = value
                        elif key in ['rarity', 'độ hiếm']:
                            fields['rarity'] = value
                        elif key in ['configuration', 'cấu hình']:
                            buffer.append(line)
                            current_key = 'engine_detail'
                        elif key in ['seating', 'ghế ngồi']:
                            buffer.append(line)
                            current_key = 'interior'
                        elif key in ['key features', 'tính năng nổi bật']:
                            fields['features'] = [f.strip() for f in value.split(',')]
                    elif line.startswith('- '):
                        # Performance lines
                        if 'power' in line.lower() or 'công suất' in line.lower():
                            fields['power'] = line.split(':', 1)[1].strip() if ':' in line else line.replace('- Power', '').replace('- Công suất', '').strip()
                        elif '0-60' in line.lower() or '0-100' in line.lower() or 'tăng tốc' in line.lower():
                            fields['acceleration'] = line.split(':', 1)[1].strip() if ':' in line else line.replace('- 0-60 mph', '').replace('- 0-100 km/h', '').replace('- Tăng tốc', '').strip()
                        elif 'top speed' in line.lower() or 'tốc độ tối đa' in line.lower():
                            fields['top_speed'] = line.split(':', 1)[1].strip() if ':' in line else line.replace('- Top Speed', '').replace('- Tốc độ tối đa', '').strip()
                        elif current_key:
                            buffer.append(line)
                    elif current_key:
                        buffer.append(line)
                # Lưu section cuối cùng
                if current_key and buffer:
                    fields[current_key] = ' '.join(buffer).strip()
                # Ưu tiên lấy section Tổng quan cho tiếng Việt
                if 'Tổng quan:' in text:
                    pattern = r"Tổng quan:\s*(.+?)\n(?:Chi tiết động cơ|Nội thất & Tính năng|$)"
                    match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
                    if match:
                        fields['description'] = match.group(1).strip()
                # Ưu tiên lấy section Overview cho tiếng Anh nếu có
                elif 'Overview:' in text:
                    pattern = r"Overview:\s*(.+?)\n(?:Engine Details|Interior & Features|$)"
                    match = re.search(pattern, text, re.DOTALL | re.IGNORECASE)
                    if match:
                        fields['description'] = match.group(1).strip()
                # Nếu không có, fallback như cũ
                if 'description' not in fields or not fields['description']:
                    # Xác định vị trí section đầu tiên
                    lines = text.split('\n')
                    section_headers = []
                    for idx, line in enumerate(lines):
                        if re.match(r'^[A-Za-zÀ-ỹ ]+:$', line.strip()):
                            section_headers.append(idx)
                    first_section = section_headers[0] if section_headers else len(lines)
                    candidate = []
                    for i in range(first_section):
                        l = lines[i].strip()
                        if l and not re.match(r'^[A-Za-zÀ-ỹ ]+:$', l):
                            candidate.append(l)
                    if candidate:
                        fields['description'] = ' '.join(candidate)
                # Nếu các trường dài bị rỗng, lấy đoạn văn dài nhất không phải section header
                for long_key in ['engine_detail', 'interior', 'description']:
                    if not fields.get(long_key):
                        paragraphs = [p.strip() for p in text.split('\n') if len(p.strip()) >= 100 and ':' not in p]
                        if paragraphs:
                            fields[long_key] = max(paragraphs, key=len)
                # Lưu lại raw_text để build_result dùng
                fields['raw_text'] = text
                return fields
            
            # Trích xuất fields từ raw text
            fields_en_dict = extract_from_text(content_en)
            fields_vi_dict = extract_from_text(content_vi)
            
            # Chỉ giữ lại log kết quả trích xuất
            logger.info(f"[Fields] Extracted fields (EN): {safe_log_result(fields_en_dict)}")
            logger.info(f"[Fields] Extracted fields (VI): {safe_log_result(fields_vi_dict)}")
            
            # Tạo car_name từ brand và model
            brand_en = fields_en_dict.get('brand', '').strip()
            model_en = fields_en_dict.get('model', '').strip()
            brand_vi = fields_vi_dict.get('brand', '').strip()
            model_vi = fields_vi_dict.get('model', '').strip()
            
            logger.info(f"[Fields] Brand (EN): {brand_en}, Model (EN): {model_en}")
            logger.info(f"[Fields] Brand (VI): {brand_vi}, Model (VI): {model_vi}")
            
            car_name_en = f"{brand_en} {model_en}".strip()
            car_name_vi = f"{brand_vi} {model_vi}".strip()
            
            if not car_name_en:
                logger.warning("[Fields] Failed to create car_name_en from brand and model")
            if not car_name_vi:
                logger.warning("[Fields] Failed to create car_name_vi from brand and model")
                
            fields_en_dict['car_name'] = car_name_en
            fields_vi_dict['car_name'] = car_name_vi
            
            logger.info(f"[Fields] Created car_name (EN): {car_name_en}")
            logger.info(f"[Fields] Created car_name (VI): {car_name_vi}")
            
            # Lấy thông tin từ fields
            price = fields_en_dict.get('avg_price', fields_en_dict.get('price', ''))
            engine_detail = fields_en_dict.get('engine_detail', '')
            interior = fields_en_dict.get('interior', '')
            features = fields_en_dict.get('features', [])
            description = fields_en_dict.get('description', '')
            number_produced = fields_en_dict.get('number_produced', '')
            rarity = fields_en_dict.get('rarity', '')
            logo_url = None  # Khởi tạo logo_url

            # === Lấy số lượng sản xuất (number_produced) ===
            number_produced_val = number_produced or fields_en_dict.get('number_produced', '')
            logger.info(f"[NumberProduced] Initial value: {number_produced_val}")
            max_number = None
            # Cache number_produced theo car_name_en
            cache_key = car_name_en.lower().strip()
            if cache_key in number_produced_cache:
                number_produced_val = number_produced_cache[cache_key]
                logger.info(f"[NumberProduced][Cache] Hit for {cache_key}: {number_produced_val}")
            else:
                t_google_start = time.time()
                if number_produced_val:
                    numbers = [int(n) for n in re.findall(r'\d+', str(number_produced_val).replace(',', ''))]
                    filtered_numbers = [n for n in numbers if not (1900 <= n <= 2030)]
                    if filtered_numbers:
                        max_number = filtered_numbers[0]
                if max_number is None:
                    try:
                        queries = [
                            f"{car_name_en} production numbers",
                            f"{car_name_en} total produced",
                            f"{car_name_en} units built"
                        ]
                        google_response = None
                        for q in queries:
                            google_response = google_search_service.search_number_produced(q)
                            logger.info(f"[NumberProduced][GoogleSearch] Query: {q} | Response: {safe_log_result(google_response, max_length=100)}")
                            if google_response and isinstance(google_response, str) and google_response.strip():
                                numbers = re.findall(r'\d+', google_response.replace(',', ''))
                                if numbers:
                                    try:
                                        max_number = int(numbers[0])
                                        number_produced_val = f"{max_number:,} units"
                                        logger.info(f"[NumberProduced][GoogleSearch] Extracted: {number_produced_val}")
                                        break
                                    except Exception as e:
                                        logger.warning(f"[NumberProduced][GoogleSearch] Failed to parse number: {numbers[0]} | Error: {e}")
                                        max_number = None
                        if max_number is None:
                            gemini_prompt = f"What is the total number of {car_name_en} produced? Please provide a specific number or range."
                            gemini_response = gemini_service.analyze_image(None, gemini_prompt)
                            logger.info(f"[NumberProduced][Gemini] Response: {safe_log_result(gemini_response, max_length=100)}")
                            if gemini_response and isinstance(gemini_response, str) and gemini_response.strip():
                                numbers = re.findall(r'\d+', gemini_response.replace(',', ''))
                                if numbers:
                                    try:
                                        max_number = int(numbers[0])
                                        number_produced_val = f"{max_number:,} units"
                                        logger.info(f"[NumberProduced][Gemini] Extracted: {number_produced_val}")
                                    except Exception as e:
                                        logger.warning(f"[NumberProduced][Gemini] Failed to parse number: {numbers[0]} | Error: {e}")
                                        max_number = None
                                else:
                                    number_produced_val = gemini_response.strip()
                                    logger.info(f"[NumberProduced][Gemini] Using full response: {safe_log_result(number_produced_val, max_length=100)}")
                            else:
                                number_produced_val = "Production numbers not available"
                                logger.info(f"[NumberProduced] No data from Gemini. Using default: {safe_log_result(number_produced_val, max_length=100)}")
                    except Exception as e:
                        logger.error(f"[NumberProduced] Error in Google/Gemini: {str(e)}")
                        number_produced_val = "Production numbers not available"
                t_google_end = time.time()
                logger.info(f"[PERF] Google Search: {t_google_end - t_google_start:.2f}s")
                # Lưu cache
                number_produced_cache[cache_key] = number_produced_val
            # === Tính rarity ===
            rarity_str = car_analyzer.calculate_rarity(str(number_produced_val))
            logger.info(f"[Rarity] max_number: {max_number}, rarity_str: {rarity_str}")
            # Cập nhật vào fields_en_dict
            fields_en_dict['number_produced'] = number_produced_val
            fields_en_dict['rarity'] = rarity_str

            # === Fallback các trường số liệu từ EN sang VI nếu VI bị rỗng ===
            fallback_keys = ['year', 'power', 'acceleration', 'top_speed', 'price', 'number_produced', 'rarity']
            for key in fallback_keys:
                if not fields_vi_dict.get(key):
                    fields_vi_dict[key] = fields_en_dict.get(key, '')

            # === Lọc tiếng Anh cho các trường mô tả dài tiếng Việt ===
            def is_mostly_english(text):
                if not text or not isinstance(text, str):
                    return False
                words = text.split()
                en_words = [w for w in words if re.match(r'^[a-zA-Z0-9\-\.,:;]+$', w)]
                return len(en_words) / max(1, len(words)) > 0.5

            for key in ['engine_detail', 'interior']:
                vi_val = fields_vi_dict.get(key, '')
                if vi_val and is_mostly_english(vi_val):
                    fields_vi_dict[key] = ''

            # Tách description tiếng Việt và tiếng Anh riêng biệt
            description_en = fields_en_dict.get('description', '')
            description_vi = fields_vi_dict.get('description', '')
            engine_detail_en = fields_en_dict.get('engine_detail', '')
            engine_detail_vi = fields_vi_dict.get('engine_detail', '')
            interior_en = fields_en_dict.get('interior', '')
            interior_vi = fields_vi_dict.get('interior', '')

            # Nếu engine_detail_vi còn là tiếng Anh, reset lại
            if is_mostly_english(engine_detail_vi):
                engine_detail_vi = ''
                logger.info("[Engine Detail VI] Removed English fallback for engine_detail_vi")
            # Nếu sau khi reset vẫn rỗng, không nên fallback sang tiếng Anh
            if not engine_detail_vi:
                engine_detail_vi = ''
            # Áp dụng tương tự cho interior_vi nếu muốn
            if is_mostly_english(interior_vi):
                interior_vi = ''
                logger.info("[Interior VI] Removed English fallback for interior_vi")
            if not interior_vi:
                interior_vi = ''

            # Nếu description_vi là tiếng Anh, cố gắng trích xuất section 'Tổng quan' từ content_vi
            if is_mostly_english(description_vi):
                logger.warning("[Description VI] Detected as English. Trying to extract 'Tổng quan' manually.")
                try:
                    pattern = r"Tổng quan:\s*(.+?)\n(?:Chi tiết động cơ|Nội thất & Tính năng|$)"
                    match = re.search(pattern, content_vi, re.DOTALL | re.IGNORECASE)
                    if match:
                        description_vi = match.group(1).strip()
                        logger.info("[Description VI] Successfully extracted from 'Tổng quan' section.")
                    else:
                        description_vi = "Mô tả chưa khả dụng bằng tiếng Việt."
                except Exception as e:
                    logger.error(f"[Description VI] Failed to extract 'Tổng quan': {str(e)}")
                    description_vi = "Mô tả chưa khả dụng bằng tiếng Việt."

            t_build_result_start = time.time()
            try:
                # Tạo kết quả cho cả tiếng Anh và tiếng Việt
                result_en = build_result(fields_en_dict, 'en', price, number_produced_val, rarity_str, engine_detail_en, interior_en, features, description_en, logo_url)
                result_vi = build_result(fields_vi_dict, 'vi', price, number_produced_val, rarity_str, engine_detail_vi, interior_vi, features, description_vi, logo_url)
                t_build_result_end = time.time()
                logger.info(f"[PERF] Build result: {t_build_result_end - t_build_result_start:.2f}s")
                # Thêm thời gian xử lý
                end_time = datetime.now()
                processing_time = (end_time - start_time).total_seconds()
                # Chuẩn bị phản hồi
                response_data = {
                    "status": "success",
                    "message": "Successfully analyzed car",
                    "result_en": result_en,
                    "result_vi": result_vi,
                    "image_processed": True,
                    "processing_time": processing_time
                }
                # Thêm log chi tiết trước khi trả response
                logger.debug(f"[API_RESPONSE] result_en: {safe_log_result(result_en, max_length=100)}")
                logger.debug(f"[API_RESPONSE] result_vi: {safe_log_result(result_vi, max_length=100)}")
                logger.debug(f"[API_RESPONSE] Brand EN: {result_en.get('brand')}, Brand VI: {result_vi.get('brand')}")
                logger.debug(f"[API_RESPONSE] Rarity EN: {result_en.get('rarity')}, Rarity VI: {result_vi.get('rarity')}")
                logger.debug(f"[API_RESPONSE] Number Produced EN: {result_en.get('number_produced')}, Number Produced VI: {result_vi.get('number_produced')}")
                logger.info(f"[PERF] Gemini: {t_gemini_end - t_gemini_start:.2f}s | Total: {processing_time:.2f}s")
                # Kiểm tra các trường quan trọng tiếng Việt
                required_vi = ['brand', 'model', 'car_name']
                missing_vi = [k for k in required_vi if not fields_vi_dict.get(k)]
                if missing_vi:
                    logger.error(f"[API] Thiếu trường tiếng Việt: {missing_vi}")
                    return jsonify({
                        "status": "error",
                        "message": f"Thiếu trường tiếng Việt: {', '.join(missing_vi)}. Vui lòng thử lại với ảnh rõ hơn hoặc prompt khác.",
                        "error": "missing_vi_fields"
                    }), 422
                return jsonify(response_data)
            except Exception as e:
                logger.error(f"Error creating response: {str(e)}", exc_info=True)
                return jsonify({
                    "status": "error",
                    "message": "Error creating response",
                    "error": "Lỗi khi tạo phản hồi. Vui lòng thử lại."
                }), 500
            
        except Exception as e:
            logger.error(f"Error creating response: {str(e)}", exc_info=True)
            return jsonify({
                "status": "error",
                "message": "Error creating response",
                "error": "Lỗi khi tạo phản hồi. Vui lòng thử lại."
            }), 500
            
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}", exc_info=True)
        return jsonify({
            "status": "error",
            "message": "Unexpected error",
            "error": "Đã xảy ra lỗi không mong muốn. Vui lòng thử lại sau."
        }), 500
    finally:
        logger.info("=== End of analyze_car request ===")

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

@app.route('/test_logo_search', methods=['GET'])
def test_logo_search():
    brand = request.args.get('brand', default='Toyota')
    try:
        logo_url = get_default_logo(brand)
        if logo_url:
            return jsonify({"status": "success", "brand": brand, "logo_url": logo_url})
        else:
            return jsonify({"status": "fail", "brand": brand, "logo_url": None, "message": "No logo found"}), 404
    except Exception as e:
        return jsonify({"status": "error", "brand": brand, "error": str(e)}), 500

@app.route('/test_number_produced', methods=['GET'])
def test_number_produced():
    car_name = request.args.get('car_name', default='Toyota Corolla Hatchback')
    try:
        result = google_search_service.search_number_produced(car_name)
        return jsonify({"status": "success", "car_name": car_name, "number_produced_results": result})
    except Exception as e:
        logger.error(f"[TestNumberProduced] Error: {str(e)}")
        return jsonify({"status": "error", "car_name": car_name, "error": str(e)}), 500

def safe_log_result(result, max_length=100):
    if isinstance(result, dict):
        result_copy = {}
        for k, v in result.items():
            if isinstance(v, (dict, list)):
                result_copy[k] = safe_log_result(v, max_length)
            elif isinstance(v, str) and (len(v) > max_length or 'base64' in k or v.startswith('data:image')):
                result_copy[k] = '[omitted]'
            else:
                result_copy[k] = v
        return result_copy
    elif isinstance(result, list):
        return [safe_log_result(item, max_length) for item in result]
    else:
        return result

if __name__ == '__main__':
    try:
        logger.info(f"Starting server on {Config.HOST}:{Config.PORT}")
        app.run(
            host=Config.HOST,
            port=Config.PORT,
            debug=Config.DEBUG,
            threaded=True
        )
    except Exception as e:
        logger.error(f"Failed to start server: {str(e)}")
        raise
