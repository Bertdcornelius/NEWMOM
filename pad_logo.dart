import 'dart:io';
import 'package:image/image.dart';

void main() {
  print('Loading logo_transparent.png...');
  final file = File('assets/logo_transparent.png');
  final original = decodeImage(file.readAsBytesSync());
  if (original == null) {
    print('Failed to load image');
    return;
  }
  
  // Calculate new size (e.g. 50% larger canvas)
  final int newWidth = (original.width * 1.5).round();
  final int newHeight = (original.height * 1.5).round();
  
  // Create a new empty image with a fully transparent background
  final paddedImage = Image(width: newWidth, height: newHeight);
  // Fill with fully transparent pixels
  fill(paddedImage, color: ColorUint8.rgba(255, 255, 255, 0));
  
  // Calculate center position
  final dstX = ((newWidth - original.width) / 2).round();
  final dstY = ((newHeight - original.height) / 2).round();
  
  // Draw the original image into the center of the padded canvas using compositeImage
  compositeImage(paddedImage, original, dstX: dstX, dstY: dstY);
  
  // Save as logo_padded.png
  File('assets/logo_padded.png').writeAsBytesSync(encodePng(paddedImage));
  print('Saved assets/logo_padded.png successfully with transparent padding');
}
