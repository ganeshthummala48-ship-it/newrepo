import tensorflow as tf
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, "model", "plant_disease_model.h5")

try:
    print(f"Attempting to load model from {MODEL_PATH} with compile=False...")
    model = tf.keras.models.load_model(MODEL_PATH, compile=False)
    print("✅ Model loaded successfully with compile=False!")
except Exception as e:
    print(f"❌ Failed to load model even with compile=False: {e}")
