import 'package:client_connect/src/core/design_system/component_library.dart';
import 'package:client_connect/src/core/design_system/design_tokens.dart';
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
    final clientAsync = ref.watch(clientByIdProvider(widget.clientId));
    final clientTagsAsync = ref.watch(clientTagsProvider(widget.clientId));
    final clientCampaignsAsync = ref.watch(clientCampaignsProvider(widget.clientId));

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            DesignTokens.surfacePrimary.withValues(alpha: 0.95),
            DesignTokens.surfacePrimary.withValues(alpha: 0.85),
          ],
        ),
        border: Border(
          left: BorderSide(
            color: DesignTokens.accentPrimary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: EdgeInsets.all(DesignTokens.space6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: DesignTokens.accentPrimary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(DesignTokens.space2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        DesignTokens.accentPrimary.withValues(alpha: 0.15),
                        DesignTokens.accentPrimary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                    border: Border.all(
                      color: DesignTokens.accentPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    FluentIcons.contact,
                    size: DesignTokens.iconSizeMedium,
                    color: DesignTokens.accentPrimary,
                  ),
                ),
                SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Details',
                        style: DesignTextStyles.subtitle.copyWith(
                          fontWeight: DesignTokens.fontWeightBold,
                        ),
                      ),
                      Text(
                        'View and edit client information',
                        style: DesignTextStyles.caption.copyWith(
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEditing) ...[
                  DesignSystemComponents.secondaryButton(
                    text: 'Cancel',
                    onPressed: () => _cancelEdit(),
                  ),
                  SizedBox(width: DesignTokens.space2),
                  DesignSystemComponents.primaryButton(
                    text: 'Save',
                    onPressed: () => _saveChanges(),
                  ),
                ] else ...[
                  DesignSystemComponents.secondaryButton(
                    text: 'Edit',
                    icon: FluentIcons.edit,
                    onPressed: () => _startEdit(),
                  ),
                ],
                SizedBox(width: DesignTokens.space2),
                IconButton(
                  icon: Icon(FluentIcons.chrome_close, size: DesignTokens.iconSizeSmall),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: clientAsync.when(
              data: (client) {
                if (client == null) {
                  return DesignSystemComponents.emptyState(
                    title: 'Client not found',
                    message: 'The requested client could not be found',
                    icon: FluentIcons.search,
                  );
                }

                // Populate controllers when data loads
                if (!_isEditing) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _populateControllers(client);
                  });
                }

                return SingleChildScrollView(
                  padding: EdgeInsets.all(DesignTokens.space6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar and basic info
                      _buildClientHeader(client),
                      SizedBox(height: DesignTokens.space6),

                      // Contact Information
                      _buildSection(
                        'Contact Information',
                        _buildContactInfo(client),
                      ),
                      SizedBox(height: DesignTokens.space6),

                      // Tags
                      _buildSection(
                        'Tags',
                        clientTagsAsync.when(
                          data: (tags) => _buildTagsSection(tags),
                          loading: () => DesignSystemComponents.skeletonLoader(height: 40),
                          error: (_, __) => DesignSystemComponents.emptyState(
                            title: 'Error loading tags',
                            message: 'Could not load client tags',
                            icon: FluentIcons.error,
                            iconColor: DesignTokens.semanticError,
                          ),
                        ),
                      ),
                      SizedBox(height: DesignTokens.space6),

                      // Recent Campaigns
                      _buildSection(
                        'Recent Campaigns',
                        clientCampaignsAsync.when(
                          data: (campaigns) => _buildCampaignsSection(campaigns),
                          loading: () => DesignSystemComponents.skeletonLoader(height: 120),
                          error: (_, __) => DesignSystemComponents.emptyState(
                            title: 'Error loading campaigns',
                            message: 'Could not load client campaigns',
                            icon: FluentIcons.error,
                            iconColor: DesignTokens.semanticError,
                          ),
                        ),
                      ),
                      SizedBox(height: DesignTokens.space6),

                      // Notes
                      if (client.notes?.isNotEmpty == true || _isEditing)
                        _buildSection(
                          'Notes',
                          _buildNotesSection(client),
                        ),
                      
                      // Activity Timeline
                      SizedBox(height: DesignTokens.space6),
                      _buildSection(
                        'Activity Timeline',
                        ClientActivityTimeline(clientId: widget.clientId),
                      ),
                    ],
                  ),
                );
              },
              loading: () => DesignSystemComponents.loadingIndicator(
                message: 'Loading client details...',
              ),
              error: (error, stack) => DesignSystemComponents.emptyState(
                title: 'Error loading client',
                message: error.toString(),
                icon: FluentIcons.error,
                iconColor: DesignTokens.semanticError,
                actionText: 'Retry',
                onAction: () => ref.invalidate(clientByIdProvider(widget.clientId)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientHeader(ClientModel client) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.accentPrimary.withValues(alpha: 0.15),
                  DesignTokens.accentPrimary.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusRound),
              border: Border.all(
                color: DesignTokens.accentPrimary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(client.fullName),
                style: DesignTextStyles.titleLarge.copyWith(
                  color: DesignTokens.accentPrimary,
                  fontWeight: DesignTokens.fontWeightBold,
                ),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.space4),

          // Name and company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isEditing) ...[
                  Row(
                    children: [
                      Expanded(
                        child: DesignSystemComponents.textInput(
                          controller: _firstNameController,
                          label: 'First Name',
                          placeholder: 'First Name',
                        ),
                      ),
                      SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: DesignSystemComponents.textInput(
                          controller: _lastNameController,
                          label: 'Last Name',
                          placeholder: 'Last Name',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: DesignTokens.space2),
                  DesignSystemComponents.textInput(
                    controller: _companyController,
                    label: 'Company',
                    placeholder: 'Company',
                  ),
                  SizedBox(height: DesignTokens.space2),
                  DesignSystemComponents.textInput(
                    controller: _jobTitleController,
                    label: 'Job Title',
                    placeholder: 'Job Title',
                  ),
                ] else ...[
                  Text(
                    client.fullName,
                    style: DesignTextStyles.titleLarge.copyWith(
                      fontWeight: DesignTokens.fontWeightBold,
                    ),
                  ),
                  if (client.jobTitle != null && client.company != null) ...[
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      '${client.jobTitle} at ${client.company}',
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ] else if (client.company != null) ...[
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      client.company!,
                      style: DesignTextStyles.body.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: DesignTextStyles.bodyLarge.copyWith(
            fontSize: 16,
          ),
        ),
        SizedBox(height: DesignTokens.space3),
        content,
      ],
    );
  }

  Widget _buildContactInfo(ClientModel client) {
    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        children: [
          if (_isEditing) ...[
            DesignSystemComponents.textInput(
              controller: _emailController,
              label: 'Email',
              placeholder: 'Email',
              prefixIcon: FluentIcons.mail,
            ),
            SizedBox(height: DesignTokens.space3),
            DesignSystemComponents.textInput(
              controller: _phoneController,
              label: 'Phone',
              placeholder: 'Phone',
              prefixIcon: FluentIcons.phone,
            ),
            SizedBox(height: DesignTokens.space3),
            DesignSystemComponents.textInput(
              controller: _addressController,
              label: 'Address',
              placeholder: 'Address',
              prefixIcon: FluentIcons.location,
              maxLines: 2,
            ),
          ] else ...[
            if (client.email != null)
              _buildInfoRow(FluentIcons.mail, 'Email', client.email!),
            if (client.phone != null) ...[
              if (client.email != null) SizedBox(height: DesignTokens.space2),
              _buildInfoRow(FluentIcons.phone, 'Phone', client.phone!),
            ],
            if (client.address != null) ...[
              if (client.email != null || client.phone != null) SizedBox(height: DesignTokens.space2),
              _buildInfoRow(FluentIcons.location, 'Address', client.address!),
            ],
            if (client.email == null && client.phone == null && client.address == null)
              DesignSystemComponents.emptyState(
                title: 'No contact information',
                message: 'No contact information available for this client',
                icon: FluentIcons.contact_info,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: DesignTokens.iconSizeSmall,
          color: DesignTokens.textSecondary,
        ),
        SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DesignTextStyles.caption.copyWith(
                  color: DesignTokens.textSecondary,
                ),
              ),
              SizedBox(height: DesignTokens.space1),
              Text(
                value,
                style: DesignTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection(List<TagModel> tags) {
    if (tags.isEmpty) {
      return DesignSystemComponents.emptyState(
        title: 'No tags assigned',
        message: 'This client has no tags assigned',
        icon: FluentIcons.tag,
      );
    }

    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Wrap(
        spacing: DesignTokens.space2,
        runSpacing: DesignTokens.space2,
        children: tags.map((tag) => DesignSystemComponents.statusBadge(
          text: tag.name,
          type: SemanticColorType.info,
        )).toList(),
      ),
    );
  }

  Widget _buildCampaignsSection(List<dynamic> campaigns) {
    if (campaigns.isEmpty) {
      return DesignSystemComponents.emptyState(
        title: 'No campaigns yet',
        message: 'This client has not been included in any campaigns',
        icon: FluentIcons.send,
      );
    }

    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Column(
        children: campaigns.take(5).map((campaign) => Container(
          padding: EdgeInsets.all(DesignTokens.space3),
          margin: EdgeInsets.only(bottom: DesignTokens.space2),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceSecondary,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: DesignTokens.neutralGray200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accentPrimary.withValues(alpha: 0.15),
                      DesignTokens.accentPrimary.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
                ),
                child: Icon(
                  FluentIcons.send,
                  size: DesignTokens.iconSizeSmall,
                  color: DesignTokens.accentPrimary,
                ),
              ),
              SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign Name', // TODO: Use actual campaign name
                      style: DesignTextStyles.bodyLarge,
                    ),
                    SizedBox(height: DesignTokens.space1),
                    Text(
                      'Sent 2 days ago', // TODO: Use actual date
                      style: DesignTextStyles.caption.copyWith(
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              DesignSystemComponents.statusBadge(
                text: 'Sent',
                type: SemanticColorType.success,
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildNotesSection(ClientModel client) {
    if (_isEditing) {
      return DesignSystemComponents.standardCard(
        padding: EdgeInsets.all(DesignTokens.space4),
        child: DesignSystemComponents.textInput(
          controller: _notesController,
          label: 'Notes',
          placeholder: 'Add notes about this client...',
          maxLines: 4,
        ),
      );
    }

    if (client.notes?.isEmpty ?? true) {
      return DesignSystemComponents.emptyState(
        title: 'No notes available',
        message: 'No notes have been added for this client',
        icon: FluentIcons.edit_note,
      );
    }

    return DesignSystemComponents.standardCard(
      padding: EdgeInsets.all(DesignTokens.space4),
      child: Text(
        client.notes!,
        style: DesignTextStyles.body,
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