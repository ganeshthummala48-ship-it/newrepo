import os
import json
import io
import joblib
from PIL import Image
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
import httpx

# ======================================================
# 🔹 LOAD ENVIRONMENT
# ======================================================

load_dotenv()

# ======================================================
# 🔹 OLLAMA HELPER
# ======================================================

async def call_ollama(prompt: str, model: str = "llama3-8b-8192"):
    groq_api_key = os.getenv("GROQ_API_KEY")
    if not groq_api_key:
        print("❌ Error: GROQ_API_KEY environment variable is not set!")
        return None
    url = "https://api.groq.com/openai/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {groq_api_key}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.5,
    }
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]
    except Exception as e:
        print(f"❌ Groq API Error: {type(e).__name__} - {str(e)}")
        return None



# ======================================================
# 🔹 APP SETUP
# ======================================================

class CropRequest(BaseModel):
    soil: str
    season: str
    rainfall: str


class QuestionRequest(BaseModel):
    question: str

class YieldRequest(BaseModel):
    crop: str
    soil: str
    rainfall: str
    land_size: float = 1.0  # in hectares

class ProfitRequest(BaseModel):
    crop: str
    yield_amount: float
    market_price: float
    cost: float

class SchemeRequest(BaseModel):
    state: str
    crop: str
    land_size: float

class CropRotationRequest(BaseModel):
    current_crop: str
    soil: str
    season: str
    years: int = 3

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ======================================================
# 🧠 DISEASE DETECTION MODEL FILES
# ======================================================

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

MODEL_PATH = os.path.join(BASE_DIR, "model", "plant_disease_model.h5")
LABELS_PATH = os.path.join(BASE_DIR, "model", "labels.json")
TREATMENTS_PATH = os.path.join(BASE_DIR, "data", "treatments.json")

# Global disease model variable (lazy loaded)
disease_model = None

def get_disease_model():
    global disease_model
    if disease_model is None:
        import tensorflow as tf
        try:
            disease_model = tf.keras.models.load_model(MODEL_PATH)
            print("✅ Disease detection model loaded")
        except Exception as e:
            print(f"⚠️ Warning: Could not load disease detection model: {e}")
    return disease_model

with open(LABELS_PATH, "r", encoding="utf-8") as f:
    label_map = json.load(f)

with open(TREATMENTS_PATH, "r", encoding="utf-8") as f:
    treatments = json.load(f)


# ======================================================
# 🌾 CROP RECOMMENDATION MODEL (LAZY LOADING)
# ======================================================

CROP_MODEL_PATH = os.path.join(BASE_DIR, "crop_model.pkl")
SOIL_ENCODER_PATH = os.path.join(BASE_DIR, "soil_encoder.pkl")
SEASON_ENCODER_PATH = os.path.join(BASE_DIR, "season_encoder.pkl")
RAINFALL_ENCODER_PATH = os.path.join(BASE_DIR, "rainfall_encoder.pkl")
CROP_ENCODER_PATH = os.path.join(BASE_DIR, "crop_encoder.pkl")

# Global variables (lazy loaded)
crop_model = None
soil_encoder = None
season_encoder = None
rainfall_encoder = None
crop_encoder = None

def get_crop_recommendation_models():
    global crop_model, soil_encoder, season_encoder, rainfall_encoder, crop_encoder
    if crop_model is None:
        try:
            crop_model = joblib.load(CROP_MODEL_PATH)
            soil_encoder = joblib.load(SOIL_ENCODER_PATH)
            season_encoder = joblib.load(SEASON_ENCODER_PATH)
            rainfall_encoder = joblib.load(RAINFALL_ENCODER_PATH)
            crop_encoder = joblib.load(CROP_ENCODER_PATH)
            print("🌾 Crop recommendation model loaded")
        except Exception as e:
            print(f"⚠️ Warning: Could not load crop recommendation model: {e}")
    return crop_model, soil_encoder, season_encoder, rainfall_encoder, crop_encoder


# ======================================================
# 🔧 UTILITY FUNCTION
# ======================================================

def normalize_disease(name: str) -> str:
    return name.replace("___", " ").replace("_", " ").strip()


# ======================================================
# 📸 DISEASE DETECTION ENDPOINT
# ======================================================

@app.post("/detect-disease")
async def detect_disease(file: UploadFile = File(...)):
    import numpy as np
    model = get_disease_model()
    if not model:
        return {"error": "Disease detection model not available on this server."}
        
    image_bytes = await file.read()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    image = image.resize((224, 224))

    image_array = np.array(image) / 255.0
    image_array = np.expand_dims(image_array, axis=0)

    predictions = model.predict(image_array)
    predicted_index = int(np.argmax(predictions))
    confidence = float(np.max(predictions)) * 100

    print(f"🔍 Predictions done. Top index: {predicted_index}, Confidence: {confidence:.2f}%")

    raw_disease = label_map.get(str(predicted_index), "Unknown Disease")
    disease = normalize_disease(raw_disease)
    print(f"🔍 Detected disease: {disease}")

    treatment = treatments.get(disease)

    if confidence < 60:
        print("⚠️ Confidence too low, marking as Unknown")
        disease = "Unknown"
        treatment = None

    ai_explanation = None

    if disease != "Unknown":
        print(f"🤖 Calling Ollama for {disease} explanation...")
        prompt = f"""
        You are an expert agricultural scientist.

        Disease detected: {disease}
        Confidence: {round(confidence, 2)}%

        Provide in this format:

Cause:
Symptoms:
Treatment:
Recommended Pesticides:
Organic Alternatives:

Keep answer short and clear.
"""
        ai_explanation = await call_ollama(prompt)
        print(f"✅ Ollama response received: {'Success' if ai_explanation else 'Failed'}")


    return {
        "disease": disease,
        "confidence": round(confidence, 2),
        "recommendation": "Follow recommended agricultural practices",
        "treatment": treatment,
        "ai_explanation": ai_explanation
    }


# ======================================================
# 🌾 CROP RECOMMENDATION ENDPOINT
# ======================================================
@app.post("/crop-rotation")
async def crop_rotation(data: CropRotationRequest):
    try:
        prompt = f"""
You are an expert agricultural scientist.

Farmer details:
Current Crop: {data.current_crop}
Soil Type: {data.soil}
Season: {data.season}
Years to Plan: {data.years}

Create a smart crop rotation plan for {data.years} years.

Respond in this format:

Rotation Plan:
Year 1:
Year 2:
Year 3:

Soil Benefits:
Pest Reduction Benefits:
Fertilizer Optimization:
Expected Yield Impact:

Keep explanation simple and farmer-friendly.
"""

        response_text = await call_ollama(prompt)
        return {"rotation_plan": response_text if response_text else "Ollama rotation plan unavailable."}

    except Exception as e:
        return {"error": str(e)}


@app.post("/recommend-crop")
def recommend_crop(data: CropRequest):
    import numpy as np
    try:
        model, s_enc, se_enc, r_enc, c_enc = get_crop_recommendation_models()
        if not model:
            return {"error": "Crop recommendation model not loaded. Check server logs."}
            
        soil_enc = s_enc.transform([data.soil])[0]
        season_enc = se_enc.transform([data.season])[0]
        rainfall_enc = r_enc.transform([data.rainfall])[0]

        features = np.array([[soil_enc, season_enc, rainfall_enc]])
        probabilities = model.predict_proba(features)[0]
        top_indices = np.argsort(probabilities)[::-1][:3]

        top_crops = []
        top_probability = probabilities[top_indices[0]]

        for rank, idx in enumerate(top_indices, start=1):
            crop_name = c_enc.inverse_transform([idx])[0]
            relative_confidence = (probabilities[idx] / top_probability) * 100

            explanation = (
                f"{crop_name} performs well in {data.soil} soil during the "
                f"{data.season} season with {data.rainfall.lower()} rainfall."
            )

            top_crops.append({
                "rank": rank,
                "crop": crop_name,
                "confidence": round(relative_confidence, 2),
                "description": explanation
            })

        return {
            "input": data.dict(),
            "top_crops": top_crops
        }

    except Exception as e:
        return {"error": str(e)}


# ======================================================
# 🤖 AI ASSISTANT ENDPOINT
# ======================================================

@app.post("/ask_ai")
async def ask_ai(data: QuestionRequest):
    try:
        system_prompt = "You are an expert AI Farming Assistant with deep knowledge of agronomy, soil science, and agricultural economics. Answer accurately and helpfully."
        full_prompt = f"{system_prompt}\n\nQuestion: {data.question}"
        response_text = await call_ollama(full_prompt)
        return {"answer": response_text if response_text else "AI Assistant currently unavailable."}
    except Exception as e:
        return {"answer": f"Error: {str(e)}"}

# ======================================================
# 📈 ADVANCED ANALYTICS ENDPOINTS
# ======================================================

@app.post("/predict-yield")
async def predict_yield(data: YieldRequest):
    try:
        # Base yields (approximate tons per hectare)
        base_yields = {
            "rice": 4.0, "wheat": 3.5, "maize": 5.0, "cotton": 2.5,
            "sugarcane": 70.0, "tomato": 20.0, "potato": 18.0
        }
        
        base = base_yields.get(data.crop.lower(), 3.0)
        
        # Simple multipliers for simulation
        soil_mult = 1.2 if data.soil.lower() in ["black", "alluvial"] else 1.0
        rain_mult = 1.1 if data.rainfall.lower() == "high" else 0.9 if data.rainfall.lower() == "low" else 1.0
        
        estimated_yield = base * soil_mult * rain_mult * data.land_size
        
        prompt = f"As an agricultural expert, briefly explain why the expected yield for {data.crop} in {data.soil} soil with {data.rainfall} rainfall is approximately {round(estimated_yield/data.land_size, 2)} tons/hectare."
        explanation = await call_ollama(prompt)
        
        return {
            "expected_yield": round(estimated_yield, 2),
            "unit": "tons",
            "explanation": explanation
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/calculate-profit")
async def calculate_profit(data: ProfitRequest):
    try:
        revenue = data.yield_amount * data.market_price
        profit = revenue - data.cost
        roi = (profit / data.cost * 100) if data.cost > 0 else 0
        
        return {
            "revenue": round(revenue, 2),
            "profit": round(profit, 2),
            "roi_percentage": round(roi, 2),
            "status": "Profitable" if profit > 0 else "Loss"
        }
    except Exception as e:
        return {"error": str(e)}

@app.post("/recommend-schemes")
async def recommend_schemes(data: SchemeRequest):
    try:
        prompt = f"""
        Act as a government agricultural advisor. 
        Farmer Profile:
        State: {data.state}
        Crop: {data.crop}
        Land Size: {data.land_size} hectares

        List 3 relevant government schemes or subsidies this farmer might be eligible for. 
        Format as a simple list with brief descriptions.
        """
        response = await call_ollama(prompt)
        return {"schemes": response}
    except Exception as e:
        return {"error": str(e)}

@app.post("/risk-alerts")
async def risk_alerts(crop: str, location: str):
    try:
        prompt = f"Analyze agricultural risks for {crop} in {location} for the next 15 days. Mention drought, heavy rain, or pest risks. Keep it very short."
        alerts = await call_ollama(prompt)
        return {"alerts": alerts}
    except Exception as e:
        return {"error": str(e)}




# ======================================================
# ROOT
# ======================================================

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/")
def root():
    return {
        "status": "FarmerAI backend running",
        "features": [
            "Crop Disease Detection",
            "Crop Recommendation",
            "AI Assistant (Ollama Llama 3 Integrated)"
        ]
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)