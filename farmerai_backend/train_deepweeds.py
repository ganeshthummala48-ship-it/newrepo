"""
🌾 DeepWeeds Classification Trainer
Extracted and optimized from Kaggle Kernel imsparsh/deepweeds-classification
"""

import os
import sys
import time
import random
import json
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, models, callbacks

# Set random seeds for reproducibility
SEED = 12
os.environ['PYTHONHASHSEED'] = str(SEED)
tf.random.set_seed(SEED)
np.random.seed(SEED)
random.seed(SEED)

print(f"⚡ TensorFlow Version: {tf.__version__}")
gpus = tf.config.list_physical_devices('GPU')
print(f"🚀 GPUs Available: {gpus}")

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data", "deepweeds")
IMG_DIR = os.path.join(DATA_DIR, "images")
LABELS_DIR = os.path.join(DATA_DIR, "labels")
LABELS_CSV = os.path.join(LABELS_DIR, "labels.csv")
MODEL_OUTPUT = os.path.join(BASE_DIR, "model", "deepweeds_model.h5")
LABELS_OUTPUT = os.path.join(BASE_DIR, "model", "deepweeds_labels.json")

def load_data():
    if not os.path.exists(LABELS_CSV):
        raise FileNotFoundError(f"Missing labels.csv at {LABELS_CSV}. Please ensure dataset is downloaded.")
    
    print("📊 Loading dataset labels...")
    train_subsets = []
    val_subsets = []
    test_subsets = []

    for x in range(5):
        train_path = os.path.join(LABELS_DIR, f"train_subset{x}.csv")
        val_path = os.path.join(LABELS_DIR, f"val_subset{x}.csv")
        test_path = os.path.join(LABELS_DIR, f"test_subset{x}.csv")
        
        if os.path.exists(train_path):
            train_subsets.append(pd.read_csv(train_path))
        if os.path.exists(val_path):
            val_subsets.append(pd.read_csv(val_path))
        if os.path.exists(test_path):
            test_subsets.append(pd.read_csv(test_path))

    train_df = pd.concat(train_subsets, axis=0, ignore_index=True)
    val_df = pd.concat(val_subsets, axis=0, ignore_index=True)
    test_df = pd.concat(test_subsets, axis=0, ignore_index=True) if test_subsets else val_df

    df_train = train_df.sample(frac=1, random_state=SEED+568).reset_index(drop=True)
    df_train['Label'] = df_train['Label'].astype(str)

    df_val = val_df.sample(frac=1, random_state=SEED+568).reset_index(drop=True)
    df_val['Label'] = df_val['Label'].astype(str)

    print(f"✅ Loaded {len(df_train)} training images, {len(df_val)} validation images.")
    return df_train, df_val

def build_model(num_classes, img_dim=224):
    print(f"🏗️ Building MobileNetV2 feature extractor (Input: {img_dim}x{img_dim}x3)...")
    base_model = keras.applications.MobileNetV2(
        weights='imagenet',
        input_shape=(img_dim, img_dim, 3),
        include_top=False
    )
    base_model.trainable = False  # Transfer learning freeze

    model = models.Sequential([
        base_model,
        layers.GlobalAveragePooling2D(),
        layers.Dropout(0.3),
        layers.Dense(256, activation='relu'),
        layers.Dropout(0.25),
        layers.Dense(num_classes, activation='softmax')
    ])

    model.compile(
        optimizer='adam',
        loss='categorical_crossentropy',
        metrics=['accuracy', keras.metrics.Precision(), keras.metrics.Recall()]
    )
    return model

def train():
    df_train, df_val = load_data()
    
    batch_size = 64
    img_dim = 224
    num_classes = df_train['Label'].nunique()

    print(f"🌱 Number of Weed Classes: {num_classes}")

    train_datagen = keras.preprocessing.image.ImageDataGenerator(
        rescale=1./255,
        shear_range=0.2,
        horizontal_flip=True,
        zoom_range=0.2
    )

    val_datagen = keras.preprocessing.image.ImageDataGenerator(rescale=1./255)

    train_generator = train_datagen.flow_from_dataframe(
        directory=IMG_DIR,
        dataframe=df_train,
        x_col='Filename',
        y_col='Label',
        batch_size=batch_size,
        color_mode="rgb",
        seed=SEED,
        shuffle=True,
        class_mode="categorical",
        target_size=(img_dim, img_dim)
    )

    val_generator = val_datagen.flow_from_dataframe(
        directory=IMG_DIR,
        dataframe=df_val,
        x_col='Filename',
        y_col='Label',
        batch_size=batch_size,
        color_mode="rgb",
        seed=SEED,
        shuffle=False,
        class_mode="categorical",
        target_size=(img_dim, img_dim)
    )

    # Save class indices mapping
    os.makedirs(os.path.dirname(LABELS_OUTPUT), exist_ok=True)
    labels_map = {v: k for k, v in train_generator.class_indices.items()}
    with open(LABELS_OUTPUT, "w") as f:
        json.dump(labels_map, f, indent=4)
    print(f"💾 Class labels saved to {LABELS_OUTPUT}")

    model = build_model(num_classes=num_classes, img_dim=img_dim)
    print(model.summary())

    cb_list = [
        callbacks.ReduceLROnPlateau(monitor='val_loss', patience=3, verbose=1, min_lr=1e-5),
        callbacks.EarlyStopping(monitor='val_loss', patience=6, verbose=1, restore_best_weights=True),
        callbacks.ModelCheckpoint(filepath=MODEL_OUTPUT, monitor='val_loss', verbose=1, save_best_only=True)
    ]

    steps_per_epoch = int(np.ceil(train_generator.n / train_generator.batch_size))
    validation_steps = int(np.ceil(val_generator.n / val_generator.batch_size))

    print(f"🔥 Starting Training for 15 Epochs...")
    history = model.fit(
        train_generator,
        steps_per_epoch=steps_per_epoch,
        validation_data=val_generator,
        validation_steps=validation_steps,
        epochs=15,
        callbacks=cb_list
    )

    print(f"🎉 Training Complete! Best model saved to: {MODEL_OUTPUT}")

if __name__ == "__main__":
    train()
