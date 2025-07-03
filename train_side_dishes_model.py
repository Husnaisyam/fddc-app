import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D
from tensorflow.keras.models import Model
import os

# Dataset paths for side dishes
train_dir = "dataset_side_dishes/train"
val_dir = "dataset_side_dishes/validation"

# Define Image size and batch size
IMG_SIZE = (224, 224)
BATCH_SIZE = 32

# Data augmentation for training
train_datagen = ImageDataGenerator(
    rescale=1.0/255,
    rotation_range=40,
    width_shift_range=0.3,
    height_shift_range=0.3,
    shear_range=0.3,
    zoom_range=0.3,
    horizontal_flip=True,
)

# Validation data only needs rescaling
val_datagen = ImageDataGenerator(rescale=1.0/255)

# Set up data generators for binary classification
train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',  # Changed to binary
    shuffle=True
)

val_generator = val_datagen.flow_from_directory(
    val_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='binary',  # Changed to binary
    shuffle=True
)

# Get class names (side dishes)
class_names = list(train_generator.class_indices.keys())
print(f"Detected side dishes: {class_names}")

# Load MobileNetV2 as base model
base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights="imagenet")
base_model.trainable = False

# Add custom classification layers
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(128, activation="relu")(x)
x = Dropout(0.5)(x)
x = Dense(1, activation="sigmoid")(x)  # Changed to single output with sigmoid

# Create final model
model = Model(inputs=base_model.input, outputs=x)

# Compile the model
model.compile(
    optimizer="adam",
    loss="binary_crossentropy",  # Changed to binary crossentropy
    metrics=["accuracy"]
)

# Display model summary
model.summary()

# Train the model
EPOCHS = 15

history = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS
)

# Save the trained model
model.save("nasi_lemak_side_dishes_model.keras")

print("✅ Training complete! Model saved as 'nasi_lemak_side_dishes_model.keras'.")