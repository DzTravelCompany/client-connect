import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../clients/logic/client_providers.dart';
import '../../templates/logic/template_providers.dart';
import '../../clients/data/client_model.dart';
import '../../templates/data/template_model.dart';
import '../../tags/logic/tag_providers.dart';
import '../../tags/data/tag_model.dart';
import '../../tags/presentation/widgets/tag_chip.dart';
import '../logic/campaign_providers.dart';
import '../presentation/widgets/template_preview_widget.dart';

class CampaignCreationScreen extends ConsumerStatefulWidget {
  const CampaignCreationScreen({super.key});

  @override
  ConsumerState<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends ConsumerState<CampaignCreationScreen> {
  int _currentStep = 0;
  final _campaignNameController = TextEditingController();
  final _searchController = TextEditingController();
  
  final List<ClientModel> _selectedClients = [];
  List<ClientModel> _filteredClients = [];
  TemplateModel? _selectedTemplate;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  
  // Filtering and search state
  String _searchTerm = '';
  final List<TagModel> _selectedTags = [];
  String _sortBy = 'name'; // name, company, recent
  bool _sortAscending = true;

  @override
  void dispose() {
    _campaignNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(campaignCreationProvider);
    
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Create Campaign'),
        commandBar: CommandBar(
          primaryItems: [
            if (_currentStep > 0)
              CommandBarButton(
                icon: const Icon(FluentIcons.back),
                label: const Text('Back'),
                onPressed: creationState.isLoading ? null : () => setState(() => _currentStep--),
              ),
            if (_currentStep < 2)
              CommandBarButton(
                icon: const Icon(FluentIcons.forward),
                label: const Text('Next'),
                onPressed: (_canProceedToNext() && !creationState.isLoading) 
                    ? () => setState(() => _currentStep++) 
                    : null,
              ),
            if (_currentStep == 2)
              CommandBarButton(
                icon: const Icon(FluentIcons.send),
                label: const Text('Create Campaign'),
                onPressed: (_canCreateCampaign() && !creationState.isLoading) 
                    ? _createCampaign 
                    : null,
              ),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Loading indicator
            if (creationState.isLoading)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Creating campaign...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),

            // Error message
            if (creationState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.error, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Error: ${creationState.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

            // Progress indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Select Audience'),
                  const Expanded(child: Divider()),
                  _buildStepIndicator(1, 'Choose Template'),
                  const Expanded(child: Divider()),
                  _buildStepIndicator(2, 'Review & Send'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Step content
            Expanded(
              child: _buildStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? Colors.green 
                : isActive 
                    ? FluentTheme.of(context).accentColor 
                    : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(FluentIcons.check_mark, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEnhancedAudienceSelection();
      case 1:
        return _buildTemplateSelection();
      case 2:
        return _buildEnhancedReviewAndSchedule();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnhancedAudienceSelection() {
    final clientsAsync = ref.watch(allClientsProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Audience',
                    style: FluentTheme.of(context).typography.title,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose which clients will receive this campaign',
                    style: FluentTheme.of(context).typography.body,
                  ),
                ],
              ),
            ),
            // Selection summary
            if (_selectedClients.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.people, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      '${_selectedClients.length} selected',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Search and filter controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]),
          ),
          child: Column(
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextBox(
                      controller: _searchController,
                      placeholder: 'Search clients by name, email, company...',
                      prefix: const Icon(FluentIcons.search),
                      suffix: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(FluentIcons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchTerm = '');
                              },
                            )
                          : null,
                      onChanged: (value) {
                        setState(() => _searchTerm = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sort dropdown
                  Expanded(
                    child: ComboBox<String>(
                      placeholder: const Text('Sort by'),
                      value: _sortBy,
                      items: const [
                        ComboBoxItem(value: 'name', child: Text('Name')),
                        ComboBoxItem(value: 'company', child: Text('Company')),
                        ComboBoxItem(value: 'recent', child: Text('Recently Added')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _sortBy = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _sortAscending ? FluentIcons.sort_up : FluentIcons.sort_down,
                    ),
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Tag filters
              tagsAsync.when(
                data: (tags) {
                  if (tags.isEmpty) return const SizedBox.shrink();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Filter by tags:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: tags.map((tag) {
                          final isSelected = _selectedTags.any((t) => t.id == tag.id);
                          return TagChip(
                            tag: tag,
                            size: TagChipSize.small,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedTags.removeWhere((t) => t.id == tag.id);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_selectedTags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Button(
                          onPressed: () => setState(() => _selectedTags.clear()),
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bulk selection controls
        Row(
          children: [
            Button(
              onPressed: () => _selectFilteredClients(),
              child: const Text('Select All Filtered'),
            ),
            const SizedBox(width: 12),
            Button(
              onPressed: () => setState(() => _selectedClients.clear()),
              child: const Text('Clear Selection'),
            ),
            const Spacer(),
            if (_selectedClients.isNotEmpty)
              Text(
                '${_selectedClients.length} of ${_getFilteredClientsCount()} clients selected',
                style: TextStyle(
                  color: Colors.grey[120],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Client list
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return const Center(
                  child: Text('No clients available. Add clients first.'),
                );
              }
              
              final filteredClients = _filterAndSortClients(clients);
              _filteredClients = filteredClients;
              
              if (filteredClients.isEmpty) {
                return const Center(
                  child: Text('No clients match your search criteria.'),
                );
              }
              
              return _buildClientList(filteredClients);
            },
            loading: () => const Center(child: ProgressRing()),
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientList(List<ClientModel> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        final isSelected = _selectedClients.any((c) => c.id == client.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey[200],
            ),
          ),
          child: ListTile(
            leading: Checkbox(
              checked: isSelected,
              onChanged: (value) => _toggleClientSelection(client),
            ),
            title: Text(
              client.fullName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (client.company != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(FluentIcons.build, size: 12),
                      const SizedBox(width: 4),
                      Text(client.company!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
                if (client.email != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(FluentIcons.mail, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.email!, 
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (client.phone != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(FluentIcons.phone, size: 12),
                      const SizedBox(width: 4),
                      Text(client.phone!, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
                // Show client tags if any
                // if (client.tag.isNotEmpty) ...[
                //   const SizedBox(height: 4),
                //   _buildClientTags(client.tagIds),
                // ],
              ],
            ),
            onPressed: () => _toggleClientSelection(client),
          ),
        );
      },
    );
  }

  Widget _buildClientTags(List<int> tagIds) {
    final tagsAsync = ref.watch(allTagsProvider);
    
    return tagsAsync.when(
      data: (allTags) {
        final clientTags = allTags.where((tag) => tagIds.contains(tag.id)).toList();
        if (clientTags.isEmpty) return const SizedBox.shrink();
        
        return Wrap(
          spacing: 4,
          runSpacing: 2,
          children: clientTags.take(3).map((tag) => TagChip(
            tag: tag,
            size: TagChipSize.small,
          )).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTemplateSelection() {
    final templatesAsync = ref.watch(templatesProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Template',
          style: FluentTheme.of(context).typography.title,
        ),
        const SizedBox(height: 8),
        Text(
          'Select the message template for this campaign',
          style: FluentTheme.of(context).typography.body,
        ),
        const SizedBox(height: 16),
        
        if (_selectedTemplate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedTemplate!.isEmail ? FluentIcons.mail : FluentIcons.chat,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected: ${_selectedTemplate!.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: templatesAsync.when(
            data: (templates) {
              if (templates.isEmpty) {
                return const Center(
                  child: Text('No templates available. Create templates first.'),
                );
              }

              return ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = _selectedTemplate?.id == template.id;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTemplate = template),
                    child: Card(
                      backgroundColor: isSelected
                          ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                          : null,
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RadioButton(
                              checked: isSelected,
                              onChanged: (checked) {
                                if (checked == true) {
                                  setState(() => _selectedTemplate = template);
                                }
                              },
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        template.isEmail
                                            ? FluentIcons.mail
                                            : FluentIcons.chat,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(template.name)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (template.subject != null)
                                    Text(
                                      'Subject: ${template.subject}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(
                                    template.body,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: ProgressRing()),
            error: (err, st) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedReviewAndSchedule() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & Schedule',
                        style: FluentTheme.of(context).typography.title,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review your campaign details and choose when to send',
                        style: FluentTheme.of(context).typography.body,
                      ),
                    ],
                  ),
                ),
                // Campaign status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.clock, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(
                        'Draft',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Campaign Name
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.edit, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Campaign Name',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                      Text(' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormBox(
                    controller: _campaignNameController,
                    placeholder: 'Enter a descriptive campaign name...',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Campaign Overview Cards
            Row(
              children: [
                // Audience Summary
                Expanded(
                  child: _buildSummaryCard(
                    icon: FluentIcons.people,
                    title: 'Audience',
                    value: '${_selectedClients.length}',
                    subtitle: _selectedClients.length == 1 ? 'recipient' : 'recipients',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                // Template Summary
                Expanded(
                  child: _buildSummaryCard(
                    icon: _selectedTemplate?.isEmail == true ? FluentIcons.mail : FluentIcons.chat,
                    title: 'Template',
                    value: _selectedTemplate?.name ?? 'None',
                    subtitle: _selectedTemplate?.type.toUpperCase() ?? '',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                // Schedule Summary
                Expanded(
                  child: _buildSummaryCard(
                    icon: FluentIcons.calendar,
                    title: 'Schedule',
                    value: _scheduledDate != null ? 'Scheduled' : 'Send Now',
                    subtitle: _scheduledDate != null ? _formatScheduledTime() : 'Immediate',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Template Preview Section
            if (_selectedTemplate != null && _selectedClients.isNotEmpty) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.preview, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Message Preview',
                            style: FluentTheme.of(context).typography.subtitle,
                          ),
                          const Spacer(),
                          ComboBox<ClientModel>(
                            placeholder: const Text('Preview for client'),
                            value: _selectedClients.first,
                            items: _selectedClients.take(5).map((client) => 
                              ComboBoxItem(
                                value: client,
                                child: Text(client.fullName),
                              ),
                            ).toList(),
                            onChanged: (client) {
                              // Update preview for selected client
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TemplatePreviewWidget(
                        template: _selectedTemplate!,
                        client: _selectedClients.first,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Scheduling Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.clock, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Schedule Options',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _scheduledDate == null ? Colors.blue.withValues(alpha: 0.1) : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _scheduledDate == null 
                                  ? Colors.blue.withValues(alpha: 0.3)
                                  : Colors.grey[60],
                            ),
                          ),
                          child: Button(
                            onPressed: () {
                              setState(() {
                                _scheduledDate = null;
                                _scheduledTime = null;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FluentIcons.send, size: 16),
                                const SizedBox(width: 8),
                                const Text('Send Now'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _scheduledDate != null ? Colors.orange.withValues(alpha: 0.1) : null,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _scheduledDate != null 
                                  ? Colors.orange.withValues(alpha: 0.3)
                                  : Colors.grey[60],
                            ),
                          ),
                          child: Button(
                            onPressed: _showSchedulePicker,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(FluentIcons.calendar, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  _scheduledDate != null 
                                      ? 'Scheduled'
                                      : 'Schedule Later',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_scheduledDate != null && _scheduledTime != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(FluentIcons.calendar_day, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduled for:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatScheduledTime(),
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(FluentIcons.clear, size: 14),
                            onPressed: () {
                              setState(() {
                                _scheduledDate = null;
                                _scheduledTime = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[120],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  List<ClientModel> _filterAndSortClients(List<ClientModel> clients) {
    var filtered = clients.where((client) {
      // Text search
      if (_searchTerm.isNotEmpty) {
        final searchLower = _searchTerm.toLowerCase();
        final matchesName = client.fullName.toLowerCase().contains(searchLower);
        final matchesEmail = client.email?.toLowerCase().contains(searchLower) ?? false;
        final matchesCompany = client.company?.toLowerCase().contains(searchLower) ?? false;
        
        if (!matchesName && !matchesEmail && !matchesCompany) {
          return false;
        }
      }
      
      // Tag filter
      // if (_selectedTags.isNotEmpty) {
      //   final hasMatchingTag = _selectedTags.any((tag) => client.tagIds.contains(tag.id));
      //   if (!hasMatchingTag) return false;
      // }
      
      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'company':
          comparison = (a.company ?? '').compareTo(b.company ?? '');
          break;
        case 'recent':
          comparison = b.id.compareTo(a.id); // Assuming higher ID = more recent
          break;
        default: // name
          comparison = a.fullName.compareTo(b.fullName);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }

  void _toggleClientSelection(ClientModel client) {
    setState(() {
      final isSelected = _selectedClients.any((c) => c.id == client.id);
      if (isSelected) {
        _selectedClients.removeWhere((c) => c.id == client.id);
      } else {
        _selectedClients.add(client);
      }
    });
  }

  void _selectFilteredClients() {
    setState(() {
      for (final client in _filteredClients) {
        if (!_selectedClients.any((c) => c.id == client.id)) {
          _selectedClients.add(client);
        }
      }
    });
  }

  int _getFilteredClientsCount() {
    return _filteredClients.length;
  }

  bool _canProceedToNext() {
    switch (_currentStep) {
      case 0:
        return _selectedClients.isNotEmpty;
      case 1:
        return _selectedTemplate != null;
      default:
        return false;
    }
  }

  bool _canCreateCampaign() {
    return _selectedClients.isNotEmpty && 
           _selectedTemplate != null && 
           _campaignNameController.text.trim().isNotEmpty;
  }

  void _showSchedulePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null) {
        setState(() {
          _scheduledDate = date;
          _scheduledTime = time;
        });
      }
    }
  }

  String _formatScheduledTime() {
    if (_scheduledDate == null || _scheduledTime == null) return '';
    
    final scheduledDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );
    
    return '${scheduledDateTime.day}/${scheduledDateTime.month}/${scheduledDateTime.year} at ${_scheduledTime!.format(context)}';
  }

  void _createCampaign() async {
    final scheduledDateTime = _scheduledDate != null && _scheduledTime != null
        ? DateTime(
            _scheduledDate!.year,
            _scheduledDate!.month,
            _scheduledDate!.day,
            _scheduledTime!.hour,
            _scheduledTime!.minute,
          )
        : null;

    final campaignId = await ref.read(campaignCreationProvider.notifier).createCampaign(
      name: _campaignNameController.text.trim(),
      templateId: _selectedTemplate!.id,
      clientIds: _selectedClients.map((c) => c.id).toList(),
      messageType: _selectedTemplate!.type,
      scheduledAt: scheduledDateTime,
      startImmediately: scheduledDateTime == null,
    );

    if (campaignId != null && mounted) {
      displayInfoBar(
        context,
        builder: (context, close) => InfoBar(
          title: const Text('Campaign Created'),
          content: Text(
            scheduledDateTime == null
                ? 'Campaign "${_campaignNameController.text}" has been created and is now sending messages.'
                : 'Campaign "${_campaignNameController.text}" has been scheduled for ${_formatScheduledTime()}.',
          ),
          severity: InfoBarSeverity.success,
          onClose: close,
        ),
      );
      
      // Navigate to campaigns list
      context.go('/campaigns');
    }
  }
}