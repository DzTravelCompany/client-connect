import 'package:client_connect/src/core/services/sending_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:window_manager/window_manager.dart';
import 'src/core/router/app_router.dart';
import 'src/core/services/database_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Client Connect',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
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

    final router = ref.watch(appRouterProvider);
    
    return fluent.FluentApp.router(
      title: 'Client Connect CRM',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: fluent.FluentThemeData(
        brightness: Brightness.light,
        accentColor: Colors.blue.toAccentColor(),
        visualDensity: VisualDensity.standard,
        focusTheme: fluent.FocusThemeData(
          glowFactor: fluent.is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      darkTheme: fluent.FluentThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.blue.toAccentColor(),
        visualDensity: VisualDensity.standard,
        focusTheme: fluent.FocusThemeData(
          glowFactor: fluent.is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
    );
  }
}