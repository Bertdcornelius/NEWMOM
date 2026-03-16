import sys
from PIL import Image

def process_image(input_path, output_path, tolerance=30):
    try:
        img = Image.open(input_path).convert("RGBA")
        width, height = img.size
        
        # 1. First, find the bounding box of the main logo.
        #    We ignore the bottom 100 pixels to exclude the sparkle icon.
        min_x = width
        min_y = height
        max_x = 0
        max_y = 0
        
        pixels = img.load()
        for y in range(height - 100):  # Ignore bottom 100 pixels
            for x in range(width):
                r, g, b, a = pixels[x, y]
                # If pixel is significantly darker than white
                if r < 255 - tolerance or g < 255 - tolerance or b < 255 - tolerance:
                    if x < min_x: min_x = x
                    if x > max_x: max_x = x
                    if y < min_y: min_y = y
                    if y > max_y: max_y = y
                    
        # Add a little padding
        padding = 10
        min_x = max(0, min_x - padding)
        min_y = max(0, min_y - padding)
        max_x = min(width, max_x + padding)
        max_y = min(height, max_y + padding)
        
        # Crop the image to just the logo
        img = img.crop((min_x, min_y, max_x, max_y))
        
        # 2. Make white background transparent
        datas = img.getdata()
        newData = []
        for item in datas:
            r, g, b, a = item
            if r >= 255 - tolerance and g >= 255 - tolerance and b >= 255 - tolerance:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)
                
        img.putdata(newData)
        
        # 3. Add equal padding to make it square, so the logo scales nicely and stays centered
        new_width, new_height = img.size
        max_dim = max(new_width, new_height)
        square_img = Image.new("RGBA", (max_dim + 40, max_dim + 40), (255, 255, 255, 0))
        paste_x = (max_dim + 40 - new_width) // 2
        paste_y = (max_dim + 40 - new_height) // 2
        
        square_img.paste(img, (paste_x, paste_y))
        
        square_img.save(output_path, "PNG")
        print(f"Successfully processed {input_path} and saved to {output_path}")
        print(f"Cropped to box: {min_x}, {min_y}, {max_x}, {max_y}")
        
    except Exception as e:
        print(f"Error processing image: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python process_logo.py <input> <output>")
        sys.exit(1)
        
    process_image(sys.argv[1], sys.argv[2])
