import 'package:client_connect/src/features/analytics/presentation/analytics_dashboard_screen.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_creation_screen.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_dashboard_screen.dart';
import 'package:client_connect/src/features/campaigns/presentation/campaign_details_screen.dart';
import 'package:client_connect/src/features/import_export/presentation/import_export_screen.dart';
import 'package:client_connect/src/features/tags/presentation/tag_management_screen.dart';
import 'package:client_connect/src/features/settings/presentation/settings_screen.dart';
import 'package:client_connect/src/features/templates/presentation/template_editor_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/templates/presentation/template_list_screen.dart';
import '../presentation/main_shell.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/clients',
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientListScreen(),
          ),
          GoRoute(
            path: '/clients/add',
            builder: (context, state) => const ClientFormScreen(),
          ),
          GoRoute(
            path: '/clients/edit/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return ClientFormScreen(clientId: id);
            },
          ),
          GoRoute(
            path: '/templates',
            builder: (context, state) => const TemplateListScreen(),
          ),
          // GoRoute(
          //   path: '/templates/new',
          //   builder: (context, state) => const TemplateFormScreen(),
          // ),
          // GoRoute(
          //   path: '/templates/edit/:id',
          //   builder: (context, state) {
          //     final id = int.parse(state.pathParameters['id']!);
          //     return TemplateFormScreen(templateId: id);
          //   },
          // ),
          GoRoute(
            path: '/templates/editor',
            builder: (context, state) => const TemplateEditorScreen(),
          ),
          GoRoute(
            path: '/templates/editor/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TemplateEditorScreen(templateId: id);
            },
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignDashboardScreen(),
          ),
          GoRoute(
            path: '/campaigns/create',
            builder: (context, state) => const CampaignCreationScreen(),
          ),
          GoRoute(
            path: '/campaigns/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CampaignDetailsScreen(campaignId: id);
            },
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsDashboardScreen(),
          ),
          GoRoute(
            path: '/tags',
            builder: (context, state) => const TagManagementScreen(),
          ),
          GoRoute(
            path: '/import-export',
            builder: (context, state) => const ImportExportScreen(),
          ),
        ],
      ),
    ],
  );
});