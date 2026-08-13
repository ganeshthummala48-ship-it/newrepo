import urllib.request
import json

response = urllib.request.urlopen("http://localhost:8000/listings?type=machinery&lang=en")
data = json.loads(response.read().decode('utf-8'))
with open('c:/PROJECTS/farmer_ai/test_api_out.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)
