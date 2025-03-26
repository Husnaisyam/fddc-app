import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D
from tensorflow.keras.models import Model
import os

# ✅ Dataset paths
train_dir = "dataset/train"
val_dir = "dataset/validation"

# ✅ Define Image size and batch size
IMG_SIZE = (224, 224)
BATCH_SIZE = 32

# ✅ Load and preprocess images

from tensorflow.keras.preprocessing.image import ImageDataGenerator

train_datagen = ImageDataGenerator(
    rescale=1.0/255,
    rotation_range=40,  # Increase rotation range
    width_shift_range=0.3,
    height_shift_range=0.3,
    shear_range=0.3,
    zoom_range=0.3,
    horizontal_flip=True,
   
)


val_datagen = ImageDataGenerator(rescale=1.0/255)

train_datagen = ImageDataGenerator(rescale=1.0/255)
val_datagen = ImageDataGenerator(rescale=1.0/255)

train_generator = train_datagen.flow_from_directory(
    train_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

val_generator = val_datagen.flow_from_directory(
    val_dir,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical'
)

# ✅ Get class names (for later prediction)
class_names = list(train_generator.class_indices.keys())
print(f"Detected classes: {class_names}")


# ✅ Load MobileNetV2 as base model (pretrained on ImageNet)
base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights="imagenet")
base_model.trainable = False  # Freeze the base model layers

# ✅ Add custom classification layers
x = base_model.output
x = GlobalAveragePooling2D()(x)
x = Dense(128, activation="relu")(x)  # <-- Add (x) here to correctly connect layers
x = Dropout(0.5)(x)  # <-- Add (x) here to correctly connect layers
x = Dense(len(class_names), activation="softmax")(x)  # <-- Add (x) here to correctly connect layers


# ✅ Create final model
model = Model(inputs=base_model.input, outputs=x)

# ✅ Compile the model
model.compile(optimizer="adam", loss="categorical_crossentropy", metrics=["accuracy"])

# ✅ Display model summary
model.summary()



# ✅ Train the model
EPOCHS = 10

history = model.fit(
    train_generator,
    validation_data=val_generator,
    epochs=EPOCHS
)

# ✅ Save the trained model
model.save("food_classification_model.keras")

print("✅ Training complete! Model saved as 'food_classification_model.keras'.")
