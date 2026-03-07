import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.models import Model
import os
import json

# 📂 Path to dataset (numeric folders: 0–37)
DATASET_DIR = r'C:\Users\Ganesh\Documents\FarmerAI\dataset\plant_disease\data_distribution_for_SVM\train'

# 📁 Output directory
MODEL_DIR = "model"
os.makedirs(MODEL_DIR, exist_ok=True)

IMAGE_SIZE = (224, 224)
BATCH_SIZE = 32
EPOCHS = 10

# 🔄 Data preprocessing
datagen = ImageDataGenerator(
    rescale=1.0 / 255.0,
    validation_split=0.2
)

# 🔢 Ensure classes are in numerical order (0 to class_count-1)
class_names = [str(i) for i in range(38)] # Adjust if number of classes changes

train_data = datagen.flow_from_directory(
    DATASET_DIR,
    target_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    subset="training",
    classes=class_names, # 👈 Force numerical order
    shuffle=True
)

val_data = datagen.flow_from_directory(
    DATASET_DIR,
    target_size=IMAGE_SIZE,
    batch_size=BATCH_SIZE,
    class_mode="categorical",
    subset="validation",
    classes=class_names, # 👈 Force numerical order
    shuffle=False
)

print("✅ Classes detected:", train_data.num_classes)
print("📂 Class mapping index:", train_data.class_indices)


# 🧠 Base model
# ----------------------------
# 1️⃣ Build base model
# ----------------------------
base_model = MobileNetV2(
    weights="imagenet",
    include_top=False,
    input_shape=(224, 224, 3)
)

base_model.trainable = False  # Freeze base layers

# ----------------------------
# 2️⃣ Add custom head
# ----------------------------
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(128, activation="relu")(x)
output = Dense(train_data.num_classes, activation="softmax")(x)

model = Model(inputs=base_model.input, outputs=output)

# ----------------------------
# 3️⃣ First training (feature extraction)
# ----------------------------
model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    train_data,
    validation_data=val_data,
    epochs=EPOCHS
)

# ----------------------------
# 4️⃣ 🔥 FINE-TUNING (PASTE HERE)
# ----------------------------
base_model.trainable = True

model.compile(
    optimizer=tf.keras.optimizers.Adam(1e-5),
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.fit(
    train_data,
    validation_data=val_data,
    epochs=5
)

# ----------------------------
# 5️⃣ Save improved model
# ----------------------------
model.save("model/plant_disease_model.h5")
