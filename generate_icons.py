import os
import subprocess
import json

# 配置
src_image = "ic_launcher.png"
output_dir = "Assets.xcassets/AppIcon.appiconset"
os.makedirs(output_dir, exist_ok=True)

# 定义需要生成的尺寸
# (filename, size)
icons = [
    ("20.png", 20),
    ("29.png", 29),
    ("40.png", 40),
    ("58.png", 58),
    ("60.png", 60),
    ("76.png", 76),
    ("80.png", 80),
    ("87.png", 87),
    ("120.png", 120),
    ("152.png", 152),
    ("167.png", 167),
    ("180.png", 180),
    ("1024.png", 1024)
]

print(f"🚀 Generating icons from {src_image}...")

# 生成图片
for filename, size in icons:
    output_path = os.path.join(output_dir, filename)
    print(f"  Processing {filename} ({size}x{size})...")
    subprocess.run(["sips", "-z", str(size), str(size), src_image, "--out", output_path], check=True)

# 生成 Contents.json
contents = {
  "images" : [
    { "size" : "20x20", "idiom" : "iphone", "filename" : "40.png", "scale" : "2x" },
    { "size" : "20x20", "idiom" : "iphone", "filename" : "60.png", "scale" : "3x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "58.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "iphone", "filename" : "87.png", "scale" : "3x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "80.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "iphone", "filename" : "120.png", "scale" : "3x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "120.png", "scale" : "2x" },
    { "size" : "60x60", "idiom" : "iphone", "filename" : "180.png", "scale" : "3x" },
    { "size" : "20x20", "idiom" : "ipad", "filename" : "20.png", "scale" : "1x" },
    { "size" : "20x20", "idiom" : "ipad", "filename" : "40.png", "scale" : "2x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "29.png", "scale" : "1x" },
    { "size" : "29x29", "idiom" : "ipad", "filename" : "58.png", "scale" : "2x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "40.png", "scale" : "1x" },
    { "size" : "40x40", "idiom" : "ipad", "filename" : "80.png", "scale" : "2x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "76.png", "scale" : "1x" },
    { "size" : "76x76", "idiom" : "ipad", "filename" : "152.png", "scale" : "2x" },
    { "size" : "83.5x83.5", "idiom" : "ipad", "filename" : "167.png", "scale" : "2x" },
    { "size" : "1024x1024", "idiom" : "ios-marketing", "filename" : "1024.png", "scale" : "1x" }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}

with open(os.path.join(output_dir, "Contents.json"), "w") as f:
    json.dump(contents, f, indent=2)

print("✅ Done!")
