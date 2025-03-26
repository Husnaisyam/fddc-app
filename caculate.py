import os

# Define dataset path
train_dir = "dataset/train"
val_dir = "dataset/validation"

# Function to count images in each category
def count_images(directory):
    for category in os.listdir(directory):
        category_path = os.path.join(directory, category)
        if os.path.isdir(category_path):
            print(f"{category}: {len(os.listdir(category_path))} images")

# Count images in training set
print("📌 Training Set:")
count_images(train_dir)

# Count images in validation set
print("\n📌 Validation Set:")
count_images(val_dir)
