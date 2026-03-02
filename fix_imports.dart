import 'dart:io';

void main() {
  final files = [
    'lib/screens/home/vaccine_screen.dart',
    'lib/screens/home/sleep_screen.dart',
    'lib/screens/home/routine_screen.dart',
    'lib/screens/home/profile_screen.dart',
    'lib/screens/home/prescription_screen.dart',
    'lib/screens/home/notes_screen.dart',
    'lib/screens/home/mom_care_screen.dart',
    'lib/screens/home/milestones_screen.dart',
    'lib/screens/home/history_screen.dart',
    'lib/screens/home/feeding_screen.dart',
    'lib/screens/home/dashboard_screen.dart',
    'lib/screens/auth/welcome_screen.dart',
    'lib/screens/auth/login_screen.dart',
  ];

  for(String path in files) {
    File f = File(path);
    if(f.existsSync()) {
       String content = f.readAsStringSync();
       if(!content.contains('premium_ui_components.dart')) {
          String prefix = '../../widgets/'; 
          String importStatement = "import '${prefix}premium_ui_components.dart';";
          content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n$importStatement");
          f.writeAsStringSync(content);
          print("Fixed $path");
       }
    }
  }
}
