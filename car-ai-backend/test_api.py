import requests
import json

def test_analyze_car():
    url = 'http://127.0.0.1:5000/analyze_car'
    
    # Open the test image file
    with open('test_car.jpg', 'rb') as image_file:
        files = {'image': ('test_car.jpg', image_file, 'image/jpeg')}
        data = {'lang': 'vi'}  # Test with Vietnamese language
        
        try:
            response = requests.post(url, files=files, data=data)
            print(f"Status Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print("\nResponse Data:")
                print(json.dumps(safe_print_result(result), indent=2, ensure_ascii=False))
                
                # Specifically check number_produced
                print("\nNumber Produced:", result.get('number_produced', 'Not found'))
            else:
                print("Error:", response.text)
                
        except Exception as e:
            print(f"Error occurred: {str(e)}")

def safe_print_result(result, max_length=100):
    if isinstance(result, dict):
        result_copy = {}
        for k, v in result.items():
            if isinstance(v, (dict, list)):
                result_copy[k] = safe_print_result(v, max_length)
            elif isinstance(v, str) and (len(v) > max_length or 'base64' in k or v.startswith('data:image')):
                result_copy[k] = '[omitted]'
            else:
                result_copy[k] = v
        return result_copy
    elif isinstance(result, list):
        return [safe_print_result(item, max_length) for item in result]
    else:
        return result

if __name__ == '__main__':
    test_analyze_car() 