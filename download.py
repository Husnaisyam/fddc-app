from bing_image_downloader import downloader

categories = ["nasi lemak"]
save_path = "dataset/nasilemak"

for category in categories:
    downloader.download(category, limit=20, output_dir=save_path, adult_filter_off=True, force_replace=False, timeout=60)

print("✅ ketupat ")
