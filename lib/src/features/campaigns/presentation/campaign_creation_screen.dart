import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../clients/logic/client_providers.dart';
import '../../templates/logic/template_providers.dart';
import '../../clients/data/client_model.dart';
import '../../templates/data/template_model.dart';
import '../../tags/logic/tag_providers.dart';
import '../../tags/data/tag_model.dart';
import '../../tags/presentation/widgets/tag_chip.dart';
import '../../templates/presentation/widgets/template_preview_dialog.dart';
import '../logic/campaign_providers.dart';


class CampaignCreationScreen extends ConsumerStatefulWidget {
  const CampaignCreationScreen({super.key});

  @override
  ConsumerState<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends ConsumerState<CampaignCreationScreen> {
  int _currentStep = 0;
  final _campaignNameController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<ClientModel> _selectedClients = [];
  List<ClientModel> _filteredClients = [];
  TemplateModel? _selectedTemplate;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  
  // Filter states
  String _searchTerm = '';
  final List<TagModel> _selectedTags = [];
  String _companyFilter = '';
  bool _showAdvancedFilters = false;

  // Track if we're in the process of disposing to prevent ref usage
  bool _isDisposing = false;

  @override
  void dispose() {
    _isDisposing = true;
    
    // Dispose controllers first
    _campaignNameController.dispose();
    _searchController.dispose();
    
    // Only reset the campaign creation state if the widget is still mounted
    // and we haven't started the disposing process
    try {
      if (mounted && !_isDisposing) {
        ref.read(campaignCreationProvider.notifier).resetState();
      }
    } catch (e) {
      // Silently catch any ref-related errors during disposal
      // This prevents the "Cannot use ref after widget was disposed" error
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Early return if disposing to prevent any ref usage
    if (_isDisposing) {
      return const ScaffoldPage(
        content: Center(child: ProgressRing()),
      );
    }

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
                onPressed: creationState.isLoading ? null : () {
                  if (mounted && !_isDisposing) {
                    setState(() => _currentStep--);
                  }
                },
              ),
            if (_currentStep < 2)
              CommandBarButton(
                icon: const Icon(FluentIcons.forward),
                label: const Text('Next'),
                onPressed: (_canProceedToNext() && !creationState.isLoading) 
                    ? () {
                        if (mounted && !_isDisposing) {
                          setState(() => _currentStep++);
                        }
                      }
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
    if (_isDisposing) return const Center(child: ProgressRing());
    
    final clientsAsync = ref.watch(allClientsProvider);
    final clientsWithTagsAsync = ref.watch(allClientsWithTagsProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title and stats
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
            if (_selectedClients.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_selectedClients.length} selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
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
                    child: TextBox(
                      controller: _searchController,
                      placeholder: 'Search clients by name, email, or company...',
                      prefix: const Icon(FluentIcons.search),
                      onChanged: (value) {
                        if (mounted && !_isDisposing) {
                          setState(() {
                            _searchTerm = value;
                          });
                          _applyFilters();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Button(
                    onPressed: () {
                      if (mounted && !_isDisposing) {
                        setState(() {
                          _showAdvancedFilters = !_showAdvancedFilters;
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_showAdvancedFilters ? FluentIcons.chevron_up : FluentIcons.chevron_down),
                        const SizedBox(width: 4),
                        const Text('Filters'),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Advanced filters
              if (_showAdvancedFilters) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Tag filters
                tagsAsync.when(
                  data: (tags) {
                    if (tags.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Filter by tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tags.map((tag) {
                            final isSelected = _selectedTags.any((t) => t.id == tag.id);
                            return TagChip(
                              tag: tag,
                              size: TagChipSize.small,
                              isSelected: isSelected,
                              onTap: () {
                                if (mounted && !_isDisposing) {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTags.removeWhere((t) => t.id == tag.id);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                  });
                                  _applyFilters();
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                
                // Clear filters button
                Row(
                  children: [
                    Button(
                      onPressed: _hasActiveFilters() ? () {
                        if (mounted && !_isDisposing) {
                          setState(() {
                            _searchController.clear();
                            _searchTerm = '';
                            _selectedTags.clear();
                            _companyFilter = '';
                          });
                          _applyFilters();
                        }
                      } : null,
                      child: const Text('Clear Filters'),
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredClients.length} clients match filters',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Selection controls
        if (_filteredClients.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(FluentIcons.people, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${_selectedClients.length} of ${_filteredClients.length} clients selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Button(
                  onPressed: () {
                    if (mounted && !_isDisposing) {
                      setState(() {
                        _selectedClients = List.from(_filteredClients);
                      });
                    }
                  },
                  child: const Text('Select All Filtered'),
                ),
                const SizedBox(width: 8),
                Button(
                  onPressed: () {
                    if (mounted && !_isDisposing) {
                      setState(() {
                        _selectedClients.clear();
                      });
                    }
                  },
                  child: const Text('Clear Selection'),
                ),
              ],
            ),
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
              
              // Initialize filtered clients if not done
              if (_filteredClients.isEmpty && _searchTerm.isEmpty && _selectedTags.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || _isDisposing) return;
                  
                  // Use clients with tags for initialization to ensure consistency
                  clientsWithTagsAsync.whenData((clientsWithTags) {
                    if (!mounted || _isDisposing) return;
                    
                    final clientModels = clientsWithTags.map((clientWithTags) => ClientModel(
                      id: clientWithTags.id,
                      firstName: clientWithTags.firstName,
                      lastName: clientWithTags.lastName,
                      email: clientWithTags.email,
                      phone: clientWithTags.phone,
                      company: clientWithTags.company,
                      jobTitle: clientWithTags.jobTitle,
                      address: null,
                      notes: null,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    )).toList();
                    
                    if (mounted && !_isDisposing) {
                      setState(() {
                        _filteredClients = clientModels;
                      });
                    }
                  });
                });
              }
              
              final displayClients = _filteredClients.isNotEmpty ? _filteredClients : clients;
              
              if (displayClients.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.search, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No clients match your filters'),
                      SizedBox(height: 8),
                      Text('Try adjusting your search criteria', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: displayClients.length,
                itemBuilder: (context, index) {
                  final client = displayClients[index];
                  final isSelected = _selectedClients.any((c) => c.id == client.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                    child: GestureDetector(
                      onTap: () {
                        if (mounted && !_isDisposing) {
                          setState(() {
                            if (isSelected) {
                              _selectedClients.removeWhere((c) => c.id == client.id);
                            } else {
                              _selectedClients.add(client);
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected 
                              ? Border.all(color: FluentTheme.of(context).accentColor)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              checked: isSelected,
                              onChanged: (value) {
                                if (mounted && !_isDisposing) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedClients.add(client);
                                    } else {
                                      _selectedClients.removeWhere((c) => c.id == client.id);
                                    }
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (client.email != null)
                                    Row(
                                      children: [
                                        const Icon(FluentIcons.mail, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            client.email!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (client.phone != null)
                                    Row(
                                      children: [
                                        const Icon(FluentIcons.phone, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          client.phone!,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  if (client.company != null)
                                    Row(
                                      children: [
                                        const Icon(FluentIcons.add_work, size: 12, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            client.company!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
            error: (error, stack) => Center(
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateSelection() {
    if (_isDisposing) return const Center(child: ProgressRing());
    
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
                const Spacer(),
                Button(
                  onPressed: () => _showTemplatePreview(_selectedTemplate!),
                  child: const Text('Preview'),
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

                  return Card(
                    backgroundColor: isSelected
                        ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                        : null,
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                    child: GestureDetector(
                      onTap: () {
                        if (mounted && !_isDisposing) {
                          setState(() => _selectedTemplate = template);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: isSelected 
                              ? Border.all(color: FluentTheme.of(context).accentColor)
                              : null,
                        ),
                        child: Row(
                          children: [
                            RadioButton(
                              checked: isSelected,
                              onChanged: (checked) {
                                if (checked == true && mounted && !_isDisposing) {
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
                                      Expanded(
                                        child: Text(
                                          template.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Button(
                                        onPressed: () => _showTemplatePreview(template),
                                        child: const Text('Preview'),
                                      ),
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
                if (_selectedTemplate != null)
                  Button(
                    onPressed: () => _showTemplatePreview(_selectedTemplate!),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.preview, size: 16),
                        SizedBox(width: 4),
                        Text('Preview Template'),
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
                  Text(
                    'Campaign Name *',
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                  const SizedBox(height: 8),
                  TextFormBox(
                    controller: _campaignNameController,
                    placeholder: 'Enter a descriptive name for your campaign...',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Campaign Overview Cards
            Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    'Recipients',
                    '${_selectedClients.length}',
                    FluentIcons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Template Type',
                    _selectedTemplate?.type.toUpperCase() ?? 'N/A',
                    _selectedTemplate?.isEmail == true ? FluentIcons.mail : FluentIcons.chat,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOverviewCard(
                    'Estimated Send Time',
                    _getEstimatedSendTime(),
                    FluentIcons.clock,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Detailed Campaign Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.info, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Campaign Summary',
                        style: FluentTheme.of(context).typography.subtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Template details
                  _buildSummarySection(
                    'Template Details',
                    [
                      _buildSummaryRow('Name', _selectedTemplate?.name ?? ''),
                      _buildSummaryRow('Type', _selectedTemplate?.type.toUpperCase() ?? ''),
                      if (_selectedTemplate?.subject != null)
                        _buildSummaryRow('Subject', _selectedTemplate!.subject!),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Audience details
                  _buildSummarySection(
                    'Audience Details',
                    [
                      _buildSummaryRow('Total Recipients', '${_selectedClients.length} clients'),
                      _buildSummaryRow('Email Recipients', '${_getEmailRecipients()} clients'),
                      _buildSummaryRow('WhatsApp Recipients', '${_getWhatsAppRecipients()} clients'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Message Preview
                  if (_selectedClients.isNotEmpty && _selectedTemplate != null) ...[
                    _buildSummarySection(
                      'Message Preview (${_selectedClients.first.fullName})',
                      [],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[100]),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedTemplate!.subject != null) ...[
                            Text(
                              'Subject: ${TemplatePreviewService.generatePreview(_selectedTemplate!, _selectedClients.first).split('\n').first}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            TemplatePreviewService.generatePreview(
                              _selectedTemplate!,
                              _selectedClients.first,
                            ),
                            style: const TextStyle(fontSize: 12),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Scheduling Options
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(FluentIcons.calendar, size: 20),
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
                            color: _scheduledDate == null 
                                ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                                : Colors.grey[150],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _scheduledDate == null 
                                  ? FluentTheme.of(context).accentColor
                                  : Colors.grey[200],
                            ),
                          ),
                          child: Button(
                            onPressed: () {
                              if (mounted && !_isDisposing) {
                                setState(() {
                                  _scheduledDate = null;
                                  _scheduledTime = null;
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Icon(
                                    FluentIcons.send,
                                    size: 24,
                                    color: _scheduledDate == null 
                                        ? FluentTheme.of(context).accentColor
                                        : Colors.grey[200],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Send Now'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Campaign will start immediately',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[100],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: _scheduledDate != null 
                                ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                                : Colors.grey[150],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _scheduledDate != null 
                                  ? FluentTheme.of(context).accentColor
                                  : Colors.grey[200],
                            ),
                          ),
                          child: Button(
                            onPressed: _showSchedulePicker,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Icon(
                                    FluentIcons.calendar,
                                    size: 24,
                                    color: _scheduledDate != null 
                                        ? FluentTheme.of(context).accentColor
                                        : Colors.grey[200],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _scheduledDate != null 
                                        ? 'Scheduled'
                                        : 'Schedule Later',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _scheduledDate != null
                                        ? _formatScheduledTime()
                                        : 'Choose date and time',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[100],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_scheduledDate != null && _scheduledTime != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(FluentIcons.clock, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Campaign Scheduled',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Will start sending on ${_formatScheduledTime()}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Validation warnings
            if (_getValidationWarnings().isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.warning, size: 16, color: Colors.yellow),
                        const SizedBox(width: 8),
                        Text(
                          'Validation Warnings',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._getValidationWarnings().map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $warning', style: const TextStyle(fontSize: 12)),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }


  void _applyFilters() {
    if (!mounted || _isDisposing) return;
    
    try {
      final clientsWithTagsAsync = ref.read(allClientsWithTagsProvider);
      clientsWithTagsAsync.whenData((clientsWithTags) {
        if (!mounted || _isDisposing) return;
        
        List<ClientWithTags> filtered = clientsWithTags;
        
        // Apply search filter
        if (_searchTerm.isNotEmpty) {
          filtered = filtered.where((clientWithTags) {
            final searchLower = _searchTerm.toLowerCase();
            return clientWithTags.fullName.toLowerCase().contains(searchLower) ||
                 (clientWithTags.email?.toLowerCase().contains(searchLower) ?? false) ||
                 (clientWithTags.company?.toLowerCase().contains(searchLower) ?? false);
          }).toList();
        }
        
        // Apply tag filters - client must have ALL selected tags (AND logic)
        if (_selectedTags.isNotEmpty) {
          filtered = filtered.where((clientWithTags) {
            // Check if client has all selected tags
            final clientTagIds = clientWithTags.tags.map((tag) => tag.id).toSet();
            final selectedTagIds = _selectedTags.map((tag) => tag.id).toSet();
            
            // Client must have all selected tags
            return selectedTagIds.every((tagId) => clientTagIds.contains(tagId));
          }).toList();
        }
        
        // Convert ClientWithTags back to ClientModel for UI compatibility
        final filteredClientModels = filtered.map((clientWithTags) => ClientModel(
          id: clientWithTags.id,
          firstName: clientWithTags.firstName,
          lastName: clientWithTags.lastName,
          email: clientWithTags.email,
          phone: clientWithTags.phone,
          company: clientWithTags.company,
          jobTitle: clientWithTags.jobTitle,
          address: null, // ClientWithTags doesn't have address field
          notes: null,   // ClientWithTags doesn't have notes field
          createdAt: DateTime.now(), // Placeholder since ClientWithTags doesn't have these
          updatedAt: DateTime.now(), // Placeholder since ClientWithTags doesn't have these
        )).toList();
        
        if (mounted && !_isDisposing) {
          setState(() {
            _filteredClients = filteredClientModels;
          });
        }
      });
    } catch (e) {
      // Silently handle any ref-related errors during filtering
    }
  }


  bool _hasActiveFilters() {
    return _searchTerm.isNotEmpty || _selectedTags.isNotEmpty || _companyFilter.isNotEmpty;
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

  int _getEmailRecipients() {
    return _selectedClients.where((client) => client.email != null).length;
  }

  int _getWhatsAppRecipients() {
    return _selectedClients.where((client) => client.phone != null).length;
  }

  String _getEstimatedSendTime() {
    final totalRecipients = _selectedClients.length;
    if (totalRecipients == 0) return 'N/A';
    
    // Estimate 1 message per second
    final seconds = totalRecipients;
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds / 60).ceil()}m';
    return '${(seconds / 3600).ceil()}h';
  }

  List<String> _getValidationWarnings() {
    List<String> warnings = [];
    
    if (_selectedTemplate?.isEmail == true) {
      final emailRecipients = _getEmailRecipients();
      if (emailRecipients < _selectedClients.length) {
        warnings.add('${_selectedClients.length - emailRecipients} clients don\'t have email addresses');
      }
    }
    
    else {
      final whatsappRecipients = _getWhatsAppRecipients();
      if (whatsappRecipients < _selectedClients.length) {
        warnings.add('${_selectedClients.length - whatsappRecipients} clients don\'t have phone numbers');
      }
    }
    
    if (_campaignNameController.text.trim().isEmpty) {
      warnings.add('Campaign name is required');
    }
    
    return warnings;
  }

  void _showSchedulePicker() async {
    if (_isDisposing) return;
    
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted && !_isDisposing) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (time != null && mounted && !_isDisposing) {
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
    
    // Use DateFormat instead of TimeOfDay.format(context) to avoid context dependency
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return '${dateFormat.format(scheduledDateTime)} at ${timeFormat.format(scheduledDateTime)}';
  }

  void _showTemplatePreview(TemplateModel template) {
    if (_isDisposing) return;
    
    showDialog(
      context: context,
      builder: (context) => TemplatePreviewDialog(
        templateName: template.name,
        templateSubject: template.subject ?? '',
        templateType: template.templateType,
        blocks: template.blocks,
      ),
    );
  }

  void _createCampaign() async {
    // Check if widget is still mounted and not disposing before starting
    if (!mounted || _isDisposing) return;
    
    final scheduledDateTime = _scheduledDate != null && _scheduledTime != null
        ? DateTime(
            _scheduledDate!.year,
            _scheduledDate!.month,
            _scheduledDate!.day,
            _scheduledTime!.hour,
            _scheduledTime!.minute,
        )
        : null;

    try {
      final campaignId = await ref.read(campaignCreationProvider.notifier).createCampaign(
        name: _campaignNameController.text.trim(),
        templateId: _selectedTemplate!.id,
        clientIds: _selectedClients.map((c) => c.id).toList(),
        messageType: _selectedTemplate!.type,
        scheduledAt: scheduledDateTime,
        startImmediately: scheduledDateTime == null,
      );

      // Check if widget is still mounted and not disposing before showing UI feedback
      if (!mounted || _isDisposing) return;

      if (campaignId != null) {
        // Store the formatted time before using it in the callback to avoid context access
        final formattedTime = _formatScheduledTime();
        final campaignName = _campaignNameController.text;
        
        // Use addPostFrameCallback to ensure UI operations happen after current build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isDisposing) return;
          
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Campaign Created'),
              content: Text(
                scheduledDateTime == null
                    ? 'Campaign "$campaignName" has been created and is now sending messages.'
                    : 'Campaign "$campaignName" has been scheduled for $formattedTime.',
              ),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
          
          // Navigate to campaigns list after a short delay to ensure InfoBar is shown
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && !_isDisposing) {
              context.go('/campaigns');
            }
          });
        });
      }
    } catch (e) {
      // Handle any errors that might occur during campaign creation
      if (mounted && !_isDisposing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _isDisposing) return;
          
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Error'),
              content: Text('Failed to create campaign: $e'),
              severity: InfoBarSeverity.error,
              onClose: close,
            ),
          );
        });
      }
    }
  }
}

// Helper service for template preview
class TemplatePreviewService {
  static String generatePreview(TemplateModel template, ClientModel client) {
    String preview = template.body;
    
    // Replace common placeholders
    preview = preview.replaceAll('{{first_name}}', client.firstName);
    preview = preview.replaceAll('{{last_name}}', client.lastName);
    preview = preview.replaceAll('{{full_name}}', client.fullName);
    preview = preview.replaceAll('{{email}}', client.email ?? '');
    preview = preview.replaceAll('{{phone}}', client.phone ?? '');
    preview = preview.replaceAll('{{company}}', client.company ?? '');
    
    return preview;
  }
}