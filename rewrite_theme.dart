import 'dart:io';

void main() {
  final screensDir = Directory('lib/screens');
  final widgetsDir = Directory('lib/widgets');

  final files = [
    ...screensDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
    ...widgetsDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart') && !f.path.contains('premium_ui_components')),
  ];

  for (final file in files) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Replace PremiumTypography.xxx with PremiumTypography(context).xxx
    final typoRegex = RegExp(r'PremiumTypography\.(h1|h2|title|bodyBold|body|caption)');
    if (typoRegex.hasMatch(content)) {
      content = content.replaceAllMapped(typoRegex, (m) => 'PremiumTypography(context).${m.group(1)}');
      changed = true;
    }

    // Replace colors: First capture all explicitly.
    final colorRegex = RegExp(r'PremiumColors\.(background|surfaceMuted|surface|sageGreen|sereneBlue|gentlePurple|warmPeach|softAmber|textPrimary|textSecondary|textMuted)');
    if (colorRegex.hasMatch(content)) {
       content = content.replaceAllMapped(colorRegex, (m) => 'PremiumColors(context).${m.group(1)}');
       changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
    }
  }
}
