import requests
import json

def test_analyze_car():
    url = "http://localhost:8000/analyze_car"
    
    # Prepare the files and data
    files = {
        'image': ('test_car.jpg', open('test_car.jpg', 'rb'), 'image/jpeg')
    }
    data = {
        'lang': 'vi'
    }
    
    try:
        # Send POST request
        response = requests.post(url, files=files, data=data)
        
        # Check if request was successful
        response.raise_for_status()
        
        # Parse and print the response
        result = response.json()
        print("\nKết quả phân tích xe:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
        
    except requests.exceptions.RequestException as e:
        print(f"Lỗi khi gọi API: {str(e)}")
    finally:
        # Close the file
        files['image'][1].close()

if __name__ == "__main__":
    test_analyze_car() 