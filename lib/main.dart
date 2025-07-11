import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'src/core/router/app_router.dart';
import 'src/core/services/database_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  await DatabaseService.instance.initialize();
  
  // Check for interrupted campaigns and show recovery dialog
  await _checkForInterruptedCampaigns();
  
  runApp(
    const ProviderScope(
      child: ClientConnectApp(),
    ),
  );
}

Future<void> _checkForInterruptedCampaigns() async {
  try {
    final sendingEngine = SendingEngine.instance;
    
    // This will automatically resume interrupted campaigns
    await sendingEngine.resumeInterruptedCampaigns();
    
  } catch (e) {
    debugPrint('Error checking for interrupted campaigns: $e');
  }
}

class ClientConnectApp extends ConsumerWidget {
  const ClientConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return fluent.FluentApp.router(
      title: 'Client Connect CRM',
      theme: fluent.FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue.toAccentColor(),
      ),
      darkTheme: fluent.FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue.toAccentColor(),
      ),
      routerConfig: appRouter,
    );
  }
}