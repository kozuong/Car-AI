import logging
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from ..config.config import Config

logger = logging.getLogger(__name__)

class GeminiService:
    def __init__(self):
        self.api_key = Config.GEMINI_API_KEY
        self.api_url = Config.GEMINI_API_URL
        self.session = self._create_session()

    def _create_session(self):
        """Create a session with retry mechanism"""
        session = requests.Session()
        retry_strategy = Retry(
            total=Config.MAX_RETRIES,
            backoff_factor=Config.RETRY_BACKOFF,
            status_forcelist=[429, 500, 502, 503, 504],
        )
        session.mount("https://", HTTPAdapter(max_retries=retry_strategy))
        return session

    def analyze_image(self, base64_image, prompt):
        """Analyze image using Gemini API"""
        try:
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

            response = self.session.post(
                self.api_url,
                params={"key": self.api_key},
                headers=headers,
                json=payload,
                timeout=Config.API_TIMEOUT
            )

            response.raise_for_status()
            result = response.json()

            if 'error' in result or 'candidates' not in result or not result['candidates']:
                raise ValueError("Invalid API response")

            return result["candidates"][0]["content"]["parts"][0]["text"]

        except Exception as e:
            logger.error(f"Error calling Gemini API: {str(e)}")
            raise

    def translate_text(self, text):
        """Translate text using Gemini API"""
        try:
            prompt = f"""Dịch đoạn văn sau sang tiếng Việt. Giữ nguyên định dạng, số liệu, đơn vị, tên hãng xe, và các thuật ngữ kỹ thuật. Nếu đoạn văn đã là tiếng Việt thì giữ nguyên, không dịch lại.\n\nĐoạn văn:\n{text}\n\nYêu cầu:\n1. Giữ nguyên tất cả số, đơn vị (hp, km/h, lít, v.v.)\n2. Giữ nguyên tên hãng xe\n3. Dịch toàn bộ mô tả, đặc điểm, tính năng sang tiếng Việt\n4. Giữ chính xác các thuật ngữ kỹ thuật\n5. Nếu đoạn văn đã là tiếng Việt thì trả về nguyên văn đó"""

            payload = {
                "contents": [{
                    "parts": [{"text": prompt}]
                }]
            }

            response = self.session.post(
                self.api_url,
                params={"key": self.api_key},
                json=payload,
                timeout=Config.API_TIMEOUT
            )

            response.raise_for_status()
            result = response.json()
            return result["candidates"][0]["content"]["parts"][0]["text"]

        except Exception as e:
            logger.error(f"Error translating text: {str(e)}")
            return text 