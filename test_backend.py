import requests

def test_health():
    try:
        # Try to call a simple endpoint or check if server is up
        response = requests.get("http://127.0.0.1:8000/")
        print(f"Base Status: {response.status_code}")
        print(f"Base Response: {response.json()}")
        
        # Check diagnostic endpoint
        diag_data = requests.get("http://127.0.0.1:8000/diag").json()
        print(f"Models: {diag_data.get('models')}")
        
        # Test crop recommendation (Lowercase now works due to normalization)
        crop_data = {"soil": "black", "season": "kharif", "rainfall": "high", "lang": "en"}
        crop_res = requests.post("http://127.0.0.1:8000/recommend-crop", json=crop_data).json()
        if "top_crops" in crop_res:
            print(f"Crop Rec: Success (Top: {crop_res['top_crops'][0]['crop']})")
        else:
            print(f"Crop Rec: Failed ({crop_res})")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_health()
