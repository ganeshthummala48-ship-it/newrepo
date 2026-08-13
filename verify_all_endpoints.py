import requests
import json

def test_endpoint(url, data=None, files=None, method="POST"):
    print(f"Testing {url}...")
    try:
        if method == "POST":
            if files:
                response = requests.post(url, data=data, files=files)
            else:
                response = requests.post(url, json=data)
        else:
            response = requests.get(url)
            
        print(f"Status: {response.status_code}")
        # Print first 200 chars of response
        print(f"Response: {response.text[:200]}...")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    base_url = "http://localhost:8000"
    
    # 1. Test Health
    test_endpoint(f"{base_url}/health", method="GET")
    
    # 2. Test Yield Prediction
    test_endpoint(f"{base_url}/predict-yield", {
        "crop": "Rice",
        "soil": "Black",
        "rainfall": "Medium",
        "land_size": 1.0
    })
    
    # 3. Test Crop Recommendation
    test_endpoint(f"{base_url}/recommend-crop", {
        "soil": "Black",
        "season": "Kharif",
        "rainfall": "Medium"
    })
    
    # 4. Test Disease Detection using a real image from the project root
    try:
        with open("flutter_01.png", "rb") as f:
            dummy_file = {"file": ("flutter_01.png", f, "image/png")}
            test_endpoint(f"{base_url}/detect-disease", files=dummy_file)
    except FileNotFoundError:
        print("flutter_01.png not found, skipping actual image upload test.")
        # Alternatively, send the fake image to test the new error handling
        dummy_file = {"file": ("test.jpg", b"fake-image-content", "image/jpeg")}
        test_endpoint(f"{base_url}/detect-disease", files=dummy_file)
