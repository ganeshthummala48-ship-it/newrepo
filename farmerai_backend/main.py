import json
import os
os.environ["KERAS_BACKEND"] = "tensorflow"

import io
import joblib
from PIL import Image
import keras
from fastapi import FastAPI, File, UploadFile, Depends, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import math
from dotenv import load_dotenv
import httpx
from sqlalchemy import Column, Integer, String, Float, JSON, ForeignKey, DateTime, Text, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from datetime import datetime


# ======================================================
# 🔹 LOAD ENVIRONMENT
# ======================================================

load_dotenv()

# ======================================================
# 🔹 COHERE HELPER
# ======================================================

LANG_NAMES = {
    "te": "Telugu", "hi": "Hindi", "en": "English",
    "mr": "Marathi", "ta": "Tamil", "bn": "Bengali",
    "gu": "Gujarati", "kn": "Kannada", "ml": "Malayalam",
    "pa": "Punjabi", "or": "Odia"
}


async def call_cohere(prompt: str, model: str = "command-a-03-2025", lang: str = "en"):
    cohere_api_key = os.getenv("COHERE_API_KEY")
    if not cohere_api_key:
        print("❌ Error: COHERE_API_KEY environment variable is not set!")
        return None
    url = "https://api.cohere.ai/v1/chat"
    headers = {
        "Authorization": f"Bearer {cohere_api_key}",
        "Content-Type": "application/json"
    }
    
    lang_name = LANG_NAMES.get(lang, "English")
    
    payload = {
        "model": model,
        "message": prompt,
        "preamble": f"You are an expert agricultural scientist and FarmerAI assistant. You MUST respond COMPLETELY and EXCLUSIVELY in the {lang_name} language. Under NO circumstances should you output English unless the user's requested language is English. All headings, bullet points, numbers, and text must be translated to {lang_name}.",
        "temperature": 0.5,
    }
    for attempt in range(2):
        try:
            async with httpx.AsyncClient(timeout=120.0) as client:
                response = await client.post(url, headers=headers, json=payload)
                response.raise_for_status()
                data = response.json()
                return data.get("text")
        except httpx.ReadTimeout:
            print(f"⚠️ Cohere ReadTimeout on attempt {attempt + 1}. Retrying...")
            if attempt == 1:
                return "AI response timed out. Please try again later."
        except Exception as e:
            print(f"❌ Cohere API Error: {type(e).__name__} - {str(e)}")
            return None



# ======================================================
# 🔹 DATABASE SETUP
# ======================================================

SQLALCHEMY_DATABASE_URL = "sqlite:///./farmer_ai.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, index=True)
    role = Column(String)  # 'farmer' or 'contractor'
    password = Column(String)
    phone = Column(String, default="")
    specialty = Column(String, default="")
    language = Column(String, default="en")
    rating = Column(Float, default=4.5)
    
    listings = relationship("Listing", back_populates="owner")

class Listing(Base):
    __tablename__ = "listings"
    id = Column(Integer, primary_key=True, index=True)
    contractor_name = Column(String, ForeignKey("users.name"))
    type = Column(String)  # 'machinery', 'labour', 'fertilizers'
    title = Column(JSON)  # Store as dict for localization
    contact = Column(String)
    description = Column(JSON)
    price = Column(String, default="")
    extra_fields = Column(JSON, default={})
    lat = Column(Float, default=0.0)
    lng = Column(Float, default=0.0)
    
    owner = relationship("User", back_populates="listings")

class Inquiry(Base):
    __tablename__ = "inquiries"
    id = Column(Integer, primary_key=True, index=True)
    farmer_name = Column(String)
    contractor_name = Column(String)
    listing_id = Column(Integer)
    offer_amount = Column(String)
    message = Column(Text)
    status = Column(String, default="pending")
    timestamp = Column(DateTime, default=datetime.utcnow)

Base.metadata.create_all(bind=engine)

# ── Safe DB Migration: Add phone column if missing ──
def _migrate_db():
    try:
        with engine.connect() as conn:
            result = conn.execute(__import__('sqlalchemy').text("PRAGMA table_info(users)"))
            columns = [row[1] for row in result]
            if 'phone' not in columns:
                conn.execute(__import__('sqlalchemy').text("ALTER TABLE users ADD COLUMN phone TEXT DEFAULT ''"))
                conn.commit()
                print("✅ DB Migration: Added 'phone' column to users table")
    except Exception as e:
        print(f"⚠️ DB Migration warning: {e}")

_migrate_db()


# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ======================================================
# 🔹 APP SETUP
# ======================================================

class CropRequest(BaseModel):
    soil: str
    season: str
    rainfall: str
    lang: str = "en"


class QuestionRequest(BaseModel):
    question: str
    lang: str = "en"

class YieldRequest(BaseModel):
    crop: str
    soil: str
    rainfall: str
    land_size: float = 1.0  # in hectares
    lang: str = "en"

class ProfitRequest(BaseModel):
    crop: str
    yield_amount: float
    market_price: float
    cost: float

class SchemeRequest(BaseModel):
    state: str
    crop: str
    land_size: float
    lang: str = "en"

class CropRotationRequest(BaseModel):
    current_crop: str
    soil: str
    season: str
    years: int = 3
    lang: str = "en"

class NegotiationRequest(BaseModel):
    item_name: str
    item_type: str # 'machinery' or 'labour'
    original_price: str
    offered_price: str
    farmer_name: str
    notes: str = ""
    lang: str = "en"

class UserCreate(BaseModel):
    name: str
    role: str # 'farmer' or 'contractor'
    password: str
    phone: str = "" # Phone number
    specialty: str = "" # For contractors: 'Machinery', 'Labour', 'Fertilizers', etc.
    language: str = "en"

class UserLogin(BaseModel):
    name: str
    password: str

class ListingCreate(BaseModel):
    contractor_name: str
    type: str # 'machinery', 'labour', 'fertilizers'
    title: str
    contact: str
    description: str
    price: str = ""
    extra_fields: dict = {}
    lat: float = 0.0
    lng: float = 0.0

class InquiryCreate(BaseModel):
    farmer_name: str
    contractor_name: str
    listing_id: int
    offer_amount: str
    message: str

class InquiryResponse(BaseModel):
    inquiry_id: int
    status: str # 'accepted' or 'rejected'

class ListingUpdate(BaseModel):
    type: str # 'machinery', 'labour', 'fertilizers'
    item: dict

class ProfileUpdate(BaseModel):
    specialty: str = None
    language: str = None

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
SPECIALIZED_TREATMENTS_PATH = os.path.join(BASE_DIR, "data", "treatments_specialized.json")

# Global disease model variable (lazy loaded)
disease_model = None
specialized_models = {}

def get_disease_model():
    """Returns the pre-loaded global disease model."""
    global disease_model
    return disease_model

@app.on_event("startup")
async def startup_event():
    """Performs pre-loading and setup tasks on server start."""
    global disease_model
    import tensorflow as tf
    import keras
    print(f"🌅 Server starting: Pre-loading models... [TF={tf.__version__}, Keras={keras.__version__}]")
    
    # 1. Ensure disease model is present
    try:
        import download_model
        download_model.download_model_if_missing()
    except Exception as e:
        print(f"⚠️ Warning: Model download check failed: {e}")

    # 2. Pre-load the base disease detection model
    if os.path.exists(MODEL_PATH):
        import tensorflow as tf
        import numpy as np
        try:
            # Use native Keras 3 loading for better compatibility
            disease_model = keras.models.load_model(MODEL_PATH, compile=False)
            print("✅ Base disease detection model loaded")
            
            # WARM-UP: Ensure first prediction is fast
            dummy_input = np.zeros((1, 224, 224, 3))
            disease_model.predict(dummy_input, verbose=0)
            print("⚡ Disease model warmed up and ready")
        except Exception as e:
            print(f"⚠️ Warning: Model loading failed: {e}")
    else:
        print("❌ Error: plant_disease_model.h5 not found after download check.")

    # 3. Pre-load crop recommendation models
    print("🌾 Pre-loading crop recommendation models...")
    get_crop_recommendation_models()


def get_specialized_model(crop_name: str):
    """
    Lazy loads or returns a mock specialized model for a specific crop.
    In a real scenario, this would load separate .h5 files.
    """
    global specialized_models
    if crop_name not in specialized_models:
        # For now, we use the base model as a placeholder or mock logic
        # If a real specialized model file exists, load it:
        spec_path = os.path.join(BASE_DIR, "model", f"{crop_name.lower()}_disease_model.h5")
        if os.path.exists(spec_path):
            import tensorflow as tf
            try:
                specialized_models[crop_name] = keras.models.load_model(spec_path, compile=False)
                print(f"✅ Specialized model for {crop_name} loaded from {spec_path}")
            except Exception as e:
                print(f"⚠️ Warning: Could not load specialized model for {crop_name}: {e}")
        else:
            print(f"ℹ️ No specialized model file for {crop_name}, using base model fallback logic.")
            specialized_models[crop_name] = None # Will trigger fallback to base model labels
    return specialized_models.get(crop_name)

with open(LABELS_PATH, "r", encoding="utf-8") as f:
    label_map = json.load(f)

# Load and merge treatments
with open(TREATMENTS_PATH, "r", encoding="utf-8") as f:
    all_treatments = json.load(f)

if os.path.exists(SPECIALIZED_TREATMENTS_PATH):
    with open(SPECIALIZED_TREATMENTS_PATH, "r", encoding="utf-8") as f:
        spec_treatments = json.load(f)
        all_treatments.update(spec_treatments)
        print("✅ Specialized treatments merged")


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
# 🔧 UTILITY FUNCTIONS
# ======================================================

@app.get("/diag")
async def diagnostic():
    """Check if models are loaded for debugging purposes."""
    global disease_model, crop_model
    return {
        "status": "online",
        "models": {
            "disease_model": "Loaded" if disease_model is not None else "Not Loaded",
            "crop_model": "Loaded" if crop_model is not None else "Not Loaded"
        },
        "paths": {
            "disease_model_path": MODEL_PATH,
            "crop_model_path": CROP_MODEL_PATH
        }
    }

def normalize_disease(name: str) -> str:
    return name.replace("___", " ").replace("_", " ").strip()

def calculate_distance(lat1, lon1, lat2, lon2):
    """Haversine formula to calculate distance between two points in km"""
    R = 6371  # Earth radius in km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

# Load mandi coordinates
COORDINATES_PATH = os.path.join(BASE_DIR, "data", "mandi_coordinates.json")
try:
    with open(COORDINATES_PATH, "r") as f:
        mandi_coords = json.load(f)
except Exception:
    mandi_coords = {}

# Load state districts
STATE_DISTRICTS_PATH = os.path.join(BASE_DIR, "data", "state_districts.json")
try:
    with open(STATE_DISTRICTS_PATH, "r") as f:
        state_districts = json.load(f)
except Exception:
    state_districts = {}


# ======================================================
# 📸 DISEASE DETECTION ENDPOINT
# ======================================================
@app.post("/detect-disease")
async def detect_disease(file: UploadFile = File(...), lang: str = Form("en")):
    import numpy as np
    base_model = get_disease_model()
    if not base_model:
        return {"error": "Disease detection model not available on this server."}
        
    image_bytes = await file.read()
    try:
        image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    except Exception as e:
        return {"error": "Invalid image format. Please upload a valid image file."}
        
    image = image.resize((224, 224))
    
    # image = ImageOps.autocontrast(image) # ❌ REMOVED: Match training preprocessing
    
    image_array = np.array(image) / 255.0
    image_array_batch = np.expand_dims(image_array, axis=0)

    # ──────────────────────────────────────────────────────────────────
    # 🎯 STAGE 1: CROP IDENTIFICATION (Hierarchical Step)
    # ──────────────────────────────────────────────────────────────────
    predictions = base_model.predict(image_array_batch)
    predicted_index = int(np.argmax(predictions))
    confidence = float(np.max(predictions)) * 100
    
    raw_label = label_map.get(str(predicted_index), "Unknown Unknown")
    # Identify crop from new label format (e.g. "Corn (maize) Cercospora leaf spot Gray leaf spot" -> "Corn")
    if " " in raw_label:
        crop_identified = raw_label.split(" ")[0].replace(",", "")
    else:
        crop_identified = raw_label
    
    print(f"🎯 Hierarchical Stage 1: Crop Identified -> {crop_identified} (Conf: {confidence:.2f}%)")

    # ──────────────────────────────────────────────────────────────────
    # 🎯 STAGE 2: SPECIALIZED DISEASE DETECTION
    # ──────────────────────────────────────────────────────────────────
    # Check if we have a specialized "deep" model for this crop
    spec_model = get_specialized_model(crop_identified)
    
    if spec_model:
        print(f"🚀 Running specialized deep-dive model for {crop_identified}...")
        spec_predictions = spec_model.predict(image_array_batch)
        # Note: In a real scenario, the spec_model would have its own label map.
        # For this architecture demonstration, we'll use the base prediction if spec_model is just a placeholder.
        # predicted_index = int(np.argmax(spec_predictions))
        # confidence = float(np.max(spec_predictions)) * 100
    
    # Extract right side of the string as the disease itself
    # e.g. "Apple Apple scab" -> "Apple scab"
    parts = raw_label.split(" ", 1)
    disease_str = parts[1] if len(parts) > 1 else raw_label
    
    disease = disease_str.strip()
    
    # Try exact match first on the full label (e.g. "Apple Apple scab")
    treatment = all_treatments.get(raw_label.strip())
    if not treatment:
        # Fallback to the parsed disease string
        treatment = all_treatments.get(disease)

    # ──────────────────────────────────────────────────────────────────
    # 🛡️ UNKNOWN IMAGE REJECTION (ENHANCED)
    # ──────────────────────────────────────────────────────────────────
    is_unknown = False
    rejection_reason = None

    # LAYER 1: Confidence threshold
    CONFIDENCE_THRESHOLD = 70.0 # Slightly relaxed for specialized routing
    if confidence < CONFIDENCE_THRESHOLD:
        is_unknown = True
        rejection_reason = f"Low confidence ({confidence:.1f}% < {CONFIDENCE_THRESHOLD}%)"

    # LAYER 2: Organic color validation
    if not is_unknown:
        img = image_array # Use pre-normalized array
        r, g, b = img[:,:,0], img[:,:,1], img[:,:,2]
        is_green = (g > r) & (g > b * 0.8)
        is_brown = (r > b) & (g > b) & (r > 0.3)
        organic_ratio = np.mean(is_green | is_brown)
        
        print(f"🌿 Organic color ratio: {organic_ratio:.4f}")
        # Tightened threshold: must have significant green or yellowish-brown matter
        if organic_ratio < 0.25: 
            is_unknown = True
            rejection_reason = f"Non-leaf image detected (organic ratio={organic_ratio:.2f} < 0.25)"

    if is_unknown:
        print(f"⚠️ Rejected as Unknown: {rejection_reason}")
        disease = "Unknown"
        treatment = None

    ai_explanation = None

    recommendation_text = "Follow recommended agricultural practices" if disease != "Unknown" else "Please upload a clear, close-up photo of an affected plant leaf."

    if disease != "Unknown":
        print(f"🤖 Calling Cohere for {disease} explanation (Crop: {crop_identified})...")
        prompt = f"""
        You are an expert agricultural scientist specialize in {crop_identified}.

        Detected: {disease}
        Crop Type: {crop_identified}
        Confidence: {round(confidence, 2)}%

        Provide a detailed explanation of the disease. Include:
        1. The main causes.
        2. Typical symptoms.
        3. Recommended treatments (chemical and organic).

        CRITICAL RULES:
        1. Your ENTIRE response MUST be strictly in the {LANG_NAMES.get(lang, "English")} language.
        2. DO NOT use English words or sentences, even for technical terms, unless the requested language is English.
        3. Translate all headings, greetings, and treatments to {LANG_NAMES.get(lang, "English")}.
        Make the response professional and use Markdown formatting for readability.
"""
        ai_explanation = await call_cohere(prompt, lang=lang)
        print(f"✅ Cohere response received: {'Success' if ai_explanation else 'Failed'}")

    # Translate basic fields if language is not English
    if lang != 'en':
        print(f"🤖 Translating basic fields to {LANG_NAMES.get(lang, 'English')}...")
        trans_prompt = f"""
        Translate the following agricultural terms to {LANG_NAMES.get(lang, 'English')}.
        Respond ONLY with a valid JSON object with the keys "disease", "recommendation", and "treatment".
        Do not include markdown blocks or any other text.
        
        Data to translate:
        disease: {disease}
        recommendation: {recommendation_text}
        treatment: {json.dumps(treatment) if treatment else 'null'}
        """
        try:
            trans_result = await call_cohere(trans_prompt, lang=lang)
            if trans_result:
                # Basic cleaning just in case Cohere adds markdown
                clean_json = trans_result.replace('```json', '').replace('```', '').strip()
                translated_data = json.loads(clean_json)
                disease = translated_data.get("disease", disease)
                recommendation_text = translated_data.get("recommendation", recommendation_text)
                if treatment and translated_data.get("treatment"):
                    treatment = translated_data.get("treatment")
        except Exception as e:
            print(f"⚠️ Translation fallback failed: {e}")

    return {
        "disease": disease,
        "confidence": round(confidence, 2),
        "recommendation": recommendation_text,
        "treatment": treatment,
        "ai_explanation": ai_explanation,
        "rejection_reason": rejection_reason if is_unknown else None
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

Rotation Plan:
Year 1:
Year 2:
Year 3:

Keep explanation simple and farmer-friendly. 
CRITICAL: Respond STRICTLY, COMPLETELY, and EXCLUSIVELY in the {LANG_NAMES.get(data.lang, "English")} language. Never respond in English.
"""

        response_text = await call_cohere(prompt, lang=data.lang)
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
            
        soil_enc = s_enc.transform([data.soil.title()])[0]
        season_enc = se_enc.transform([data.season.title()])[0]
        rainfall_enc = r_enc.transform([data.rainfall.title()])[0]

        features = np.array([[soil_enc, season_enc, rainfall_enc]])
        probabilities = model.predict_proba(features)[0]
        top_indices = np.argsort(probabilities)[::-1][:3]

        top_crops = []
        top_probability = probabilities[top_indices[0]]

        for rank, idx in enumerate(top_indices, start=1):
            crop_name = c_enc.inverse_transform([idx])[0]
            relative_confidence = (probabilities[idx] / top_probability) * 100

            # Localized default explanations
            explanations = {
                "en": f"{crop_name} performs well in {data.soil} soil during the {data.season} season with {data.rainfall.lower()} rainfall.",
                "hi": f"{crop_name} {data.soil} मिट्टी में {data.season} मौसम के दौरान {data.rainfall.lower()} वर्षा के साथ अच्छा प्रदर्शन करता है।",
                "te": f"{crop_name} {data.season} కాలంలో {data.soil} నేలలో {data.rainfall.lower()} వర్షపాతంతో బాగా పెరుగుతుంది."
            }
            explanation = explanations.get(data.lang, explanations["en"])

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
        system_prompt = f"You are an expert AI Farming Assistant. You MUST respond STRICTLY AND ONLY in the {LANG_NAMES.get(data.lang, 'English')} language. Under NO circumstances should you reply in English unless specifically requested."
        full_prompt = f"{system_prompt}\n\nQuestion: {data.question}"
        response_text = await call_cohere(full_prompt, lang=data.lang)
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
        
        prompt = f"Briefly explain yield factors for {data.crop} in {data.soil} soil with {data.rainfall} rain. Keep to 2-3 sentences. Respond strictly in the {LANG_NAMES.get(data.lang, 'English')} language."
        explanation = await call_cohere(prompt, lang=data.lang)
        
        if not explanation:
            explanation = f"Calculated based on average yield for {data.crop} in {data.soil} soil conditions."
            
        return {
            "expected_yield": round(estimated_yield, 2),
            "unit": "tons",
            "explanation": explanation
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/recommend-schemes")
async def recommend_schemes(data: SchemeRequest):
    try:
        prompt = (
            f"You are an expert on Indian government agricultural schemes and subsidies.\n\n"
            f"A farmer in {data.state} is growing {data.crop} on {data.land_size} hectares of land.\n\n"
            f"List the top 5 most relevant central and state government schemes for this farmer. "
            f"For each scheme, provide:\n"
            f"- **Scheme Name** (with the ministry/department)\n"
            f"- **What it offers** (subsidy amount, loan, insurance, etc.)\n"
            f"- **Who is eligible**\n"
            f"- **How to apply** (portal or office)\n"
            f"- **Application Link**: Provide a direct official URL to the application portal if known, otherwise provide a link to the main department website (e.g., https://pmkisan.gov.in/ for PM-KISAN, https://pmfby.gov.in/ for PMFBY, etc.).\n\n"
            f"Format your response in clear Markdown with each scheme as a section. "
            f"Include both central government schemes (like PM-KISAN, PMFBY) and any relevant {data.state}-specific schemes. "
            f"CRITICAL: The entire textual response (descriptions, headings, names) MUST be COMPLETELY translated into the {LANG_NAMES.get(data.lang, 'English')} language. DO NOT return English summaries. Keep only the URLs exactly as standard English links."
        )
        response = await call_cohere(prompt, lang=data.lang)
        return {"schemes": response}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/risk-alerts")
async def risk_alerts(crop: str, location: str, lang: str = "en", lat: float = 0.0, lon: float = 0.0):
    try:
        location_context = location
        if lat != 0.0 and lon != 0.0:
            location_context = f"{location} (GPS coordinates: {round(lat, 4)}, {round(lon, 4)})"

        prompt = (
            f"Analyze agricultural risks for {crop} crop in {location_context} for the next 15 days. "
            f"Consider season, likely weather patterns, common pests, and disease risks for this region. "
            f"Mention specific risks like drought, heavy rain, frost, or pest outbreaks. Keep it concise and farmer-friendly. "
            f"Respond STRICTLY in the {LANG_NAMES.get(lang, 'English')} language."
        )
        alerts = await call_cohere(prompt, lang=lang)
        return {"alerts": alerts}
    except Exception as e:
        return {"error": str(e)}

@app.post("/negotiate")
async def negotiate(data: NegotiationRequest):
    try:
        # Business logic for negotiation simulation
        # In a real app, this would notify the owner/provider
        
        prompt = f"""
You are an AI negotiation assistant for a middle-man agricultural platform.
A farmer named {data.farmer_name} wants to negotiate for {data.item_name} ({data.item_type}).
Original Price: {data.original_price}
Farmer's Offer: {data.offered_price}
Farmer's Notes: {data.notes}

Provide a professional, fair response.
If the offer is too low (e.g., >30% discount), provide a counter-offer.
If it's reasonable, accept it gracefully.

Respond in this format:
Status: [Accepted/Counter-Offer]
Message: [Your response to the farmer]
Counter Price: [If counter-offer, specify price, else N/A]

Respond STRICTLY in the {LANG_NAMES.get(data.lang, 'English')} language.
"""
        response = await call_cohere(prompt, lang=data.lang)
        
        # Simulate saving to a database
        negotiation_id = f"NEG-{math.floor(math.cos(1) * 10000)}" # Dummy ID
        
        return {
            "negotiation_id": negotiation_id,
            "response": response,
            "status": "success"
        }
    except Exception as e:
        return {"error": str(e)}

@app.get("/negotiation-history")
async def get_negotiation_history(farmer_name: str):
    # Dummy history
    return {
        "history": [
            {
                "item": "Mahindra Arjun 555",
                "status": "Accepted",
                "price": "₹700/hr",
                "date": "2026-03-10"
            },
            {
                "item": "Sri Rama Labour Group",
                "status": "Counter-Offer",
                "price": "₹420/day",
                "date": "2026-03-12"
            }
        ]
    }


@app.get("/districts")
async def get_districts(state: str):
    return {"districts": state_districts.get(state, [])}

@app.get("/mandi-coordinates")
async def get_mandi_coordinates():
    return mandi_coords




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
            "AI Assistant (Cohere Integrated)",
            "Regional Language Support (Hindi/Telugu/Local)"
        ]
    }


# ======================================================
# 🔑 AUTH & ROLE ENDPOINTS
# ======================================================

# Mock user "database"
users_db = {}
notifications_db = []
listings_db = [
    {
        "id": 0,
        "contractor_name": "AgroStore Alpha",
        "type": "fertilizers",
        "title": {"en": "Urea Gold Premium", "te": "యూరియా గోల్డ్ ప్రీమియం"},
        "contact": "9000100020",
        "description": {"en": "High nitrogen fertilizer for paddy and maize.", "te": "వరి మరియు మొక్కజొన్న కోసం అధిక నైట్రోజన్ ఎరువులు."},
        "price": "₹350/50kg",
        "extra_fields": {"stock": "500 bags", "composition": "N:P:K (46:0:0)"},
        "lat": 17.3850,
        "lng": 78.4867
    },
    {
        "id": 1,
        "contractor_name": "Farmer's Friend Shop",
        "type": "fertilizers",
        "title": {"en": "DAP - Powerful Growth", "te": "డిఎపి - శక్తివంతమైన వృద్ధి"},
        "contact": "9000100021",
        "description": {"en": "Essential phosphorus for root development.", "te": "వేరు అభివృద్ధికి అవసరమైన భాస్వరం."},
        "price": "₹1350/50kg",
        "extra_fields": {"stock": "200 bags", "composition": "N:P:K (18:46:0)"},
        "lat": 17.4000,
        "lng": 78.5000
    },
    {
        "id": 2,
        "contractor_name": "Kisan Seva Center",
        "type": "fertilizers",
        "title": {"en": "Organic Compost Plus", "te": "సేంద్రీయ కంపోస్ట్ ప్లస్"},
        "contact": "9000100022",
        "description": {"en": "Pure organic manure for sustainable farming.", "te": "స్థిరమైన వ్యవసాయం కోసం స్వచ్ఛమైన సేంద్రీయ ఎరువు."},
        "price": "₹450/40kg",
        "extra_fields": {"stock": "1000 bags", "origin": "Eco-Friendly"},
        "lat": 17.3700,
        "lng": 78.4500
    },
    {
        "id": 3,
        "contractor_name": "Ramu Tractors",
        "type": "machinery",
        "title": {"en": "Mahindra Arjun 605", "te": "మహీంద్రా అర్జున్ 605"},
        "contact": "9000100023",
        "description": {"en": "Heavy duty tractor for plowing and transport.", "te": "దున్నడం మరియు రవాణా కోసం భారీ ట్రాక్టర్."},
        "price": "₹800/hr",
        "extra_fields": {"model": "2023", "hp": "57 HP"},
        "lat": 17.4200,
        "lng": 78.4800
    }
]
inquiries_db = []

@app.post("/register")
async def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.name == user.name).first()
    if db_user:
        return {"error": "User already exists"}
    
    new_user = User(
        name=user.name,
        role=user.role,
        password=user.password,
        phone=user.phone or "",
        specialty=user.specialty or "",
        language=user.language or "en"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return {"status": "success", "message": f"User {user.name} registered as {user.role}"}

@app.get("/contractors")
async def list_contractors(type: str = None, db: Session = Depends(get_db)):
    query = db.query(User).filter(User.role == "contractor")
    if type:
        query = query.filter(User.specialty.ilike(f"%{type}%"))
    
    contractors = query.all()
    results = []
    for c in contractors:
        results.append({
            "name": c.name,
            "specialty": c.specialty,
            "rating": c.rating,
            "feedback": ["Great service!"] # Placeholder
        })
    return {"contractors": results}

@app.post("/login")
async def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.name == user.name).first()
    if not db_user or db_user.password != user.password:
        return {"error": "Invalid credentials"}
    return {"status": "success", "role": db_user.role, "lang": db_user.language, "phone": db_user.phone or ""}

@app.get("/listings")
async def get_listings(type: str = None, lang: str = "en", db: Session = Depends(get_db)):
    query = db.query(Listing)
    if type:
        query = query.filter(Listing.type.ilike(type))
    
    items = query.all()
    
    processed_items = []
    for item in items:
        # Helper to parse stringified JSON from SQLite
        def safe_json_load(val):
            if isinstance(val, str):
                try:
                    return json.loads(val)
                except:
                    return {}
            return val or {}

        title_dict = safe_json_load(item.title)
        desc_dict = safe_json_load(item.description)
        extra_dict = safe_json_load(item.extra_fields)

        item_dict = {
            "id": item.id,
            "contractor_name": item.contractor_name,
            "type": item.type,
            "title": title_dict.get(lang, title_dict.get("en", str(item.title))),
            "contact": item.contact,
            "description": desc_dict.get(lang, desc_dict.get("en", str(item.description))),
            "price": item.price,
            "extra_fields": extra_dict,
            "lat": item.lat,
            "lng": item.lng
        }
        processed_items.append(item_dict)
        
    return {"items": processed_items}

@app.post("/add_listing")
async def add_listing(listing: ListingCreate, db: Session = Depends(get_db)):
    # Check if contractor exists
    db_contractor = db.query(User).filter(User.name == listing.contractor_name).first()
    if not db_contractor:
        # For simplicity, create user if not exists or return error
        pass

    new_listing = Listing(
        contractor_name=listing.contractor_name,
        type=listing.type,
        title=listing.title,
        contact=listing.contact,
        description=listing.description,
        price=listing.price,
        extra_fields=listing.extra_fields,
        lat=listing.lat,
        lng=listing.lng
    )
    db.add(new_listing)
    db.commit()
    db.refresh(new_listing)
    return {"status": "success", "message": "Listing added successfully", "id": new_listing.id}

@app.post("/update_profile")
async def update_profile(name: str, data: ProfileUpdate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.name == name).first()
    if not db_user:
        return {"error": "User not found"}
    
    if data.specialty is not None:
        db_user.specialty = data.specialty
    if data.language is not None:
        db_user.language = data.language
        
    db.commit()
    return {"status": "success"}

@app.get("/notifications")
async def get_notifications(user: str = None, db: Session = Depends(get_db)):
    # Inquiries serve as notifications for contractors
    if user:
        inquiries = db.query(Inquiry).filter(Inquiry.contractor_name == user).all()
        return {"notifications": inquiries}
    return {"notifications": db.query(Inquiry).all()}

@app.post("/create_inquiry")
async def create_inquiry(inquiry: InquiryCreate, db: Session = Depends(get_db)):
    new_inq = Inquiry(
        farmer_name=inquiry.farmer_name,
        contractor_name=inquiry.contractor_name,
        listing_id=inquiry.listing_id,
        offer_amount=inquiry.offer_amount,
        message=inquiry.message,
        status="pending"
    )
    db.add(new_inq)
    db.commit()
    db.refresh(new_inq)
    
    return {"status": "success", "inquiry_id": new_inq.id}

@app.get("/inquiries")
async def get_inquiries(user: str, role: str, db: Session = Depends(get_db)):
    if role == "contractor":
        items = db.query(Inquiry).filter(Inquiry.contractor_name == user).all()
    else:
        items = db.query(Inquiry).filter(Inquiry.farmer_name == user).all()
    return {"inquiries": items}

@app.post("/respond_inquiry")
async def respond_inquiry(res: InquiryResponse, db: Session = Depends(get_db)):
    inq = db.query(Inquiry).filter(Inquiry.id == res.inquiry_id).first()
    if inq:
        inq.status = res.status
        db.commit()
        return {"status": "success"}
    return {"error": "Inquiry not found"}

@app.get("/recommendations/fertilizer")
async def get_fertilizer_recommendation(crop: str):
    # Gemini 3 Flash Power: Intelligent Rule-Engine (Mocking AI logic)
    recommendations = {
        "paddy": {
            "fertilizer": "Urea (apply 3 doses), DAP (during transplanting), MOP (at flowering).",
            "pesticide": "Tricyclazole for blast, Carbofuran for stem borer.",
            "tip": "Keep water levels at 2-5cm for first 30 days."
        },
        "maize": {
            "fertilizer": "Urea (side-dressing), Zinc Sulphate (basal dose).",
            "pesticide": "Monocrotophos for fall armyworm.",
            "tip": "Ensure proper drainage during rainy season."
        },
        "cotton": {
            "fertilizer": "NPK 20:20:0:13, Magnesium Sulphate for leaf reddening.",
            "pesticide": "Neem oil for whiteflies, Acephate for jassids.",
            "tip": "Apply PGRs to control vegetative growth if too dense."
        },
        "tomato": {
            "fertilizer": "Calcium Nitrate for blossom end rot prevention, Potash for fruit quality.",
            "pesticide": "Copper Oxychloride for early blight.",
            "tip": "Stake the plants to prevent soil contact for fruits."
        }
    }
    
    crop_lower = crop.lower()
    return recommendations.get(crop_lower, {
        "fertilizer": "Balanced NPK (19:19:19) for general growth.",
        "pesticide": "General bio-pesticide application as needed.",
        "tip": "Monitor soil moisture regularly and ensure proper aeration."
    })

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)