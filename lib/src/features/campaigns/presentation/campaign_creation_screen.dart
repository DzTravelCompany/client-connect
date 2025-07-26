import 'package:client_connect/src/core/design_system/design_tokens.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show TimeOfDay, showDatePicker, showTimePicker;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../templates/logic/template_providers.dart';
import '../../clients/data/client_model.dart';
import '../../templates/data/template_model.dart';
import '../../templates/presentation/widgets/template_preview_dialog.dart';
import '../logic/campaign_providers.dart';
import 'widgets/smart_client_selector_modal.dart';


class CampaignCreationScreen extends ConsumerStatefulWidget {
  const CampaignCreationScreen({super.key});

  @override
  ConsumerState<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends ConsumerState<CampaignCreationScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  final _campaignNameController = TextEditingController();
  final _searchController = TextEditingController();
  
  List<ClientModel> _selectedClients = [];
  TemplateModel? _selectedTemplate;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;

  Timer? _debounceTimer;
  late AnimationController _stepAnimationController;
  late Animation<double> _stepAnimation;

  // Form validation
  final Map<String, String?> _validationErrors = {};
  // final bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    _stepAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stepAnimation = CurvedAnimation(
      parent: _stepAnimationController,
      curve: Curves.easeInOut,
    );
    _stepAnimationController.forward();
  }

  @override
  void dispose() {
    _campaignNameController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _stepAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(campaignCreationProvider);
    
    return ScaffoldPage(
      header: _buildEnhancedHeader(creationState),
      content: Column(
        children: [
          // Enhanced progress indicator
          _buildEnhancedProgressIndicator(),
          
          // Main content with animation
          Expanded(
            child: AnimatedBuilder(
              animation: _stepAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - _stepAnimation.value) * 20),
                  child: Opacity(
                    opacity: _stepAnimation.value,
                    child: _buildStepContent(),
                  ),
                );
              },
            ),
          ),
          
          // Enhanced navigation footer
          _buildEnhancedNavigationFooter(creationState),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(CampaignCreationState creationState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Back button with enhanced styling
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(FluentIcons.back, size: 16),
              onPressed: creationState.isLoading ? null : () => context.go('/campaigns'),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Enhanced title section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Campaign',
                  style: FluentTheme.of(context).typography.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: FluentTheme.of(context).accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepDescription(),
                  style: FluentTheme.of(context).typography.body?.copyWith(
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
          
          // Enhanced status indicators
          if (creationState.isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Creating...', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProgressIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step indicators with enhanced design
          Row(
            children: [
              _buildEnhancedStepIndicator(0, 'Select Audience', FluentIcons.people),
              _buildConnector(0),
              _buildEnhancedStepIndicator(1, 'Choose Template', FluentIcons.mail),
              _buildConnector(1),
              _buildEnhancedStepIndicator(2, 'Review & Send', FluentIcons.send),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (_currentStep + 1) / 3,
              child: Container(
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStepIndicator(int step, String title, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    final isUpcoming = _currentStep < step;
    
    return Expanded(
      child: Column(
        children: [
          // Step circle with enhanced design
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green 
                  : isActive 
                      ? FluentTheme.of(context).accentColor 
                      : Colors.grey[200],
              shape: BoxShape.circle,
              boxShadow: isActive ? [
                BoxShadow(
                  color: FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isCompleted
                    ? const Icon(FluentIcons.check_mark, color: Colors.white, size: 20)
                    : Icon(
                        icon,
                        color: isActive || isCompleted ? Colors.white : Colors.grey[100],
                        size: 20,
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Step title with enhanced styling
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive 
                  ? FluentTheme.of(context).accentColor
                  : isUpcoming 
                      ? Colors.grey[100]
                      : Colors.grey[200],
            ),
            textAlign: TextAlign.center,
          ),
          
          // Step validation indicator
          if (isCompleted)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Complete',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConnector(int step) {
    final isCompleted = _currentStep > step;
    
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isCompleted 
              ? Colors.green 
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEnhancedAudienceSelection();
      case 1:
        return _buildEnhancedTemplateSelection();
      case 2:
        return _buildEnhancedReviewAndSchedule();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnhancedAudienceSelection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced header with statistics
              _buildSectionHeader(
                'Select Your Audience',
                'Choose which clients will receive this campaign',
                additionalWidget: _selectedClients.isNotEmpty
                    ? _buildAudienceStats()
                    : null,
              ),
              
              const SizedBox(height: 24),
              
              // Client selection card with open modal button
              _buildClientSelectionCard(),
              
              const SizedBox(height: 20),
              
              // Selected clients list (if any)
              _selectedClients.isNotEmpty
                ? _buildSelectedClientsList()
                : _buildEmptySelectionState(),
              
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.people_add,
                  size: 24,
                  color: FluentTheme.of(context).accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Clients',
                      style: FluentTheme.of(context).typography.subtitle?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose which clients will receive this campaign',
                      style: TextStyle(
                        color: Colors.grey[100],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Client selection button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _openClientSelectorModal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(FluentIcons.people_add, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedClients.isEmpty
                          ? 'Select Clients'
                          : 'Add or Remove Clients',
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          if (_selectedClients.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Selection summary
            Row(
              children: [
                Icon(
                  FluentIcons.info,
                  size: 16,
                  color: Colors.grey[100],
                ),
                const SizedBox(width: 8),
                Text(
                  'Selected ${_selectedClients.length} clients',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[100],
                  ),
                ),
                const Spacer(),
                Button(
                  onPressed: () {
                    setState(() => _selectedClients.clear());
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedClientsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Clients',
          style: FluentTheme.of(context).typography.subtitle?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _selectedClients.length,
          itemBuilder: (context, index) {
            final client = _selectedClients[index];
            return _buildSelectedClientCard(client);
          },
        ),
      ],
    );
  }

  Widget _buildSelectedClientCard(ClientModel client) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Client avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: FluentTheme.of(context).accentColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Client details
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (client.email != null) ...[
                        Icon(
                          FluentIcons.mail,
                          size: 12,
                          color: Colors.grey[100],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client.email!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (client.company != null) ...[
                        Icon(
                          FluentIcons.build,
                          size: 12,
                          color: Colors.grey[100],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client.company!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Remove button
            IconButton(
              icon: Icon(
                FluentIcons.cancel,
                size: 16,
                color: Colors.red,
              ),
              onPressed: () {
                setState(() {
                  _selectedClients.removeWhere((c) => c.id == client.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySelectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              FluentIcons.people_add,
              size: 40,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Clients Selected',
            style: FluentTheme.of(context).typography.subtitle?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click the "Select Clients" button to choose\nwho will receive this campaign',
            style: TextStyle(
              color: Colors.grey[100],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _openClientSelectorModal,
            child: const Text('Select Clients'),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTemplateSelection() {
    final templatesAsync = ref.watch(templatesProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced header
              _buildSectionHeader(
                'Choose Your Template',
                'Select the message template for this campaign',
                additionalWidget: _selectedTemplate != null
                    ? _buildTemplatePreviewButton()
                    : null,
              ),
              
              const SizedBox(height: 24),
              
              // Template type filter
              _buildTemplateTypeFilter(),
              
              const SizedBox(height: 20),
              
              // Enhanced template list
              templatesAsync.when(
                data: (templates) => _buildEnhancedTemplateList(templates),
                loading: () => _buildTemplateListSkeleton(),
                error: (error, stack) => _buildErrorState('Failed to load templates: $error'),
                
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedReviewAndSchedule() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced header
            _buildSectionHeader(
              'Review & Schedule',
              'Review your campaign details and choose when to send',
            ),
            
            const SizedBox(height: 24),
            
            // Campaign name section
            _buildCampaignNameSection(),
            
            const SizedBox(height: 24),
            
            // Campaign overview cards
            _buildCampaignOverviewCards(),
            
            const SizedBox(height: 24),
            
            // Detailed summary
            _buildDetailedCampaignSummary(),
            
            const SizedBox(height: 24),
            
            // Enhanced scheduling section
            _buildEnhancedSchedulingSection(),
            
            const SizedBox(height: 24),
            
            // Validation warnings
            if (_getValidationWarnings().isNotEmpty)
              _buildValidationWarnings(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, {Widget? additionalWidget}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: FluentTheme.of(context).typography.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: FluentTheme.of(context).typography.body?.copyWith(
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
        ),
        if (additionalWidget != null) ...[
          const SizedBox(width: 16),
          additionalWidget,
        ],
      ],
    );
  }

  Widget _buildAudienceStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FluentTheme.of(context).accentColor,
            FluentTheme.of(context).accentColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(FluentIcons.people, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '${_selectedClients.length} Selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatePreviewButton() {
    return Button(
      onPressed: () => _showTemplatePreview(_selectedTemplate!),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(FluentIcons.preview, size: 16),
          SizedBox(width: 8),
          Text('Preview Template'),
        ],
      ),
    );
  }

  Widget _buildTemplateTypeFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.neutralWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
      ),
      child: Row(
        children: [
          Icon(FluentIcons.filter, size: 16, color: Colors.grey[100]),
          const SizedBox(width: 8),
          Text(
            'Filter by type:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[200],
            ),
          ),
          const SizedBox(width: 16),
          _buildTypeFilterChip('All', null),
          const SizedBox(width: 8),
          _buildTypeFilterChip('Email', 'email'),
          const SizedBox(width: 8),
          _buildTypeFilterChip('WhatsApp', 'whatsapp'),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, String? type) {
    // For now, we'll just show all templates
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[150]),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildEnhancedTemplateList(List<TemplateModel> templates) {
    if (templates.isEmpty) {
      return _buildEmptyState(
        'No templates available',
        'Create templates first to use in campaigns',
        FluentIcons.mail,
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      itemCount: templates.length,
      itemBuilder: (context, index) => _buildEnhancedTemplateCard(templates[index]),
    );
  }

  Widget _buildEnhancedTemplateCard(TemplateModel template) {
    final isSelected = _selectedTemplate?.id == template.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
              ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? FluentTheme.of(context).accentColor
                : Colors.grey[200],
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: HoverButton(
            onPressed: () {
              setState(() => _selectedTemplate = template);
            },
            builder: (context, states) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Template type icon
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: template.isEmail 
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        template.isEmail ? FluentIcons.mail : FluentIcons.chat,
                        color: template.isEmail ? Colors.blue : Colors.green,
                        size: 24,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Template details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: template.isEmail 
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  template.type.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: template.isEmail ? Colors.blue : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (template.subject != null) ...[
                            Text(
                              'Subject: ${template.subject}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            template.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[100],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Actions
                    Column(
                      children: [
                        // Selection indicator
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? FluentTheme.of(context).accentColor
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected 
                                  ? FluentTheme.of(context).accentColor
                                  : Colors.grey[150],
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: isSelected
                              ? const Icon(FluentIcons.check_mark, color: Colors.white, size: 14)
                              : null,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Preview button
                        IconButton(
                          icon: Icon(FluentIcons.preview, size: 16, color: Colors.grey[100]),
                          onPressed: () => _showTemplatePreview(template),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateListSkeleton() {
    return ListView.builder(
      itemCount: 3,
      shrinkWrap: true,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignNameSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              Icon(FluentIcons.edit, size: 16, color: Colors.grey[100]),
              const SizedBox(width: 8),
              Text(
                'Campaign Name *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[200],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormBox(
            controller: _campaignNameController,
            placeholder: 'Enter a descriptive name for your campaign...',
            onChanged: (value) {
              setState(() {
                if (value.trim().isEmpty) {
                  _validationErrors['campaignName'] = 'Campaign name is required';
                } else {
                  _validationErrors.remove('campaignName');
                }
              });
            },
          ),
          if (_validationErrors['campaignName'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationErrors['campaignName']!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCampaignOverviewCards() {
    return Row(
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
            'Est. Duration',
            _getEstimatedSendTime(),
            FluentIcons.clock,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[100],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCampaignSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FluentIcons.info,
                  size: 20,
                  color: FluentTheme.of(context).accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Campaign Summary',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
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
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedTemplate!.subject != null) ...[
                    Text(
                      'Subject: ${TemplatePreviewService.generatePreview(_selectedTemplate!, _selectedClients.first).split('\n').first}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    TemplatePreviewService.generatePreview(
                      _selectedTemplate!,
                      _selectedClients.first,
                    ),
                    style: const TextStyle(fontSize: 13),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSchedulingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  FluentIcons.calendar,
                  size: 20,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Schedule Options',
                style: FluentTheme.of(context).typography.subtitle?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Scheduling options
          Row(
            children: [
              Expanded(
                child: _buildScheduleOption(
                  'Send Now',
                  'Campaign will start immediately',
                  FluentIcons.send,
                  _scheduledDate == null,
                  () {
                    setState(() {
                      _scheduledDate = null;
                      _scheduledTime = null;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildScheduleOption(
                  'Schedule Later',
                  _scheduledDate != null 
                      ? _formatScheduledTime()
                      : 'Choose date and time',
                  FluentIcons.calendar,
                  _scheduledDate != null,
                  _showSchedulePicker,
                ),
              ),
            ],
          ),
          
          // Scheduled time display
          if (_scheduledDate != null && _scheduledTime != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(FluentIcons.clock, size: 16, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campaign Scheduled',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Will start sending on ${_formatScheduledTime()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.edit, size: 16),
                    onPressed: _showSchedulePicker,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleOption(String title, String subtitle, IconData icon, bool isSelected, VoidCallback onTap) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected 
            ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected 
              ? FluentTheme.of(context).accentColor
              : Colors.grey[200],
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: HoverButton(
          onPressed: onTap,
          builder: (context, states) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? FluentTheme.of(context).accentColor.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isSelected 
                          ? FluentTheme.of(context).accentColor
                          : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected 
                          ? FluentTheme.of(context).accentColor
                          : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[100],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildValidationWarnings() {
    final warnings = _getValidationWarnings();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.warning, size: 20, color: Colors.yellow),
              const SizedBox(width: 12),
              const Text(
                'Please Review',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 6, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Text(
                    warning,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEnhancedNavigationFooter(CampaignCreationState creationState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200])),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Step info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Step ${_currentStep + 1} of 3',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation buttons
          if (_currentStep > 0) ...[
            Button(
              onPressed: creationState.isLoading ? null : _goToPreviousStep,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.chevron_left, size: 16),
                  SizedBox(width: 4),
                  Text('Back'),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          if (_currentStep < 2)
            FilledButton(
              onPressed: (_canProceedToNext() && !creationState.isLoading) 
                  ? _goToNextStep
                  : null,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next'),
                  SizedBox(width: 4),
                  Icon(FluentIcons.chevron_right, size: 16),
                ],
              ),
            ),
          
          if (_currentStep == 2)
            FilledButton(
              onPressed: (_canCreateCampaign() && !creationState.isLoading) 
                  ? _createCampaign 
                  : null,
              child: creationState.isLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: ProgressRing(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Creating...'),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.send, size: 16),
                        SizedBox(width: 4),
                        Text('Create Campaign'),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, size: 40, color: Colors.grey[200]),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[100],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(FluentIcons.error, size: 40, color: Colors.red),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[100],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return 'Select which clients will receive your campaign';
      case 1:
        return 'Choose the message template to send';
      case 2:
        return 'Review details and schedule your campaign';
      default:
        return '';
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Select Audience';
      case 1:
        return 'Choose Template';
      case 2:
        return 'Review & Send';
      default:
        return '';
    }
  }

  void _goToNextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _stepAnimationController.reset();
      _stepAnimationController.forward();
    }
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
    } else {
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
      
      if (time != null && mounted) {
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
    
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return '${dateFormat.format(scheduledDateTime)} at ${timeFormat.format(scheduledDateTime)}';
  }

  void _showTemplatePreview(TemplateModel template) {
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

  void _openClientSelectorModal() {
    showDialog(
      context: context,
      builder: (context) => SmartClientSelectorModal(
        initialSelectedClients: _selectedClients,
        campaignContext: _campaignNameController.text.isNotEmpty 
            ? _campaignNameController.text 
            : _selectedTemplate?.name,
        onConfirm: (selectedClients) {
          setState(() => _selectedClients = selectedClients);
          Navigator.pop(context);
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  void _createCampaign() async {
    if (!mounted) return;
    
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

      if (!mounted) return;

      if (campaignId != null) {
        final formattedTime = _formatScheduledTime();
        final campaignName = _campaignNameController.text;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Campaign Created Successfully'),
              content: Text(
                scheduledDateTime == null
                    ? 'Campaign "$campaignName" has been created and is now sending messages.'
                    : 'Campaign "$campaignName" has been scheduled for $formattedTime.',
              ),
              severity: InfoBarSeverity.success,
              onClose: close,
            ),
          );
          
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              context.go('/campaigns');
            }
          });
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          
          displayInfoBar(
            context,
            builder: (context, close) => InfoBar(
              title: const Text('Error Creating Campaign'),
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