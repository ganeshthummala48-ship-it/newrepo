"""
🍎 Fruits-360 ResNet50 Classifier Trainer
Extracted and optimized from Kaggle Kernel danishmubashar/fruits-360-classified-by-resnet-acc-99-99
"""

import os
import json
import time
import numpy as np
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, callbacks

# Set Random Seeds
SEED = 123
tf.random.set_seed(SEED)
np.random.seed(SEED)

print(f"⚡ TensorFlow Version: {tf.__version__}")
gpus = tf.config.list_physical_devices('GPU')
print(f"🚀 GPUs Available: {gpus}")

# Paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data", "fruits-360")
TRAIN_DIR = os.path.join(DATA_DIR, "Training")
TEST_DIR = os.path.join(DATA_DIR, "Test")

MODEL_OUTPUT = os.path.join(BASE_DIR, "model", "fruits360_model.h5")
LABELS_OUTPUT = os.path.join(BASE_DIR, "model", "fruits360_labels.json")

IMG_SIZE = (100, 100)
BATCH_SIZE = 32

def load_datasets():
    if not os.path.exists(TRAIN_DIR):
        print(f"⚠️ Warning: Dataset path {TRAIN_DIR} not found. Please ensure fruits-360 dataset is unzipped in data/fruits-360.")
        return None, None, None

    print("📊 Loading Training & Validation Datasets...")
    train_ds = tf.keras.preprocessing.image_dataset_from_directory(
        TRAIN_DIR,
        validation_split=0.2,
        subset='training',
        batch_size=BATCH_SIZE,
        image_size=IMG_SIZE,
        seed=SEED,
        shuffle=True
    )

    val_ds = tf.keras.preprocessing.image_dataset_from_directory(
        TRAIN_DIR,
        validation_split=0.2,
        subset='validation',
        batch_size=BATCH_SIZE,
        image_size=IMG_SIZE,
        seed=SEED
    )

    class_names = train_ds.class_names
    print(f"✅ Loaded {len(class_names)} Fruit & Vegetable Classes!")
    return train_ds, val_ds, class_names

def build_resnet_model(num_classes):
    print("🏗️ Building ResNet50 Transfer Learning Architecture...")
    data_augmentation = tf.keras.Sequential([
        layers.RandomFlip('horizontal'),
        layers.RandomRotation(0.2)
    ])

    inputs = keras.Input(shape=(100, 100, 3))
    x = data_augmentation(inputs)
    x = keras.applications.resnet.preprocess_input(x)

    base_model = keras.applications.ResNet50(
        include_top=False,
        weights='imagenet',
        input_shape=(100, 100, 3)
    )
    base_model.trainable = False  # Freeze pre-trained weights

    x = base_model(x, training=False)
    x = layers.GlobalAveragePooling2D()(x)
    x = layers.Dropout(0.2)(x)
    outputs = layers.Dense(num_classes)(x)

    model = keras.Model(inputs=inputs, outputs=outputs)

    optimizer = keras.optimizers.Adam(learning_rate=0.0001)
    model.compile(
        optimizer=optimizer,
        loss=keras.losses.SparseCategoricalCrossentropy(from_logits=True),
        metrics=['accuracy']
    )
    return model

def train():
    train_ds, val_ds, class_names = load_datasets()
    if train_ds is None:
        return

    # Cache class names JSON
    os.makedirs(os.path.dirname(LABELS_OUTPUT), exist_ok=True)
    labels_map = {idx: name for idx, name in enumerate(class_names)}
    with open(LABELS_OUTPUT, "w") as f:
        json.dump(labels_map, f, indent=4)
    print(f"💾 Class map saved to {LABELS_OUTPUT}")

    # Prefetch for optimal throughput
    AUTOTUNE = tf.data.experimental.AUTOTUNE
    train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

    num_classes = len(class_names)
    model = build_resnet_model(num_classes=num_classes)
    print(model.summary())

    early_stopping = callbacks.EarlyStopping(monitor='val_accuracy', patience=4, restore_best_weights=True)
    checkpoint = callbacks.ModelCheckpoint(filepath=MODEL_OUTPUT, monitor='val_accuracy', save_best_only=True)

    print("🔥 Starting ResNet50 Training (10 Epochs)...")
    history = model.fit(
        train_ds,
        epochs=10,
        validation_data=val_ds,
        callbacks=[early_stopping, checkpoint]
    )

    print(f"🎉 Training Complete! Model saved to {MODEL_OUTPUT}")

if __name__ == "__main__":
    train()
