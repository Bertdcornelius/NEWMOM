import 'dart:io';
import 'package:image/image.dart';

void main() {
  print('Loading logo.png...');
  final file = File('assets/logo.png');
  final image = decodeImage(file.readAsBytesSync());
  if (image == null) {
    print('Failed to load image');
    return;
  }
  
  // Make all pure white pixels transparent
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      if (p.r >= 240 && p.g >= 240 && p.b >= 240) {
        // High tolerance for white
        image.setPixelRgba(x, y, 255, 255, 255, 0); 
      }
    }
  }
  
  File('assets/logo_transparent.png').writeAsBytesSync(encodePng(image));
  print('Saved assets/logo_transparent.png successfully');
}
