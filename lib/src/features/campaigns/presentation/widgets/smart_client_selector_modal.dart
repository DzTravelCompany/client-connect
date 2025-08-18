import 'package:client_connect/constants.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:client_connect/src/core/design_system/component_library.dart';
import 'package:client_connect/src/core/design_system/design_tokens.dart';
import 'package:client_connect/src/features/clients/data/client_model.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:client_connect/src/features/tags/data/tag_model.dart';
import 'package:client_connect/src/features/tags/logic/tag_providers.dart';
import 'package:client_connect/src/features/tags/presentation/widgets/tag_chip.dart';

/// A compact modal dialog for selecting clients with smart suggestions
class SmartClientSelectorModal extends ConsumerStatefulWidget {
  /// The initially selected clients
  final List<ClientModel> initialSelectedClients;
  
  /// The campaign type or context to help with suggestions
  final String? campaignContext;
  
  /// Maximum number of clients that can be selected
  final int? maxSelections;
  
  /// Callback when selection is confirmed
  final void Function(List<ClientModel> selectedClients) onConfirm;
  
  /// Callback when selection is canceled
  final void Function() onCancel;

  const SmartClientSelectorModal({
    super.key,
    required this.initialSelectedClients,
    this.campaignContext,
    this.maxSelections,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  ConsumerState<SmartClientSelectorModal> createState() => _SmartClientSelectorModalState();
}

class _SmartClientSelectorModalState extends ConsumerState<SmartClientSelectorModal> {
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  List<TagModel> _selectedTags = [];
  Timer? _debounceTimer;
  
  // Client selection state
  late List<ClientModel> _selectedClients;
  List<ClientModel> _filteredClients = [];
  List<ClientModel> _suggestedClients = [];
  
  // UI state
  bool _isLoading = false;
  bool _showSuggestions = true;
  bool _showAdvancedFilters = false;
  
  @override
  void initState() {
    super.initState();
    _selectedClients = List.from(widget.initialSelectedClients);
    _generateSuggestions();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(allClientsProvider);
    final tagsAsync = ref.watch(allTagsProvider);
    
    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
      title: _buildHeader(),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and filter bar
          _buildSearchBar(tagsAsync),
          
          const SizedBox(height: 16),
          
          // Selection stats
          if (_selectedClients.isNotEmpty)
            _buildSelectionStats(),
            
          const SizedBox(height: 8),
          
          // Smart suggestions section
          if (_showSuggestions && _suggestedClients.isNotEmpty)
            _buildSuggestionsSection(),
            
          const SizedBox(height: 16),
          
          // Client list
          Expanded(
            child: clientsAsync.when(
              data: (clients) => _buildClientList(clients),
              loading: () => DesignSystemComponents.loadingIndicator(
                message: 'Loading clients...',
              ),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: widget.onCancel,
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedClients.isEmpty 
              ? null 
              : () => widget.onConfirm(_selectedClients),
          child: Text(
            _selectedClients.isEmpty
                ? 'Select Clients'
                : 'Confirm (${_selectedClients.length})',
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(FluentIcons.people_add, size: 20),
        const SizedBox(width: 8),
        const Text('Select Clients'),
        const Spacer(),
        if (_selectedClients.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.accentPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_selectedClients.length} selected',
              style: TextStyle(
                color: DesignTokens.accentPrimary,
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(FluentIcons.clear_selection, size: 16),
            onPressed: () {
              setState(() => _selectedClients.clear());
            },
          ),
        ],
      ],
    );
  }
  
  Widget _buildSearchBar(AsyncValue<List<TagModel>> tagsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input with filter toggle
        Row(
          children: [
            Expanded(
              child: DesignSystemComponents.textInput(
                controller: _searchController,
                placeholder: 'Search by name, email, or company...',
                prefixIcon: FluentIcons.search,
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _searchTerm = value);
                      _applyFilters();
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            DesignSystemComponents.secondaryButton(
              text: 'Filters',
              icon: _showAdvancedFilters ? FluentIcons.filter_solid : FluentIcons.filter,
              onPressed: () {
                setState(() => _showAdvancedFilters = !_showAdvancedFilters);
              },
            ),
          ],
        ),
        
        // Advanced filters (collapsible)
        AnimatedContainer(
          duration: DesignTokens.animationNormal,
          height: _showAdvancedFilters ? null : 0,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: _showAdvancedFilters ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter by tags:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                tagsAsync.when(
                  data: (tags) => _buildTagFilters(tags),
                  loading: () => const SizedBox(
                    height: 32,
                    child: ProgressRing(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('Failed to load tags'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    DesignSystemComponents.secondaryButton(
                      text: 'Clear Filters',
                      icon: FluentIcons.clear_filter,
                      onPressed: _hasActiveFilters() ? () {
                        setState(() {
                          _searchController.clear();
                          _searchTerm = '';
                          _selectedTags = [];
                        });
                        _applyFilters();
                      } : null,
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredClients.length} clients match filters',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ) : null,
        ),
      ],
    );
  }
  
  Widget _buildTagFilters(List<TagModel> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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
            _applyFilters();
          },
        );
      }).toList(),
    );
  }
  
  Widget _buildSelectionStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.accentPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: DesignTokens.accentPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FluentIcons.people_add,
            size: 16,
            color: DesignTokens.accentPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            '${_selectedClients.length} clients selected',
            style: TextStyle(
              fontWeight: DesignTokens.fontWeightMedium,
              color: DesignTokens.accentPrimary,
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
    );
  }
  
  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              FluentIcons.lightbulb,
              size: 16,
              color: DesignTokens.semanticInfo,
            ),
            const SizedBox(width: 8),
            Text(
              'Suggested Clients',
              style: TextStyle(
                fontWeight: DesignTokens.fontWeightSemiBold,
                fontSize: DesignTokens.fontSizeBodyLarge,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(FluentIcons.chrome_close, size: 12),
              onPressed: () {
                setState(() => _showSuggestions = false);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestedClients.length,
            itemBuilder: (context, index) {
              final client = _suggestedClients[index];
              final isSelected = _selectedClients.any((c) => c.id == client.id);
              
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                child: _buildSuggestedClientCard(client, isSelected),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
  
  Widget _buildSuggestedClientCard(ClientModel client, bool isSelected) {
    return Card(
      padding: EdgeInsets.zero,
      backgroundColor: isSelected 
          ? DesignTokens.accentPrimary.withValues(alpha: 0.1)
          : null,
      borderColor: isSelected 
          ? DesignTokens.accentPrimary
          : null,
      child: HoverButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedClients.removeWhere((c) => c.id == client.id);
            } else {
              _selectedClients.add(client);
            }
          });
        },
        builder: (context, states) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: DesignTokens.accentPrimary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: DesignTokens.fontWeightBold,
                            color: DesignTokens.accentPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        client.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        FluentIcons.check_mark,
                        size: 16,
                        color: DesignTokens.accentPrimary,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (client.email != null)
                  _buildClientDetailRow(FluentIcons.mail, client.email!),
                if (client.company != null)
                  _buildClientDetailRow(FluentIcons.build, client.company!),
                const Spacer(),
                _buildSuggestionReason(client),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSuggestionReason(ClientModel client) {
    // TODO This would be replaced with actual suggestion reasoning
    String reason = 'Engaged with similar campaigns';
    
    if (client.id % 3 == 0) {
      reason = 'Recently active client';
    } else if (client.id % 3 == 1) {
      reason = 'High engagement rate';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.semanticInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        reason,
        style: TextStyle(
          fontSize: 10,
          color: DesignTokens.semanticInfo,
          fontWeight: DesignTokens.fontWeightMedium,
        ),
      ),
    );
  }
  
  Widget _buildClientList(List<ClientModel> clients) {
    if (_isLoading) {
      return DesignSystemComponents.loadingIndicator(
        message: 'Filtering clients...',
      );
    }
    
    if (_filteredClients.isEmpty && _searchTerm.isEmpty && _selectedTags.isEmpty) {
      // Initialize filtered clients if needed
      _filteredClients = clients;
    }
    
    final displayClients = _filteredClients.isNotEmpty ? _filteredClients : clients;
    
    if (displayClients.isEmpty) {
      return _buildEmptyState(
        'No clients match your filters',
        'Try adjusting your search criteria',
        FluentIcons.search,
      );
    }
    
    return Material(
      color: Colors.transparent,
      child: ListView.builder(
        itemCount: displayClients.length,
        itemBuilder: (context, index) {
          final client = displayClients[index];
          final isSelected = _selectedClients.any((c) => c.id == client.id);
          
          return _buildClientListItem(client, isSelected);
        },
      ),
    );
  }
  
  Widget _buildClientListItem(ClientModel client, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected 
            ? DesignTokens.accentPrimary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected 
              ? DesignTokens.accentPrimary
              : Colors.transparent,
        ),
      ),
      child: HoverButton(
        onPressed: () {
          setState(() {
            if (isSelected) {
              _selectedClients.removeWhere((c) => c.id == client.id);
            } else {
              if (widget.maxSelections != null && 
                  _selectedClients.length >= widget.maxSelections!) {
                // Show max selection warning
                _showMaxSelectionWarning();
                return;
              }
              _selectedClients.add(client);
            }
          });
        },
        builder: (context, states) {
          final isHovered = states.contains(WidgetState.hovered);
          
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isHovered && !isSelected
                  ? DesignTokens.neutralGray100
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? DesignTokens.accentPrimary
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected 
                          ? DesignTokens.accentPrimary
                          : DesignTokens.borderPrimary,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isSelected
                      ? const Icon(FluentIcons.check_mark, color: Colors.white, size: 12)
                      : null,
                ),
                
                const SizedBox(width: 12),
                
                // Client avatar
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DesignTokens.neutralGray400,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      client.firstName.isNotEmpty ? client.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                          color: DesignTokens.neutralBlack,
                        ),
                      ),
                      if (client.email != null || client.company != null)
                        Row(
                          children: [
                            if (client.email != null) ...[
                              Icon(
                                FluentIcons.mail,
                                size: 12,
                                color: DesignTokens.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                client.email!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            if (client.company != null) ...[
                              Icon(
                                FluentIcons.build,
                                size: 12,
                                color: DesignTokens.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                client.company!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Quick actions
                if (isHovered || isSelected)
                  IconButton(
                    icon: Icon(
                      isSelected ? FluentIcons.cancel : FluentIcons.add,
                      size: 16,
                      color: isSelected 
                          ? DesignTokens.semanticError
                          : DesignTokens.accentPrimary,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isSelected) {
                          _selectedClients.removeWhere((c) => c.id == client.id);
                        } else {
                          if (widget.maxSelections != null && 
                              _selectedClients.length >= widget.maxSelections!) {
                            // Show max selection warning
                            _showMaxSelectionWarning();
                            return;
                          }
                          _selectedClients.add(client);
                        }
                      });
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildClientDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: DesignTokens.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: DesignTokens.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: DesignTokens.neutralGray100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 30, color: DesignTokens.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: DesignTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_hasActiveFilters())
            Button(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _searchTerm = '';
                  _selectedTags = [];
                });
                _applyFilters();
              },
              child: const Text('Clear Filters'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: DesignTokens.semanticError.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.error,
              size: 30,
              color: DesignTokens.semanticError,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error Loading Clients',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: DesignTokens.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Button(
            onPressed: () {
              final _ = ref.refresh(allClientsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  
  void _applyFilters() {
    setState(() => _isLoading = true);
    
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      
      final clientsAsync = ref.read(allClientsProvider);
      await clientsAsync.when(
        data: (clients) async {
          if (!mounted) return;
          
          List<ClientModel> filtered = clients;
          
          // Apply search filter
          if (_searchTerm.isNotEmpty) {
            final searchLower = _searchTerm.toLowerCase();
            filtered = filtered.where((client) {
              return client.fullName.toLowerCase().contains(searchLower) ||
                  (client.email?.toLowerCase().contains(searchLower) ?? false) ||
                  (client.company?.toLowerCase().contains(searchLower) ?? false);
            }).toList();
          }
          
          if (_selectedTags.isNotEmpty) {
            try {
              final tagNames = _selectedTags.map((tag) => tag.name).toList();
              final clientDao = ref.read(clientDaoProvider);
              final taggedClients = await clientDao.getClientsByTags(tagNames);
              final taggedClientIds = taggedClients.map((c) => c.id).toSet();
              
              // Filter the current list to only include clients with selected tags
              filtered = filtered.where((client) => taggedClientIds.contains(client.id)).toList();
            } catch (e) {
              // Fallback to original filtering if database query fails
              logger.e('Error filtering by tags: $e');
            }
          }
          
          if (mounted) {
            setState(() {
              _filteredClients = filtered;
              _isLoading = false;
            });
          }
        },
        loading: () {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
        error: (error, stack) {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    });
  }
  
  bool _hasActiveFilters() {
    return _searchTerm.isNotEmpty || _selectedTags.isNotEmpty;
  }
  
  void _generateSuggestions() {
    // In a real implementation, this would use AI or analytics to generate suggestions
    // based on the campaign context, client engagement history, etc.
    
    final clientsAsync = ref.read(allClientsProvider);
    clientsAsync.whenData((clients) {
      if (!mounted) return;
      
      // Simulate AI-generated suggestions
      // In a real implementation, this would use more sophisticated logic
      final suggestions = clients.where((client) {
        // Example logic: suggest clients with high engagement or recent activity
        // This is just a placeholder - real logic would be more complex
        if (widget.campaignContext?.toLowerCase().contains('newsletter') ?? false) {
          // For newsletter campaigns, suggest clients with email addresses
          return client.email != null && client.email!.isNotEmpty;
        } else if (widget.campaignContext?.toLowerCase().contains('promo') ?? false) {
          // For promotional campaigns, suggest clients from specific companies
          return client.company != null && 
                 ['Acme Inc', 'TechCorp', 'Global Services'].contains(client.company);
        }
        
        // Default suggestion logic: clients with even IDs (just for demonstration)
        return client.id % 2 == 0;
      }).take(10).toList();
      
      setState(() => _suggestedClients = suggestions);
    });
  }
  
  void _showMaxSelectionWarning() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Maximum Selection Reached'),
        content: Text(
          'You can select a maximum of ${widget.maxSelections} clients. '
          'Please remove some clients before adding more.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Provider for client suggestions based on campaign context
final clientSuggestionsProvider = FutureProvider.family<List<ClientModel>, String?>((ref, campaignContext) async {
  // In a real implementation, this would use AI or analytics to generate suggestions
  // based on the campaign context, client engagement history, etc.
  
  final allClients = await ref.watch(allClientsProvider.future);
  
  // Simulate AI-generated suggestions
  // In a real implementation, this would use more sophisticated logic
  final suggestions = allClients.where((client) {
    // Example logic: suggest clients with high engagement or recent activity
    // This is just a placeholder - real logic would be more complex
    if (campaignContext?.toLowerCase().contains('newsletter') ?? false) {
      // For newsletter campaigns, suggest clients with email addresses
      return client.email != null && client.email!.isNotEmpty;
    } else if (campaignContext?.toLowerCase().contains('promo') ?? false) {
      // For promotional campaigns, suggest clients from specific companies
      return client.company != null && 
             ['Acme Inc', 'TechCorp', 'Global Services'].contains(client.company);
    }
    
    // Default suggestion logic: clients with even IDs (just for demonstration)
    return client.id % 2 == 0;
  }).take(10).toList();
  
  return suggestions;
});