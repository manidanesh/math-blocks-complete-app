#!/usr/bin/env python3
"""
Resize Bond to Ten icons to all required iOS sizes
"""

from PIL import Image
import os

# Define the target sizes based on iOS requirements
ICON_SIZES = [
    # iPhone
    (40, "Icon-App-20x20@2x.png"),     # 20x20@2x
    (60, "Icon-App-20x20@3x.png"),     # 20x20@3x  
    (29, "Icon-App-29x29@1x.png"),     # 29x29@1x
    (58, "Icon-App-29x29@2x.png"),     # 29x29@2x
    (87, "Icon-App-29x29@3x.png"),     # 29x29@3x
    (80, "Icon-App-40x40@2x.png"),     # 40x40@2x
    (120, "Icon-App-40x40@3x.png"),    # 40x40@3x
    (120, "Icon-App-60x60@2x.png"),    # 60x60@2x (correcting the previous copy)
    
    # iPad  
    (20, "Icon-App-20x20@1x.png"),     # 20x20@1x
    (40, "Icon-App-40x40@1x.png"),     # 40x40@1x
    
    # App Store
    (1024, "Icon-App-1024x1024@1x.png"), # 1024x1024@1x
]

def resize_icon(source_path, target_size, target_filename):
    """Resize an icon to target size"""
    try:
        # Open the source image
        with Image.open(source_path) as img:
            # Resize with high-quality resampling
            resized_img = img.resize((target_size, target_size), Image.Resampling.LANCZOS)
            
            # Save to target location
            target_path = f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{target_filename}"
            resized_img.save(target_path, "PNG")
            print(f"✅ Created {target_filename} ({target_size}x{target_size})")
            
    except Exception as e:
        print(f"❌ Error creating {target_filename}: {e}")

def main():
    # Use the largest available icon as source (167x167)
    source_icon = "icon/bond_to_ten_icon_167x167.png"
    
    if not os.path.exists(source_icon):
        print(f"❌ Source icon not found: {source_icon}")
        return
    
    print("🎨 Generating missing iOS app icons...")
    
    # Create all missing icon sizes
    for target_size, target_filename in ICON_SIZES:
        target_path = f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{target_filename}"
        
        # Only create if doesn't exist or if we need to fix the size
        if not os.path.exists(target_path) or target_filename == "Icon-App-60x60@2x.png":
            resize_icon(source_icon, target_size, target_filename)
        else:
            print(f"⏭️  Skipped {target_filename} (already exists)")
    
    print("\n🎉 Icon generation complete!")
    print("📱 Ready to build and deploy to iPhone!")

if __name__ == "__main__":
    main()
