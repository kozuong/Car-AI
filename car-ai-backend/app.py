from flask import Flask, request, jsonify
import base64
import os
import re
import io
import requests
from PIL import Image
from dotenv import load_dotenv
import logging
from datetime import datetime
import json

# Configure logging with more detail
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Load API key từ biến môi trường
load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")
logger.info(f"Loaded API key: {api_key[:5]}...{api_key[-5:] if api_key else 'None'}")

app = Flask(__name__)

# Resize ảnh và mã hóa base64
def encode_image(image_file, max_size=512):
    try:
        # Đọc và kiểm tra kích thước file
        image_file.seek(0, os.SEEK_END)
        original_size = image_file.tell()
        image_file.seek(0)
        logger.info(f"Original file size: {original_size / 1024:.2f}KB")

        if original_size > 10 * 1024 * 1024:  # 10MB limit
            raise ValueError("File size exceeds 10MB limit")

        # Đọc ảnh
        image = Image.open(image_file)
        logger.info(f"Original image size: {image.size}, mode: {image.mode}")

        # Chuyển đổi sang RGB nếu cần
        if image.mode != 'RGB':
            logger.info(f"Converting image from {image.mode} to RGB")
            image = image.convert('RGB')

        # Tính toán kích thước mới
        if max(image.size) > max_size:
            ratio = max_size / max(image.size)
            new_size = tuple(int(dim * ratio) for dim in image.size)
            logger.info(f"Resizing image from {image.size} to {new_size}")
            image = image.resize(new_size, Image.Resampling.LANCZOS)

        # Nén ảnh với chất lượng tự động điều chỉnh
        quality = 85
        buffer = io.BytesIO()
        while True:
            buffer.seek(0)
            buffer.truncate()
            image.save(buffer, format='JPEG', quality=quality, optimize=True)
            size = buffer.tell()
            logger.info(f"Compressed size with quality {quality}: {size / 1024:.2f}KB")
            
            if size <= 800 * 1024 or quality <= 30:  # Giới hạn 800KB
                break
                
            quality -= 10

        buffer.seek(0)
        base64_data = base64.b64encode(buffer.read()).decode("utf-8")
        logger.info(f"Final base64 size: {len(base64_data) / 1024:.2f}KB")
        return base64_data

    except Exception as e:
        logger.error(f"Error encoding image: {str(e)}")
        raise

def research_missing_info(car_name, missing_fields, lang='en'):
    """Research missing information using Gemini API"""
    try:
        # Tạo prompt cho việc research
        field_names = {
            'interior': 'interior features and materials',
            'engine': 'engine specifications',
            'features': 'key features and technologies',
            'power': 'horsepower and performance specs',
            'acceleration': '0-60 mph acceleration time',
            'top_speed': 'top speed',
            'price': 'price range',
            'year': 'model year'
        }
        
        fields_str = ', '.join(field_names[f] for f in missing_fields)
        
        prompt = f"""Research and provide accurate information about the {car_name}'s {fields_str}.
        Format the response exactly like this:
        Interior: (detailed interior features including materials, comfort features, technology)
        Engine: (detailed engine specifications)
        Features: (key features and technologies)
        Performance:
        - Power: (horsepower)
        - 0-60 mph: (acceleration time)
        - Top Speed: (maximum speed)
        Price: (price in USD)
        Year: (model year)

        Provide only the fields requested. Keep responses professional and factual."""

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        headers = {
            "Content-Type": "application/json"
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        content = result["candidates"][0]["content"]["parts"][0]["text"]
        
        # Parse researched information
        researched_fields = extract_fields(content)
        logger.info(f"Successfully researched missing information for {car_name}")
        return researched_fields
        
    except Exception as e:
        logger.error(f"Error researching information: {str(e)}")
        return None

def research_engine_info(car_name):
    """Research engine information using Gemini API"""
    try:
        prompt = f"""Research and provide detailed engine specifications for {car_name}. Include:
- Engine type and configuration
- Displacement
- Power output
- Transmission
- Fuel type
- Any special features or technologies

Format the response in bullet points."""

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
            params={"key": api_key},
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        engine_info = result["candidates"][0]["content"]["parts"][0]["text"]
        
        # Format the response
        bullet_points = [point.strip() for point in engine_info.split('\n') if point.strip().startswith('-')]
        if not bullet_points:
            bullet_points = ["- " + line.strip() for line in engine_info.split('\n') if line.strip()]
        
        return '\n'.join(bullet_points)
    except Exception as e:
        logger.error(f"Error researching engine info: {str(e)}")
        return "- Engine information not available"

def research_interior_info(car_name):
    """Research interior information using Gemini API"""
    try:
        prompt = f"""Research and provide detailed interior features and specifications for {car_name}. Include:
- Seating materials and configuration
- Dashboard features
- Technology and infotainment
- Comfort features
- Safety features
- Storage solutions

Format the response in bullet points."""

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
            params={"key": api_key},
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        interior_info = result["candidates"][0]["content"]["parts"][0]["text"]
        
        # Format the response
        bullet_points = [point.strip() for point in interior_info.split('\n') if point.strip().startswith('-')]
        if not bullet_points:
            bullet_points = ["- " + line.strip() for line in interior_info.split('\n') if line.strip()]
        
        return '\n'.join(bullet_points)
    except Exception as e:
        logger.error(f"Error researching interior info: {str(e)}")
        return "- Interior information not available"

def ensure_language_consistency(data, lang):
    """Ensure all text fields are in the correct language"""
    try:
        if lang == 'vi':
            # Translate all text fields to Vietnamese
            fields_to_translate = ['description', 'engine_detail', 'interior']
            for field in fields_to_translate:
                if field in data and data[field]:
                    data[field] = translate_to_vietnamese(data[field])
            
            # Translate features list
            if 'features' in data and isinstance(data['features'], list):
                data['features'] = [translate_to_vietnamese(feature) for feature in data['features']]
        
        return data
    except Exception as e:
        logger.error(f"Error ensuring language consistency: {str(e)}")
        return data

def ensure_complete_data(data, car_name, lang):
    try:
        # Check and research engine details if missing or invalid
        if (not data.get('engine_detail') or data['engine_detail'].strip() in ['N/A', '', 'No engine details available.', 'Không có thông tin động cơ.']):
            engine_info = research_engine_info(car_name)
            if not engine_info or engine_info.strip() in ['N/A', '', 'No engine details available.']:
                engine_info = 'Không có thông tin động cơ.' if lang == 'vi' else 'No engine information available.'
            if lang == 'vi' and engine_info:
                engine_info = translate_to_vietnamese(engine_info)
            data['engine_detail'] = engine_info

        # Check and research interior if missing
        if not data.get('interior') or data['interior'] == 'N/A' or data['interior'] == 'No interior details available.':
            interior_info = research_interior_info(car_name)
            if lang == 'vi':
                interior_info = translate_to_vietnamese(interior_info)
            data['interior'] = interior_info

        # Ensure features list exists
        if 'features' not in data or not data['features']:
            data['features'] = ['- Standard features available']

        # Ensure description exists
        if not data.get('description') or data['description'] == 'N/A' or data['description'] == 'No detailed description available.':
            data['description'] = f"Detailed information about {car_name}"

        return data
    except Exception as e:
        logger.error(f"Error ensuring complete data: {str(e)}")
        return data

# Trích xuất các trường từ phản hồi
def extract_fields(text):
    try:
        fields = {
            "brand": "", "model": "", "year": "",
            "price": "", "power": "", "acceleration": "",
            "top_speed": "", "description": {
                "overview": [],
                "engine": [],
                "interior": []
            }
        }

        current_field = None
        current_section = None
        
        lines = text.strip().splitlines()
        in_description = False
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
                
            # Check for main field headers and section headers
            if line.endswith(':'):
                header = line[:-1].lower()
                if header == "description":
                    in_description = True
                    current_field = "description"
                elif header == "performance":
                    in_description = False
                    current_field = "performance"
                elif in_description:
                    if "overview" in header:
                        current_section = "overview"
                    elif "engine" in header:
                        current_section = "engine"
                    elif "interior" in header or "features" in header:
                        current_section = "interior"
                continue
                
            # Handle performance metrics
            if current_field == "performance":
                if "power:" in line.lower():
                    fields["power"] = line.split(":", 1)[1].strip()
                elif "0-60" in line.lower() or "0-100" in line.lower():
                    fields["acceleration"] = line.split(":", 1)[1].strip()
                elif "top speed" in line.lower():
                    fields["top_speed"] = line.split(":", 1)[1].strip()
                continue
                
            # Handle other fields
            if ":" in line and not line.startswith('-'):
                try:
                    key, value = line.split(":", 1)
                    key = key.strip().lower()
                    value = value.strip()
                    
                    if "brand" in key:
                        fields["brand"] = value
                    elif "model" in key:
                        fields["model"] = value
                    elif "year" in key:
                        fields["year"] = value
                    elif "price" in key:
                        fields["price"] = value
                except:
                    continue
            elif in_description:
                # Handle description sections
                if current_section == "overview" and not line.startswith('-'):
                    fields["description"]["overview"].append(line)
                elif line.startswith('-'):
                    if current_section == "engine":
                        fields["description"]["engine"].append(line.strip('- '))
                    elif current_section == "interior":
                        fields["description"]["interior"].append(line.strip('- '))

        # Construct formatted description
        description_parts = []
        engine_detail = ""
        interior = ""
        
        if fields["description"]["overview"]:
            overview = " ".join(fields["description"]["overview"]).strip()
            if overview:
                description_parts.append(overview)
        
        if fields["description"]["engine"]:
            engine_detail = "\n".join(fields["description"]["engine"])
        
        if fields["description"]["interior"]:
            interior = "\n".join(fields["description"]["interior"])

        final_description = "\n".join(description_parts)

        car_name = f"{fields['brand']} {fields['model']}".strip()
        if not car_name:
            car_name = "Unknown Car"

        # Ensure all required fields have at least a default value
        return (
            car_name, 
            fields["year"] or "N/A", 
            fields["price"] or "N/A",
            fields["power"] or "N/A", 
            fields["acceleration"] or "N/A", 
            fields["top_speed"] or "N/A",
            engine_detail or "No engine details available.",
            interior or "No interior details available.",
            final_description or "No detailed description available."
        )
    except Exception as e:
        logger.error(f"Error in extract_fields: {str(e)}")
        # Return default values if extraction fails
        return (
            "Unknown Car", "N/A", "N/A",
            "N/A", "N/A", "N/A",
            "No engine details available.", "No interior details available.",
            "Unable to extract detailed information from the image."
        )

def translate_to_vietnamese(text):
    """Translate text to Vietnamese using Gemini API"""
    try:
        prompt = f"""Translate the following text to Vietnamese. Keep all numbers, units, and technical specifications unchanged:

{text}

Translation rules:
1. Keep all numbers and units (hp, km/h, etc) unchanged
2. Keep car brand names unchanged
3. Translate all descriptions and features to Vietnamese
4. Keep technical terms accurate"""

        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        response = requests.post(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
            params={"key": api_key},
            json=payload,
            timeout=20
        )
        
        response.raise_for_status()
        result = response.json()
        translated = result["candidates"][0]["content"]["parts"][0]["text"]
        return translated
    except Exception as e:
        logger.error(f"Error translating to Vietnamese: {str(e)}")
        return text

@app.route('/analyze_car', methods=['POST'])
def analyze_car():
    try:
        logger.info("Received analyze_car request")
        if not api_key:
            logger.error("API key is not configured")
            return jsonify({"error": "API key is not configured"}), 500

        if 'image' not in request.files:
            logger.error("No image file provided")
            return jsonify({"error": "No image file provided"}), 400
        image_file = request.files['image']
        if not image_file.filename:
            logger.error("No image file selected")
            return jsonify({"error": "No image file selected"}), 400
        lang = request.form.get('lang', 'vi')
        logger.info(f"Language: {lang}")
        start_time = datetime.now()
        try:
            base64_image = encode_image(image_file, max_size=512)
        except Exception as e:
            logger.error(f"Error encoding image: {str(e)}")
            error_msg = {
                'vi': "Lỗi xử lý ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Image processing failed. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400

        session = requests.Session()
        retries = 3
        backoff_factor = 0.5
        retry_strategy = requests.adapters.Retry(
            total=retries,
            backoff_factor=backoff_factor,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        session.mount("https://", requests.adapters.HTTPAdapter(max_retries=retry_strategy))

        # Prompt cho Gemini
        prompt = f"""Analyze this car image and provide the following information in this EXACT format:\nBrand: (manufacturer name)\nModel: (model name)\nYear: (specific year or year range)\nPrice: (price range in USD)\nPerformance:\n- Power: (exact HP number or range)\n- 0-60 mph: (exact seconds)\n- Top Speed: (exact km/h)\n\nDescription:\nOverview:\n(Write 2-3 sentences about the car's overall characteristics)\n\nEngine Details:\n- Configuration: (engine type and layout)\n- Displacement: (in liters)\n- Turbo/Supercharging: (if applicable)\n- Transmission: (type and speeds)\n\nInterior & Features:\n- Seating: (material and configuration)\n- Dashboard: (key features)\n- Technology: (main tech features)\n- Key Features: (list 3-4 standout features)\n\nNote: Please maintain the exact format with proper line breaks and section headers."""

        payload = {
            "contents": [{
                "parts": [
                    {"text": prompt},
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": base64_image
                        }
                    }
                ]
            }]
        }
        headers = {"Content-Type": "application/json"}
        logger.info("Sending request to Gemini API")
        response = session.post(
            "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent",
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=(3, 15)
        )
        if response.status_code != 200:
            logger.error(f"API Error: {response.status_code} - {response.text}")
            error_msg = {
                'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Unable to analyze image. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400
        result = response.json()
        if 'error' in result or 'candidates' not in result or not result['candidates']:
            logger.error("No candidates in Gemini API response")
            error_msg = {
                'vi': "Không thể phân tích ảnh. Vui lòng thử lại với ảnh khác.",
                'en': "Unable to analyze image. Please try with a different image."
            }
            return jsonify({"error": error_msg[lang]}), 400
        content = result["candidates"][0]["content"]["parts"][0]["text"]
        logger.info("Extracting fields from response")
        # Trích xuất các trường
        car_name, year, price, power, acceleration, top_speed, engine_detail, interior, description = extract_fields(content)
        # Tách các phần mô tả
        features = []
        # Tách features nếu có
        if interior:
            for line in interior.split('\n'):
                if '-' in line:
                    features.append(line.strip('- ').strip())
        # Nếu thiếu engine_detail hoặc interior thì research
        if not engine_detail or 'không có thông tin' in engine_detail.lower() or 'no information' in engine_detail.lower():
            engine_detail = research_engine_info(car_name)
            if lang == 'vi':
                engine_detail = translate_to_vietnamese(engine_detail)
        if not interior or 'không có thông tin' in interior.lower() or 'no information' in interior.lower():
            interior = research_missing_info(car_name, ['interior'], lang=lang)
            if isinstance(interior, dict):
                interior = interior.get('interior', '')
            if lang == 'vi' and interior:
                interior = translate_to_vietnamese(interior)
        # Nếu thiếu mô tả thì tạo mô tả ngắn
        if not description or 'không có mô tả' in description.lower() or 'no description' in description.lower():
            description = f"{car_name} {year} {price} {power} {acceleration} {top_speed}"
            if lang == 'vi':
                description = translate_to_vietnamese(description)
        # Dịch toàn bộ sang tiếng Việt nếu cần
        if lang == 'vi':
            description = translate_to_vietnamese(description)
        # Đảm bảo không có trường nào rỗng hoặc N/A
        def clean_field(val):
            return val if val and val != 'N/A' else (translate_to_vietnamese('Không có thông tin') if lang == 'vi' else 'No information')
        response_data = {
            "car_name": clean_field(car_name),
            "brand": clean_field(car_name.split(' ')[0] if car_name else ''),
            "year": clean_field(year),
            "price": clean_field(price),
            "power": clean_field(power),
            "acceleration": clean_field(acceleration),
            "top_speed": clean_field(top_speed),
            "engine_detail": clean_field(engine_detail),
            "interior": clean_field(interior),
            "features": features if features else [clean_field('')],
            "description": clean_field(description)
        }

        # Ensure all data is complete and in the correct language
        response_data = ensure_complete_data(response_data, car_name, lang)
        response_data = ensure_language_consistency(response_data, lang)

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
        if not api_key:
            return jsonify({"error": "API key is not configured"}), 500

        logger.info(f"Using API key: {api_key}")
        prompt = "Hello, this is a test message."
        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }

        headers = {
            "Content-Type": "application/json"
        }

        # Sử dụng API endpoint từ AI Studio
        api_url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"
        logger.info(f"Calling API URL: {api_url}")
        
        response = requests.post(
            api_url,
            params={"key": api_key},
            headers=headers,
            json=payload,
            timeout=10
        )
        
        if response.status_code != 200:
            logger.error(f"API Error: {response.status_code} - {response.text}")
            return jsonify({"error": f"API Error: {response.status_code} - {response.text}"}), 500
        
        result = response.json()
        logger.info(f"API Response: {result}")
        
        if 'error' in result:
            return jsonify({"error": result['error']}), 500
            
        if 'candidates' not in result or not result['candidates']:
            return jsonify({"error": "No response from API"}), 500
            
        return jsonify({
            "status": "success",
            "response": result["candidates"][0]["content"]["parts"][0]["text"]
        })
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        return jsonify({"error": str(e)}), 500
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
