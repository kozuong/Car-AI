# Car AI Backend

Backend service for Car AI application that provides image processing and AI analysis capabilities.

## Features

- Image upload and processing
- AI-powered car analysis
- RESTful API endpoints
- Secure file handling

## Prerequisites

- Python 3.11 or higher
- pip (Python package manager)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/your-username/car-ai-backend.git
cd car-ai-backend
```

2. Create and activate virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create .env file:
```bash
cp .env.example .env
```

## Configuration

Create a `.env` file in the root directory with the following variables:
```
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key
```

## Running the Application

1. Development mode:
```bash
flask run
```

2. Production mode:
```bash
gunicorn app:app
```

## API Endpoints

- `POST /upload`: Upload car image for analysis
- `GET /analyze/<image_id>`: Get analysis results for uploaded image
- `GET /health`: Health check endpoint

## Deployment

The application is configured for deployment on Render.com. The `render.yaml` file contains the necessary configuration.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.