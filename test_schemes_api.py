import requests
import json

url = "http://localhost:8000/recommend-schemes"
payload = {
    "state": "Telangana",
    "crop": "Rice",
    "land_size": 2.0,
    "lang": "en"
}
headers = {
    "Content-Type": "application/json"
}

try:
    print(f"Sending request to {url}...")
    response = requests.post(url, headers=headers, data=json.dumps(payload), timeout=120)
    response.raise_for_status()
    print("Response received:")
    print(json.dumps(response.json(), indent=2))
except Exception as e:
    print(f"Error: {e}")
