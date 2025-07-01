import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../clients/logic/client_providers.dart';
import '../../templates/logic/template_providers.dart';
import '../../clients/data/client_model.dart';
import '../../templates/data/template_model.dart';
import '../logic/campaign_providers.dart';

class CampaignCreationScreen extends ConsumerStatefulWidget {
  const CampaignCreationScreen({super.key});

  @override
  ConsumerState<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends ConsumerState<CampaignCreationScreen> {
  int _currentStep = 0;
  final _campaignNameController = TextEditingController();
  
  List<ClientModel> _selectedClients = [];
  TemplateModel? _selectedTemplate;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  @override
  void dispose() {
    _campaignNameController.dispose();
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
                color: Colors.grey[10],
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
                    : Colors.grey[60],
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
        return _buildAudienceSelection();
      case 1:
        return _buildTemplateSelection();
      case 2:
        return _buildReviewAndSchedule();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAudienceSelection() {
    final clientsAsync = ref.watch(allClientsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Audience',
          style: FluentTheme.of(context).typography.title,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose which clients will receive this campaign',
          style: FluentTheme.of(context).typography.body,
        ),
        const SizedBox(height: 16),
        
        if (_selectedClients.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.people, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_selectedClients.length} clients selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Button(
                  onPressed: () => setState(() => _selectedClients.clear()),
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        Expanded(
          child: clientsAsync.when(
            data: (clients) {
              if (clients.isEmpty) {
                return const Center(
                  child: Text('No clients available. Add clients first.'),
                );
              }
              
              return Column(
                children: [
                  // Select all/none buttons
                  Row(
                    children: [
                      Button(
                        onPressed: () => setState(() => _selectedClients = List.from(clients)),
                        child: const Text('Select All'),
                      ),
                      const SizedBox(width: 16),
                      Button(
                        onPressed: () => setState(() => _selectedClients.clear()),
                        child: const Text('Select None'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Client list
                  Expanded(
                    child: ListView.builder(
                      itemCount: clients.length,
                      itemBuilder: (context, index) {
                        final client = clients[index];
                        final isSelected = _selectedClients.any((c) => c.id == client.id);

                        return GestureDetector(
                          onTap: () {
                            // also toggle when tapping anywhere on the row
                            setState(() {
                              if (isSelected) {
                                _selectedClients.removeWhere((c) => c.id == client.id);
                              } else {
                                _selectedClients.add(client);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  checked: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true){
                                        _selectedClients.add(client);
                                      }
                                      else {
                                        _selectedClients.removeWhere((c) => c.id == client.id);
                                      }
                                    });
                                  },
                                ),

                                const SizedBox(width: 12),

                                // Labels
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(client.fullName),

                                      const SizedBox(height: 4),

                                      if (client.email != null)
                                        Row(
                                          children: [
                                            const Icon(FluentIcons.mail, size: 12),
                                            const SizedBox(width: 4),
                                            Text(client.email!, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),

                                      if (client.phone != null)
                                        Row(
                                          children: [
                                            const Icon(FluentIcons.phone, size: 12),
                                            const SizedBox(width: 4),
                                            Text(client.phone!, style: const TextStyle(fontSize: 12)),
                                          ],
                                        ),

                                      if (client.company != null)
                                        Text(client.company!, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
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
                            // 1) The dot itself
                            RadioButton(
                              checked: isSelected,
                              onChanged: (checked) {
                                if (checked == true) {
                                  setState(() => _selectedTemplate = template);
                                }
                              },
                            ),

                            const SizedBox(width: 12),

                            // 2) Your icon + title + body
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

  Widget _buildReviewAndSchedule() {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review & Schedule',
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 8),
            Text(
              'Review your campaign details and choose when to send',
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 24),
            
            // Campaign Name
            Text(
              'Campaign Name *',
              style: FluentTheme.of(context).typography.body,
            ),
            const SizedBox(height: 8),
            TextFormBox(
              controller: _campaignNameController,
              placeholder: 'Enter campaign name...',
            ),
            
            const SizedBox(height: 24),
            
            // Campaign Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[40]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campaign Summary',
                    style: FluentTheme.of(context).typography.subtitle,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Recipients', '${_selectedClients.length} clients'),
                  _buildSummaryRow('Template', _selectedTemplate?.name ?? ''),
                  _buildSummaryRow('Type', _selectedTemplate?.type.toUpperCase() ?? ''),
                  if (_selectedTemplate?.subject != null)
                    _buildSummaryRow('Subject', _selectedTemplate!.subject!),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Preview with first client
                  if (_selectedClients.isNotEmpty && _selectedTemplate != null) ...[
                    Text(
                      'Message Preview (${_selectedClients.first.fullName}):',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey[60]),
                      ),
                      child: Text(
                        TemplatePreviewService.generatePreview(
                          _selectedTemplate!,
                          _selectedClients.first,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Scheduling Options
            Text(
              'Schedule Options',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
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
                const SizedBox(width: 16),
                Expanded(
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
              ],
            ),
            
            if (_scheduledDate != null && _scheduledTime != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(FluentIcons.clock, size: 16),
                    const SizedBox(width: 8),
                    Text('Scheduled for: ${_formatScheduledTime()}'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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