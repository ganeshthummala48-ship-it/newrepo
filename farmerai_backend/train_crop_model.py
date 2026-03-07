import os
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import joblib

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, "data", "crop_data.csv")

print("📂 Script directory:", BASE_DIR)
print("📄 CSV path:", DATA_PATH)
print("📄 File size:", os.path.getsize(DATA_PATH), "bytes")

# 🔥 Auto-detect delimiter (handles Excel / Windows issues)
df = pd.read_csv(
    DATA_PATH,
    sep=None,          # 👈 AUTO detect
    engine="python",   # 👈 required for auto detection
    encoding="utf-8-sig"
)

print("✅ CSV loaded successfully")
print(df.head())
print("🧾 Columns detected:", df.columns.tolist())

required = {'soil', 'season', 'rainfall', 'crop'}
if not required.issubset(df.columns):
    raise ValueError(
        f"❌ CSV format error. Expected columns {required}, "
        f"but got {set(df.columns)}"
    )

# ================= ML =================

soil_encoder = LabelEncoder()
season_encoder = LabelEncoder()
rainfall_encoder = LabelEncoder()
crop_encoder = LabelEncoder()

df['soil'] = soil_encoder.fit_transform(df['soil'])
df['season'] = season_encoder.fit_transform(df['season'])
df['rainfall'] = rainfall_encoder.fit_transform(df['rainfall'])
df['crop'] = crop_encoder.fit_transform(df['crop'])

X = df[['soil', 'season', 'rainfall']]
y = df['crop']

model = RandomForestClassifier(
    n_estimators=200,
    random_state=42
)
model.fit(X, y)

joblib.dump(model, os.path.join(BASE_DIR, "crop_model.pkl"))
joblib.dump(soil_encoder, os.path.join(BASE_DIR, "soil_encoder.pkl"))
joblib.dump(season_encoder, os.path.join(BASE_DIR, "season_encoder.pkl"))
joblib.dump(rainfall_encoder, os.path.join(BASE_DIR, "rainfall_encoder.pkl"))
joblib.dump(crop_encoder, os.path.join(BASE_DIR, "crop_encoder.pkl"))

print("✅ Crop recommendation model trained and saved successfully")
