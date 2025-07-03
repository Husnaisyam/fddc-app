from bing_image_downloader import downloader

categories = ["nasi ayam"]
save_path = "dataset/train/nasi ayam"

for category in categories:
    downloader.download(category, limit=20, output_dir=save_path, adult_filter_off=True, force_replace=False, timeout=60)

print("✅ done ")
