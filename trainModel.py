import tensorflow as tf
import tensorflow_datasets as tfds
import matplotlib.pyplot as plt

# Load the dataset
dataset, info = tfds.load('food101', split='train[:10%]', as_supervised=True, with_info=True)

# Display sample images
def show_images(dataset, num=5):
    plt.figure(figsize=(10, 5))
    for i, (image, label) in enumerate(dataset.take(num)):
        plt.subplot(1, num, i+1)
        plt.imshow(image.numpy())
        plt.axis("off")
    plt.show()

show_images(dataset)
