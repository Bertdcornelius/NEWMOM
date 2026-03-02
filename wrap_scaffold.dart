import 'dart:io';

void main() {
  final dir = Directory('lib/screens');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    if (file.path.contains('premium_ui_components') || file.path.contains('glass_morph_ui')) continue;
    String content = file.readAsStringSync();
    
    bool changed = false;

    // Replace Scaffold with PremiumScaffold
    if (content.contains('return Scaffold(')) {
        content = content.replaceAll('return Scaffold(', 'return PremiumScaffold(');
        changed = true;
    }
    if (content.contains('return const Scaffold(')) {
        content = content.replaceAll('return const Scaffold(', 'return PremiumScaffold(');
        changed = true;
    }

    // Remove backgroundColor: PremiumColors(context).background
    if (content.contains('backgroundColor: PremiumColors(context).background,')) {
        content = content.replaceAll('backgroundColor: PremiumColors(context).background,', '');
        changed = true;
    }

    // Remove backgroundColor: PremiumColors.background
    if (content.contains('backgroundColor: PremiumColors.background,')) {
         content = content.replaceAll('backgroundColor: PremiumColors.background,', '');
         changed = true;
    }

    if (changed) {
        file.writeAsStringSync(content);
        print('Updated ${file.path}');
    }
  }
}
