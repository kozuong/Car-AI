import base64
import io
import logging
from PIL import Image
from ..config.config import Config

logger = logging.getLogger(__name__)

class ImageProcessor:
    @staticmethod
    def encode_image(image_file, max_size=Config.MAX_IMAGE_SIZE):
        """Process and encode image to base64"""
        try:
            # Check file size
            image_file.seek(0, io.SEEK_END)
            original_size = image_file.tell()
            image_file.seek(0)
            logger.info(f"Original file size: {original_size / 1024:.2f}KB")

            if original_size > Config.MAX_FILE_SIZE:
                raise ValueError("File size exceeds limit")

            # Read and process image
            image = Image.open(image_file)
            logger.info(f"Original image size: {image.size}, mode: {image.mode}")

            # Convert to RGB if needed
            if image.mode != 'RGB':
                logger.info(f"Converting image from {image.mode} to RGB")
                image = image.convert('RGB')

            # Resize if needed
            if max(image.size) > max_size:
                ratio = max_size / max(image.size)
                new_size = tuple(int(dim * ratio) for dim in image.size)
                logger.info(f"Resizing image from {image.size} to {new_size}")
                image = image.resize(new_size, Image.Resampling.LANCZOS)

            # Compress with auto quality adjustment
            quality = 85
            buffer = io.BytesIO()
            while True:
                buffer.seek(0)
                buffer.truncate()
                image.save(buffer, format='JPEG', quality=quality, optimize=True)
                size = buffer.tell()
                logger.info(f"Compressed size with quality {quality}: {size / 1024:.2f}KB")
                
                if size <= Config.MAX_COMPRESSED_SIZE or quality <= 30:
                    break
                    
                quality -= 10

            buffer.seek(0)
            base64_data = base64.b64encode(buffer.read()).decode("utf-8")
            logger.info(f"Final base64 size: {len(base64_data) / 1024:.2f}KB")
            return base64_data

        except Exception as e:
            logger.error(f"Error encoding image: {str(e)}")
            raise 