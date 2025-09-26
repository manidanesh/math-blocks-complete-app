#!/usr/bin/env python3
"""
Generate proper Bond to Ten app icon with base-10 blocks
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
    """Create Bond to Ten icon with proper mathematical base-10 blocks"""
    
    # Create image with white background
    img = Image.new('RGB', (size, size), '#FFFFFF')
    draw = ImageDraw.Draw(img)
    
    # Calculate proportional sizes
    margin = max(2, size // 20)
    content_area = size - 2 * margin
    
    # Educational colors for math blocks
    hundred_color = '#1E88E5'    # Blue for hundreds
    ten_color = '#FF7043'        # Orange for tens  
    unit_color = '#66BB6A'       # Green for units
    text_color = '#263238'       # Dark gray for text
    border_color = '#424242'     # Medium gray for borders
    
    # Font setup
    try:
        if size >= 100:
            font_size = max(8, size // 25)
            font = ImageFont.truetype("/System/Library/Fonts/Helvetica-Bold.ttc", font_size)
        else:
            font = None
    except:
        font = None
    
    # Layout: Arrange blocks vertically for clarity
    block_spacing = max(2, content_area // 20)
    
    # 1. Draw hundred block (top) - 10x10 grid of small squares
    hundred_size = min(content_area // 3, content_area - 2 * block_spacing)
    hundred_x = margin + (content_area - hundred_size) // 2
    hundred_y = margin
    
    if hundred_size > 10:  # Only draw if large enough
        cell_size = max(1, hundred_size // 10)
        
        # Draw the 10x10 grid
        for row in range(10):
            for col in range(10):
                if cell_size >= 1:
                    x1 = hundred_x + col * cell_size
                    y1 = hundred_y + row * cell_size
                    x2 = x1 + cell_size - 1
                    y2 = y1 + cell_size - 1
                    
                    if x2 > x1 and y2 > y1:
                        draw.rectangle([x1, y1, x2, y2], 
                                     fill=hundred_color, 
                                     outline=border_color,
                                     width=1 if size >= 60 else 0)
        
        # Add "100" label below
        if font and size >= 60:
            draw.text((hundred_x + hundred_size//2 - 10, hundred_y + hundred_size + 2), 
                     "100", fill=text_color, font=font, anchor="mt")
    
    # 2. Draw ten strip (middle) - 10 connected rectangles
    ten_y = hundred_y + hundred_size + block_spacing
    ten_width = min(content_area * 3 // 4, hundred_size)
    ten_height = max(2, content_area // 15)
    ten_x = margin + (content_area - ten_width) // 2
    
    if ten_width > 10 and ten_height > 0:
        unit_width = max(1, ten_width // 10)
        
        for i in range(10):
            if unit_width >= 1:
                x1 = ten_x + i * unit_width
                y1 = ten_y
                x2 = x1 + unit_width - 1
                y2 = y1 + ten_height
                
                if x2 > x1 and y2 > y1:
                    draw.rectangle([x1, y1, x2, y2], 
                                 fill=ten_color, 
                                 outline=border_color,
                                 width=1 if size >= 60 else 0)
        
        # Add "10" label below
        if font and size >= 60:
            draw.text((ten_x + ten_width//2, ten_y + ten_height + 2), 
                     "10", fill=text_color, font=font, anchor="mt")
    
    # 3. Draw unit cube (bottom) - single square
    unit_y = ten_y + ten_height + block_spacing
    unit_size = max(4, min(content_area // 8, hundred_size // 4))
    unit_x = margin + (content_area - unit_size) // 2
    
    if unit_size > 2:
        draw.rectangle([unit_x, unit_y, unit_x + unit_size, unit_y + unit_size], 
                      fill=unit_color, 
                      outline=border_color,
                      width=2 if size >= 60 else 1)
        
        # Add "1" label below
        if font and size >= 60:
            draw.text((unit_x + unit_size//2, unit_y + unit_size + 2), 
                     "1", fill=text_color, font=font, anchor="mt")
    
    # Add subtle rounded border for larger icons
    if size >= 120:
        border_radius = size // 25
        draw.rounded_rectangle([1, 1, size-2, size-2], 
                              radius=border_radius,
                              outline='#E0E0E0', 
                              width=1)
    
    return img

def generate_ios_icons():
    """Generate all iOS icon sizes"""
    
    # Create output directory
    icon_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(icon_dir, exist_ok=True)
    
    print("Generating proper Bond to Ten app icons...")
    
    # Generate icons for each size
    for size_info in ICON_SIZES:
        if len(size_info) == 2:
            size, scale = size_info
            # Calculate base size from scale
            if scale == "@2x":
                base_size = size // 2
            elif scale == "@3x":
                base_size = size // 3
            else:
                base_size = size
        else:
            size = size_info[0]
            scale = "@1x"
            base_size = size
        
        # Create icon
        icon = create_bond_to_ten_icon(size)
        
        # Determine filename based on base size
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
        print(f"✅ Generated: {filename} ({size}x{size})")

if __name__ == "__main__":
    generate_ios_icons()
    print("\n🎉 Bond to Ten icon generation complete!")
    print("📱 Icons created with proper base-10 blocks representation:")
    print("   • Blue 10x10 grid (hundreds)")
    print("   • Orange strip of 10 units (tens)")  
    print("   • Green single square (units)")
    print("\nNext steps:")
    print("1. flutter clean")
    print("2. flutter build ios --release")
    print("3. Install to iPhone")
