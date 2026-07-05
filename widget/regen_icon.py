from pathlib import Path
from PIL import Image

src = Path(r"c:/Users/adars/OneDrive/Desktop/THE IDEA/BITEKOI LABS/EverlastimerWidget/resources/icons/AppIcons/android/mipmap-xxxhdpi/texttest..png")
dst = Path(r"c:/Users/adars/OneDrive/Desktop/THE IDEA/BITEKOI LABS/EverlastimerWidget/app.ico")

if not src.exists():
    raise FileNotFoundError(f"Source icon not found: {src}")

img = Image.open(src).convert("RGBA")

sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
img.save(dst, format="ICO", sizes=sizes)
print(f"Generated icon: {dst} ({dst.stat().st_size} bytes)")
