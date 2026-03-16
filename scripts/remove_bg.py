import sys
from PIL import Image

def remove_white_background(input_path, output_path, tolerance=50):
    try:
        # Open the image and convert it to RGBA
        img = Image.open(input_path).convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            # item is (R, G, B, A)
            # Check if pixel is close to white based on tolerance
            if item[0] >= 255 - tolerance and item[1] >= 255 - tolerance and item[2] >= 255 - tolerance:
                # Change to transparent
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)

        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Successfully processed {input_path} and saved to {output_path}")
        
    except Exception as e:
        print(f"Error processing image: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python remove_bg.py <input_image> <output_image>")
        sys.exit(1)
        
    input_img = sys.argv[1]
    output_img = sys.argv[2]
    
    remove_white_background(input_img, output_img)
