import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../logic/client_providers.dart';

class ClientListScreen extends ConsumerStatefulWidget {
  const ClientListScreen({super.key});

  @override
  ConsumerState<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends ConsumerState<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = _searchTerm.isEmpty
        ? ref.watch(allClientsProvider)
        : ref.watch(searchClientsProvider(_searchTerm));

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Clients'),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Add Client'),
              onPressed: () => context.go('/clients/add'),
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.sync),
              label: const Text('Import/Export'),
              onPressed: () => context.go('/import-export'),
            ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextBox(
              controller: _searchController,
              placeholder: 'Search clients...',
              prefix: const Icon(FluentIcons.search),
              onChanged: (value) {
                setState(() {
                  _searchTerm = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Client list
            Expanded(
              child: clientsAsync.when(
                data: (clients) {
                  if (clients.isEmpty) {
                    return const Center(
                      child: Text('No clients found. Add your first client!'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: clients.length,
                    itemBuilder: (context, index) {
                      final client = clients[index];
                      return Card(
                        child: ListTile(
                          title: Text(client.fullName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.email != null) Text(client.email!),
                              if (client.company != null) Text(client.company!),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(FluentIcons.edit),
                                onPressed: () => context.go('/clients/edit/${client.id}'),
                              ),
                              IconButton(
                                icon: const Icon(FluentIcons.delete),
                                onPressed: () => _showDeleteDialog(client.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: ProgressRing()),
                error: (error, stack) => Center(
                  child: Text('Error: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int clientId) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Delete Client'),
        content: const Text('Are you sure you want to delete this client? This action cannot be undone.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () async {
              Navigator.of(context).pop();
              final dao = ref.read(clientDaoProvider);
              try {
                await dao.deleteClient(clientId);
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Client deleted'),
                      content: const Text('The client has been successfully deleted.'),
                      severity: InfoBarSeverity.success,
                      onClose: close,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) => InfoBar(
                      title: const Text('Error'),
                      content: Text('Failed to delete client: $e'),
                      severity: InfoBarSeverity.error,
                      onClose: close,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}