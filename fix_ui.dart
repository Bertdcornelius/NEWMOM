import 'dart:io';

void main() {
  // 1. Fix login screen text colors
  var file = File('lib/screens/auth/login_screen.dart');
  var content = file.readAsStringSync();
  content = content.replaceFirst(
    'controller: _emailController,',
    'controller: _emailController,\n              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),'
  );
  content = content.replaceFirst(
    'controller: _passwordController,',
    'controller: _passwordController,\n              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),'
  );
  file.writeAsStringSync(content);
  print('login_screen updated');

  // 2. Fix welcome screen guest persistence
  var welcomeFile = File('lib/screens/auth/welcome_screen.dart');
  var welcomeContent = welcomeFile.readAsStringSync();
  welcomeContent = welcomeContent.replaceFirst(
    \"import 'login_screen.dart';\",
    \"import '../../services/local_storage_service.dart';\nimport 'login_screen.dart';\"
  );
  welcomeContent = welcomeContent.replaceFirst(
    \"await context.read<SupabaseService>().signInAnonymously();\",
    \"await context.read<SupabaseService>().signInAnonymously();\n      await context.read<LocalStorageService>().saveString('guest_mode', 'true');\"
  );
  welcomeFile.writeAsStringSync(welcomeContent);
  print('welcome_screen updated');

  // 3. Fix premium UI components shadows
  var premiumFile = File('lib/widgets/premium_ui_components.dart');
  var premiumContent = premiumFile.readAsStringSync();
  // Fix PremiumCard
  premiumContent = premiumContent.replaceFirst(
    \"return ClipRRect(\",
    \"return Container(\n      decoration: BoxDecoration(\n        borderRadius: BorderRadius.circular(24),\n        boxShadow: isDark ? [] : [\n          BoxShadow(\n            color: Colors.black.withOpacity(0.05),\n            blurRadius: 30,\n            offset: const Offset(0, 10),\n          )\n        ],\n      ),\n      child: ClipRRect(\"
  );
  // Remove inner shadow from PremiumCard
  premiumContent = premiumContent.replaceFirst(
    \"boxShadow: [\n              BoxShadow(\n                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),\n                blurRadius: 30,\n                offset: const Offset(0, 10),\n              )\n            ],\",
    \"\"
  );
  // Fix DataTile shadow
  premiumContent = premiumContent.replaceFirst(
    \"child: ClipRRect(\n        borderRadius: BorderRadius.circular(16),\",
    \"child: Container(\n        decoration: BoxDecoration(\n          borderRadius: BorderRadius.circular(16),\n          boxShadow: isDark ? [] : [\n            BoxShadow(\n              color: Colors.black.withOpacity(0.04),\n              blurRadius: 20,\n              offset: const Offset(0, 8),\n            )\n          ],\n        ),\n        child: ClipRRect(\n          borderRadius: BorderRadius.circular(16),\"
  );
  premiumFile.writeAsStringSync(premiumContent);
  print('premium_ui_components updated');

  // 4. Fix Dashboard baby name persistence
  var dashboardFile = File('lib/screens/home/dashboard_screen.dart');
  var dashContent = dashboardFile.readAsStringSync();
  // Inject local storage check before profile fetch
  dashContent = dashContent.replaceFirst(
    \"final profile = await service.getProfile();\",
    \"final localStorage = context.read<LocalStorageService>();\n    final savedName = localStorage.getString('baby_name');\n    final profile = await service.getProfile();\"
  );
  dashContent = dashContent.replaceFirst(
    \"_babyName = profile?['baby_name'] ?? 'Baby';\",
    \"_babyName = profile?['baby_name'] ?? savedName ?? 'Baby';\"
  );
  dashContent = dashContent.replaceFirst(
    \"if (profile == null || profile['baby_name'] == null) {\",
    \"if ((profile == null || profile['baby_name'] == null) && savedName == null) {\"
  );
  dashContent = dashContent.replaceFirst(
    \"await context.read<SupabaseService>().updateProfile({'baby_name': nameController.text});\",
    \"await context.read<SupabaseService>().updateProfile({'baby_name': nameController.text});\n                               await context.read<LocalStorageService>().saveString('baby_name', nameController.text);\"
  );
  dashboardFile.writeAsStringSync(dashContent);
  print('dashboard_screen updated');
}
