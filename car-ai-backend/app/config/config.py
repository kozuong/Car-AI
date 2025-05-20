import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    # API Configuration
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent"
    
    # Image Processing
    MAX_IMAGE_SIZE = 512  # pixels
    MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB
    MAX_COMPRESSED_SIZE = 800 * 1024  # 800KB
    
    # API Settings
    API_TIMEOUT = (3, 15)  # (connect timeout, read timeout)
    MAX_RETRIES = 3
    RETRY_BACKOFF = 0.5
    
    # Logging
    LOG_LEVEL = "DEBUG"
    LOG_FORMAT = '%(asctime)s - %(levelname)s - %(message)s'
    
    # Server
    HOST = '0.0.0.0'
    PORT = 8000
    DEBUG = True 