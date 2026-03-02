import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  for (final file in dir.listSync(recursive: true).whereType<File>().where((f)=>f.path.endsWith('.dart'))) {
    var text = file.readAsStringSync();
    
    // specifically target widgets that take PremiumColors or PremiumTypography and are frequently const
    text = text.replaceAll(RegExp(r'const\s+PremiumBubbleIcon'), 'PremiumBubbleIcon');
    text = text.replaceAll(RegExp(r'const\s+PremiumCard'), 'PremiumCard');
    text = text.replaceAll(RegExp(r'const\s+DataTile'), 'DataTile');
    text = text.replaceAll(RegExp(r'const\s+PremiumActionButton'), 'PremiumActionButton');
    text = text.replaceAll(RegExp(r'const\s+Text\('), 'Text(');
    text = text.replaceAll(RegExp(r'const\s+Icon\('), 'Icon(');
    text = text.replaceAll(RegExp(r'const\s+Padding\('), 'Padding(');
    text = text.replaceAll(RegExp(r'const\s+Center\('), 'Center(');

    file.writeAsStringSync(text);
  }
}
