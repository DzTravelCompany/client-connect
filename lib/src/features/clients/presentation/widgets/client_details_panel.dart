import 'package:client_connect/src/features/clients/data/client_activity_model.dart';
import 'package:client_connect/src/features/clients/logic/client_activity_providers.dart';
import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logic/client_providers.dart';
import '../../data/client_model.dart';
import '../../../tags/logic/tag_providers.dart';
import 'client_activity_timeline.dart';

class ClientDetailsPanel extends ConsumerStatefulWidget {
  final int clientId;
  final VoidCallback onClose;

  const ClientDetailsPanel({
    super.key,
    required this.clientId,
    required this.onClose,
  });

  @override
  ConsumerState<ClientDetailsPanel> createState() => _ClientDetailsPanelState();
}

class _ClientDetailsPanelState extends ConsumerState<ClientDetailsPanel> {
  bool _isEditing = false;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _companyController = TextEditingController();
    _jobTitleController = TextEditingController();
    _addressController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateControllers(ClientModel client) {
    _firstNameController.text = client.firstName;
    _lastNameController.text = client.lastName;
    _emailController.text = client.email ?? '';
    _phoneController.text = client.phone ?? '';
    _companyController.text = client.company ?? '';
    _jobTitleController.text = client.jobTitle ?? '';
    _addressController.text = client.address ?? '';
    _notesController.text = client.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final clientAsync = ref.watch(clientByIdProvider(widget.clientId));
    final clientTagsAsync = ref.watch(clientTagsProvider(widget.clientId));
    final clientCampaignsAsync = ref.watch(clientCampaignsProvider(widget.clientId));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Client Details',
                  style: theme.typography.subtitle?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_isEditing) ...[
                Button(
                  onPressed: () => _cancelEdit(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _saveChanges(),
                  child: const Text('Save'),
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(FluentIcons.edit),
                  onPressed: () => _startEdit(),
                ),
              ],
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(FluentIcons.chrome_close),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: clientAsync.when(
              data: (client) {
                if (client == null) {
                  return const Center(child: Text('Client not found'));
                }

                // Populate controllers when data loads
                if (!_isEditing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _populateControllers(client);
                  });
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar and basic info
                      _buildClientHeader(client, theme),
                      const SizedBox(height: 24),

                      // Contact Information
                      _buildSection(
                        'Contact Information',
                        _buildContactInfo(client, theme),
                        theme,
                      ),
                      const SizedBox(height: 24),

                      // Tags
                      _buildSection(
                        'Tags',
                        clientTagsAsync.when(
                          data: (tags) => _buildTagsSection(tags, theme),
                          loading: () => const ProgressRing(),
                          error: (_, __) => const Text('Error loading tags'),
                        ),
                        theme,
                      ),
                      const SizedBox(height: 24),

                      // Recent Campaigns
                      _buildSection(
                        'Recent Campaigns',
                        clientCampaignsAsync.when(
                          data: (campaigns) => _buildCampaignsSection(campaigns, theme),
                          loading: () => const ProgressRing(),
                          error: (_, __) => const Text('Error loading campaigns'),
                        ),
                        theme,
                      ),
                      const SizedBox(height: 24),

                      // Notes
                      if (client.notes?.isNotEmpty == true || _isEditing)
                        _buildSection(
                          'Notes',
                          _buildNotesSection(client, theme),
                          theme,
                        ),
                      // Activity Timeline
                      const SizedBox(height: 24),
                      _buildSection(
                        'Activity Timeline',
                        ClientActivityTimeline(clientId: widget.clientId),
                        theme,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: ProgressRing()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(FluentIcons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading client: $error'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(ClientModel client, FluentThemeData theme) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              _getInitials(client.fullName),
              style: TextStyle(
                color: theme.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name and company
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextBox(
                        controller: _firstNameController,
                        placeholder: 'First Name',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextBox(
                        controller: _lastNameController,
                        placeholder: 'Last Name',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextBox(
                  controller: _companyController,
                  placeholder: 'Company',
                ),
                const SizedBox(height: 8),
                TextBox(
                  controller: _jobTitleController,
                  placeholder: 'Job Title',
                ),
              ] else ...[
                Text(
                  client.fullName,
                  style: theme.typography.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (client.jobTitle != null && client.company != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${client.jobTitle} at ${client.company}',
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ] else if (client.company != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    client.company!,
                    style: theme.typography.body?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget content, FluentThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.typography.bodyStrong?.copyWith(
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildContactInfo(ClientModel client, FluentThemeData theme) {
    return Column(
      children: [
        if (_isEditing) ...[
          TextBox(
            controller: _emailController,
            placeholder: 'Email',
            prefix: const Icon(FluentIcons.mail),
          ),
          const SizedBox(height: 12),
          TextBox(
            controller: _phoneController,
            placeholder: 'Phone',
            prefix: const Icon(FluentIcons.phone),
          ),
          const SizedBox(height: 12),
          TextBox(
            controller: _addressController,
            placeholder: 'Address',
            prefix: const Icon(FluentIcons.location),
            maxLines: 2,
          ),
        ] else ...[
          if (client.email != null)
            _buildInfoRow(FluentIcons.mail, 'Email', client.email!, theme),
          if (client.phone != null) ...[
            if (client.email != null) const SizedBox(height: 8),
            _buildInfoRow(FluentIcons.phone, 'Phone', client.phone!, theme),
          ],
          if (client.address != null) ...[
            if (client.email != null || client.phone != null) const SizedBox(height: 8),
            _buildInfoRow(FluentIcons.location, 'Address', client.address!, theme),
          ],
          if (client.email == null && client.phone == null && client.address == null)
            Text(
              'No contact information available',
              style: theme.typography.body?.copyWith(
                color: theme.resources.textFillColorSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, FluentThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.resources.textFillColorSecondary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.typography.caption?.copyWith(
                  color: theme.resources.textFillColorSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.typography.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(List<TagModel> tags, FluentThemeData theme) {
    if (tags.isEmpty) {
      return Text(
        'No tags assigned',
        style: theme.typography.body?.copyWith(
          color: theme.resources.textFillColorSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag.name,
          style: TextStyle(
            fontSize: 12,
            color: theme.accentColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCampaignsSection(List<dynamic> campaigns, FluentThemeData theme) {
    if (campaigns.isEmpty) {
      return Text(
        'No campaigns yet',
        style: theme.typography.body?.copyWith(
          color: theme.resources.textFillColorSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      children: campaigns.take(5).map((campaign) => Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.resources.cardBackgroundFillColorSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              FluentIcons.send,
              size: 16,
              color: theme.resources.textFillColorSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campaign Name', // TODO: Use actual campaign name
                    style: theme.typography.bodyStrong,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sent 2 days ago', // TODO: Use actual date
                    style: theme.typography.caption?.copyWith(
                      color: theme.resources.textFillColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Sent',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNotesSection(ClientModel client, FluentThemeData theme) {
    if (_isEditing) {
      return TextBox(
        controller: _notesController,
        placeholder: 'Add notes about this client...',
        maxLines: 4,
      );
    }

    if (client.notes?.isEmpty ?? true) {
      return Text(
        'No notes available',
        style: theme.typography.body?.copyWith(
          color: theme.resources.textFillColorSecondary,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.resources.cardBackgroundFillColorSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        client.notes!,
        style: theme.typography.body,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts.first[0].toUpperCase();
    }
    return '?';
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    // Reset controllers to original values
    final clientAsync = ref.read(clientByIdProvider(widget.clientId));
    clientAsync.whenData((client) {
      if (client != null) {
        _populateControllers(client);
      }
    });
  }

  void _saveChanges() async {
    try {
      final clientNotifier = ref.read(clientFormProvider.notifier);
      
      final updatedClient = ClientModel(
        id: widget.clientId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim().isEmpty ? null : _jobTitleController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(), // This should come from the original client
        updatedAt: DateTime.now(),
      );
      
      await clientNotifier.saveClient(updatedClient);
      
      // Add activity log
      await ref.read(clientActivityNotifierProvider.notifier).addActivity(
        clientId: widget.clientId,
        activityType: ClientActivityType.updated,
        description: 'Client information updated',
      );
      
      setState(() {
        _isEditing = false;
      });
      
      // Refresh client data
      ref.invalidate(clientByIdProvider(widget.clientId));
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Changes Saved'),
            content: const Text('Client information has been updated successfully.'),
            severity: InfoBarSeverity.success,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Error'),
            content: Text('Failed to save changes: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}