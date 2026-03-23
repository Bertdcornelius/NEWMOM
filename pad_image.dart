import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final path = 'assets/logo.png';
  final outPath = 'assets/logo_superset_style.png';

  final file = File(path);
  if (!file.existsSync()) {
    print('Original logo.png not found at \$path');
    exit(1);
  }

  final imageBytes = file.readAsBytesSync();
  final originalFormat = img.decodeImage(imageBytes)!;
  
  // Android adaptive icons only show the inner 66% (circle/squircle masks).
  // Thus, the logo needs extreme padding to not get its edges sliced off.
  // 1024x1024 is the standard size. Let's make the canvas massive compared to the logo.
  final newW = (originalFormat.width * 2.2).toInt();
  final newH = (originalFormat.height * 2.2).toInt();
  
  // Base canvas initialized fully white with full opacity
  final newImg = img.Image(width: newW, height: newH);
  img.fill(newImg, color: img.ColorRgba8(255, 255, 255, 255));
  
  final offsetX = (newW - originalFormat.width) ~/ 2;
  final offsetY = (newH - originalFormat.height) ~/ 2;
  
  // Composite original image over the white background
  img.compositeImage(newImg, originalFormat, dstX: offsetX, dstY: offsetY);
  
  File(outPath).writeAsBytesSync(img.encodePng(newImg));
  print('Padded image generated successfully at \$outPath');
}
