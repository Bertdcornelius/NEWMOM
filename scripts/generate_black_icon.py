import sys
from PIL import Image

def generate_black_icon():
    try:
        # Open the original image
        img = Image.open('assets/app_icon.jpeg').convert('RGBA')

        # Crop the bottom 100 pixels to remove sparkle
        width, height = img.size
        img = img.crop((0, 0, width, height - 100))

        pixels = img.load()
        min_x, min_y = width, height
        max_x, max_y = 0, 0

        for y in range(img.height):
            for x in range(img.width):
                r, g, b, a = pixels[x, y]
                intensity = (r + g + b) // 3
                if intensity < 120:
                    if x < min_x: min_x = x
                    if x > max_x: max_x = x
                    if y < min_y: min_y = y
                    if y > max_y: max_y = y

        logo = img.crop((min_x, min_y, max_x, max_y))

        logo_data = logo.getdata()
        clean_data = []

        # Map the color to be pure without the white background mixing
        for item in logo_data:
            r, g, b, a = item
            intensity = (r + g + b) // 3
            
            if intensity > 220:
                clean_data.append((255, 255, 255, 0))
            else:
                # Smooth alpha based on intensity for perfect anti-aliasing
                alpha = max(0, min(255, int(255 - (intensity * 255 / 220))))
                # Set the logo color to PURE BLACK (0, 0, 0) instead of natural slate/teal color
                clean_data.append((0, 0, 0, alpha))

        logo.putdata(clean_data)

        # Create a pristine, pure white 1024x1024 background
        canvas = Image.new('RGBA', (1024, 1024), (255, 255, 255, 255))

        # Scale logo to be about 65% of the canvas
        logo_w, logo_h = logo.size
        target_size = int(1024 * 0.65)
        ratio = min(target_size / logo_w, target_size / logo_h)
        new_w = int(logo_w * ratio)
        new_h = int(logo_h * ratio)

        logo = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)

        offset_x = (1024 - new_w) // 2
        offset_y = (1024 - new_h) // 2

        # Paste the logo perfectly centered
        canvas.paste(logo, (offset_x, offset_y), mask=logo)
        canvas.save('assets/black_flawless_icon.png', 'PNG')
        print('Successfully generated black_flawless_icon.png')
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    generate_black_icon()
