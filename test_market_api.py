import requests

def test_market():
    url = "http://localhost:8000/market-prices"
    params = {
        "state": "Telangana",
        "commodity": "Cotton",
        "lat": 17.4,  # Near Hyderabad
        "lon": 78.5
    }
    try:
        response = requests.get(url, params=params)
        print(f"Status: {response.status_code}")
        data = response.json()
        if isinstance(data, list) and len(data) > 0:
            print(f"Count: {len(data)}")
            print("First record sample:")
            print(data[0])
        else:
            print(f"Response: {data}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_market()
