#!/usr/bin/env python3
"""
Generate Bond to Ten app icon with number blocks design
Creates icons in all required iOS sizes
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Icon sizes needed for iOS
ICON_SIZES = [
    (20, "@1x"), (40, "@2x"), (60, "@3x"),  # 20x20
    (29, "@1x"), (58, "@2x"), (87, "@3x"),  # 29x29
    (40, "@1x"), (80, "@2x"), (120, "@3x"), # 40x40
    (120, "@2x"), (180, "@3x"),             # 60x60
    (76, "@1x"), (152, "@2x"),              # 76x76
    (167, "@2x"),                           # 83.5x83.5
    (1024, "@1x")                           # 1024x1024
]

def create_bond_to_ten_icon(size):
    """Create Bond to Ten icon with proper base-10 blocks representation"""
    
    # Create image with white background (typical for educational apps)
    img = Image.new('RGB', (size, size), '#FFFFFF')
    draw = ImageDraw.Draw(img)
    
    # Calculate sizes based on icon size
    margin = size // 12
    content_size = size - 2 * margin
    
    # Colors for different base-10 blocks
    unit_color = '#4CAF50'      # Green for units (1s)
    ten_color = '#FF9800'       # Orange for tens  
    hundred_color = '#2196F3'   # Blue for hundreds
    border_color = '#333333'    # Dark border
    
    # Font setup
    try:
        font_size = max(size // 20, 8)
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", font_size)
        title_font_size = max(size // 25, 6)
        title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", title_font_size)
    except:
        try:
            font = ImageFont.load_default()
            title_font = font
        except:
            font = None
            title_font = None
    
    # Draw the iconic base-10 blocks layout
    
    # 1. Draw the hundred square (top area)
    hundred_size = content_size // 3
    hundred_x = margin + (content_size - hundred_size) // 2
    hundred_y = margin
    
    # Create hundred square as a 10x10 grid
    cell_size = max(1, hundred_size // 10)
    for row in range(10):
        for col in range(10):
            cell_x = hundred_x + col * cell_size
            cell_y = hundred_y + row * cell_size
            cell_x2 = cell_x + cell_size - 1
            cell_y2 = cell_y + cell_size - 1
            # Ensure coordinates are valid
            if cell_x2 > cell_x and cell_y2 > cell_y:
                draw.rectangle(
                    [cell_x, cell_y, cell_x2, cell_y2],
                    fill=hundred_color,
                    outline=border_color,
                    width=1
                )
    
    # Add "100" label
    if font:
        text = "100"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        text_x = hundred_x + (hundred_size - text_width) // 2
        text_y = hundred_y + hundred_size + 2
        draw.text((text_x, text_y), text, fill=border_color, font=font)
    
    # 2. Draw ten strip (middle left)
    ten_width = content_size // 2
    ten_height = content_size // 12
    ten_x = margin
    ten_y = hundred_y + hundred_size + margin
    
    # Create ten strip as 10 connected units
    unit_width = max(1, ten_width // 10)
    for i in range(10):
        unit_x = ten_x + i * unit_width
        unit_x2 = unit_x + unit_width - 1
        unit_y2 = ten_y + ten_height
        # Ensure coordinates are valid
        if unit_x2 > unit_x and unit_y2 > ten_y:
            draw.rectangle(
                [unit_x, ten_y, unit_x2, unit_y2],
                fill=ten_color,
                outline=border_color,
                width=1
            )
    
    # Add "10" label
    if font:
        text = "10"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = ten_x + (ten_width - text_width) // 2
        text_y = ten_y + ten_height + 2
        draw.text((text_x, text_y), text, fill=border_color, font=font)
    
    # 3. Draw single unit (bottom right)
    unit_size = content_size // 8
    unit_x = margin + content_size - unit_size
    unit_y = ten_y + ten_height + margin // 2
    
    draw.rectangle(
        [unit_x, unit_y, unit_x + unit_size, unit_y + unit_size],
        fill=unit_color,
        outline=border_color,
        width=2
    )
    
    # Add "1" label
    if font:
        text = "1"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = unit_x + (unit_size - text_width) // 2
        text_y = unit_y + unit_size + 2
        draw.text((text_x, text_y), text, fill=border_color, font=font)
    
    # Add rounded corner border for the whole icon (optional)
    if size >= 100:
        border_radius = size // 20
        # Draw a subtle border around the entire icon
        draw.rounded_rectangle(
            [2, 2, size-3, size-3],
            radius=border_radius,
            fill=None,
            outline='#E0E0E0',
            width=2
        )
    
    return img

def generate_ios_icons():
    """Generate all iOS icon sizes"""
    
    # Create output directory
    icon_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icon_dir, exist_ok=True)
    
    # Generate icons for each size
    for size_info in ICON_SIZES:
        if len(size_info) == 2:
            size, scale = size_info
            base_size = {
                "@1x": size,
                "@2x": size // 2,
                "@3x": size // 3
            }.get(scale, size)
        else:
            size = size_info[0]
            scale = "@1x"
            base_size = size
        
        # Create icon
        icon = create_bond_to_ten_icon(size)
        
        # Determine filename based on size
        if size == 1024:
            filename = "Icon-App-1024x1024@1x.png"
        elif base_size == 20:
            filename = f"Icon-App-20x20{scale}.png"
        elif base_size == 29:
            filename = f"Icon-App-29x29{scale}.png"
        elif base_size == 40:
            filename = f"Icon-App-40x40{scale}.png"
        elif base_size == 60:
            filename = f"Icon-App-60x60{scale}.png"
        elif base_size == 76:
            filename = f"Icon-App-76x76{scale}.png"
        elif size == 167:
            filename = "Icon-App-83.5x83.5@2x.png"
        else:
            filename = f"Icon-App-{size}x{size}.png"
        
        # Save icon
        filepath = os.path.join(icon_dir, filename)
        icon.save(filepath, "PNG")
        print(f"Generated: {filename} ({size}x{size})")

if __name__ == "__main__":
    print("Generating Bond to Ten app icons...")
    generate_ios_icons()
    print("Icon generation complete!")
    print("\nNext steps:")
    print("1. Run: flutter clean")
    print("2. Run: flutter build ios --release")
    print("3. Install to iPhone")

