import 'package:client_connect/src/features/campaigns/presentation/campaign_analytics_dashboard.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/main_shell.dart';
import '../presentation/navigation/navigation_providers.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/clients/presentation/client_list_screen.dart';
import '../../features/clients/presentation/client_form_screen.dart';
import '../../features/templates/presentation/template_list_screen.dart';
import '../../features/templates/presentation/template_from_screen.dart';
import '../../features/templates/presentation/template_editor_screen.dart';
import '../../features/campaigns/presentation/campaign_dashboard_screen.dart';
import '../../features/campaigns/presentation/campaign_creation_screen.dart';
import '../../features/campaigns/presentation/campaign_details_screen.dart';
import '../../features/analytics/presentation/analytics_dashboard_screen.dart';
import '../../features/import_export/presentation/import_export_screen.dart';
import '../../features/tags/presentation/tag_management_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

// Provider for the router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Update navigation state when route changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final container = ProviderScope.containerOf(context);
            container.read(navigationStateProvider.notifier).updateFromRoute(state.uri.path);
          });
          
          return MainShell(child: child);
        },
        routes: [
          // Dashboard - Primary landing page
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          
          // Clients
          GoRoute(
            path: '/clients',
            builder: (context, state) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) => const ClientFormScreen(),
                name: 'addClient',
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => ClientFormScreen(
                  clientId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
                name: 'editClient',
              ),
            ],
          ),
          
          // Templates
          GoRoute(
            path: '/templates',
            builder: (context, state) => const TemplateListScreen(),
            routes: [
              GoRoute(
                path: 'editor',
                builder: (context, state) => const TemplateEditorScreen(),
                name: 'editorTemplate',
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => TemplateFormScreen(
                  templateId: int.tryParse(state.pathParameters['id'] ?? ''),
                ),
                name: 'editTemplate',
              ),
              GoRoute(
                path: 'editor/:id',
                builder: (context, state) => TemplateEditorScreen(
                  templateId: int.parse(state.pathParameters['id']!),
                ),
                name: 'editeditorTemplate',
              ),
            ],
          ),
          
          // Campaigns
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignDashboardScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CampaignCreationScreen(),
                name: 'createCampaigns',
              ),
              GoRoute(
                path: 'analytics',
                builder: (context, state) => CampaignAnalyticsDashboard(),
                name: 'seeAnalyticsCampaigns',
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CampaignDetailsScreen(
                  campaignId: int.parse(state.pathParameters['id']!),
                ),
                name: 'seeCampaigns',
              ),
            ],
          ),
          
          // Analytics
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsDashboardScreen(),
          ),
          
          // Import/Export
          GoRoute(
            path: '/import-export',
            builder: (context, state) => const ImportExportScreen(),
          ),
          
          // Tags
          GoRoute(
            path: '/tags',
            builder: (context, state) => const TagManagementScreen(),
          ),
          
          // Settings
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// Legacy router for backward compatibility
final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        // Dashboard - New primary landing page
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        
        // Clients
        GoRoute(
          path: '/clients',
          builder: (context, state) => const ClientListScreen(),
          routes: [
            GoRoute(
              path: '/add',
              builder: (context, state) => const ClientFormScreen(),
              name: 'addClient',
            ),
            GoRoute(
              path: '/edit/:id',
              builder: (context, state) => ClientFormScreen(
                clientId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
              name: 'editClient',
            ),
          ],
        ),
        
        // Templates
        GoRoute(
          path: '/templates',
          builder: (context, state) => const TemplateListScreen(),
          routes: [
            GoRoute(
              path: '/editor',
              builder: (context, state) => const TemplateEditorScreen(),
              name: 'editorTemplate',
            ),
            GoRoute(
              path: '/edit/:id',
              builder: (context, state) => TemplateFormScreen(
                templateId: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
              name: 'editTemplate',
            ),
            GoRoute(
              path: '/editor/:id',
              builder: (context, state) => TemplateEditorScreen(
                templateId: int.parse(state.pathParameters['id']!),
              ),
              name: 'editeditorTemplate',
            ),
          ],
        ),
        
        // Campaigns
        GoRoute(
          path: '/campaigns',
          builder: (context, state) => const CampaignDashboardScreen(),
          routes: [
            GoRoute(
              path: '/create',
              builder: (context, state) => const CampaignCreationScreen(),
              name: 'createCampaigns',
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => CampaignAnalyticsDashboard(),
              name: 'seeAnalyticsCampaigns',
            ),
            GoRoute(
              path: '/:id',
              builder: (context, state) => CampaignDetailsScreen(
                campaignId: int.parse(state.pathParameters['id']!),
              ),
              name: 'seeCampaigns',
            ),
          ],
        ),
        
        // Analytics
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsDashboardScreen(),
        ),
        
        // Import/Export
        GoRoute(
          path: '/import-export',
          builder: (context, state) => const ImportExportScreen(),
        ),
        
        // Tags
        GoRoute(
          path: '/tags',
          builder: (context, state) => const TagManagementScreen(),
        ),
        
        // Settings
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);
