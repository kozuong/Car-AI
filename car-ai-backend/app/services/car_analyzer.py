import logging
from datetime import datetime
from .gemini_service import GeminiService

logger = logging.getLogger(__name__)

class CarAnalyzer:
    def __init__(self):
        self.gemini_service = GeminiService()

    def extract_fields(self, text):
        """Extract car information from text"""
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
            return (
                "Unknown Car", "N/A", "N/A",
                "N/A", "N/A", "N/A",
                "No engine details available.", "No interior details available.",
                "Unable to extract detailed information from the image."
            )

    def ensure_complete_data(self, data, car_name, lang):
        """Ensure all required data is present and in correct language"""
        try:
            # Check and research engine details if missing
            if not data.get('engine_detail') or data['engine_detail'].strip() in ['N/A', '', 'No engine details available.', 'Không có thông tin động cơ.']:
                engine_info = self.gemini_service.analyze_image(None, f"Research engine specifications for {car_name}")
                if lang == 'vi':
                    engine_info = self.gemini_service.translate_text(engine_info)
                data['engine_detail'] = engine_info

            # Check and research interior if missing
            if not data.get('interior') or data['interior'] == 'N/A' or data['interior'] == 'No interior details available.':
                interior_info = self.gemini_service.analyze_image(None, f"Research interior features for {car_name}")
                if lang == 'vi':
                    interior_info = self.gemini_service.translate_text(interior_info)
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

    def ensure_language_consistency(self, data, lang):
        """Ensure all text fields are in the correct language"""
        try:
            if lang == 'vi':
                # Translate all text fields to Vietnamese
                fields_to_translate = ['description', 'engine_detail', 'interior']
                for field in fields_to_translate:
                    if field in data and data[field]:
                        data[field] = self.gemini_service.translate_text(data[field])
                
                # Translate features list
                if 'features' in data and isinstance(data['features'], list):
                    data['features'] = [self.gemini_service.translate_text(feature) for feature in data['features']]
            
            return data

        except Exception as e:
            logger.error(f"Error ensuring language consistency: {str(e)}")
            return data 