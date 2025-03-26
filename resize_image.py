import os
from PIL import Image

# Define dataset directory
dataset_dir = "dataset"  # Change if your folder name is different
target_size = (224, 224)  # Standard size for MobileNet & ResNet

# Function to resize images
def resize_images(directory):
    for category in os.listdir(directory):
        category_path = os.path.join(directory, category)
        if os.path.isdir(category_path):
            for img_name in os.listdir(category_path):
                img_path = os.path.join(category_path, img_name)
                if img_path.endswith((".jpg", ".png", ".jpeg")):
                    img = Image.open(img_path)
                    img = img.resize(target_size)  # Resize to 224x224
                    img.save(img_path)  # Overwrite with resized image

# Resize images in dataset
resize_images(dataset_dir)

print("✅ All images resized to 224x224!")
