import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show ExpansionTile, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../logic/campaign_providers.dart';
import '../../../clients/logic/client_providers.dart';

class RealTimeMessageLogs extends ConsumerStatefulWidget {
  final int campaignId;
  final bool showFilters;
  final bool showExportButton;

  const RealTimeMessageLogs({
    super.key,
    required this.campaignId,
    this.showFilters = true,
    this.showExportButton = true,
  });

  @override
  ConsumerState<RealTimeMessageLogs> createState() => _RealTimeMessageLogsState();
}

class _RealTimeMessageLogsState extends ConsumerState<RealTimeMessageLogs> {
  String _selectedFilter = 'all';
  String _searchTerm = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(realTimeMessageLogsProvider(widget.campaignId));
    final theme = FluentTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with filters and actions
          _buildHeader(theme),
          
          // Message logs list
          Expanded(
            child: logsAsync.when(
              data: (logs) => _buildLogsList(theme, logs),
              loading: () => const Center(child: ProgressRing()),
              error: (error, stack) => _buildErrorState(theme, error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(FluentThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]),
        ),
      ),
      child: Column(
        children: [
          // Title and actions row
          Row(
            children: [
              Icon(FluentIcons.mail, size: 20, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                'Real-Time Message Logs',
                style: theme.typography.bodyStrong,
              ),
              const Spacer(),
              if (widget.showExportButton)
                Button(
                  onPressed: _exportLogs,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.download, size: 14),
                      SizedBox(width: 4),
                      Text('Export'),
                    ],
                  ),
                ),
            ],
          ),
          
          if (widget.showFilters) ...[
            const SizedBox(height: 16),
            
            // Search and filters row
            Row(
              children: [
                // Search box
                Expanded(
                  child: TextBox(
                    controller: _searchController,
                    placeholder: 'Search by client name or email...',
                    prefix: const Icon(FluentIcons.search, size: 16),
                    onChanged: (value) => setState(() => _searchTerm = value),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Status filter dropdown
                SizedBox(
                  width: 120,
                  child: ComboBox<String>(
                    value: _selectedFilter,
                    items: const [
                      ComboBoxItem(value: 'all', child: Text('All Status')),
                      ComboBoxItem(value: 'sent', child: Text('Sent')),
                      ComboBoxItem(value: 'failed', child: Text('Failed')),
                      ComboBoxItem(value: 'pending', child: Text('Pending')),
                      ComboBoxItem(value: 'retrying', child: Text('Retrying')),
                    ],
                    onChanged: (value) => setState(() => _selectedFilter = value ?? 'all'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogsList(FluentThemeData theme, List<EnhancedMessageLog> logs) {
    final filteredLogs = _filterLogs(logs);
    
    if (filteredLogs.isEmpty) {
      return _buildEmptyState(theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredLogs.length,
      itemBuilder: (context, index) {
        final log = filteredLogs[index];
        return _buildLogItem(theme, log);
      },
    );
  }

  Widget _buildLogItem(FluentThemeData theme, EnhancedMessageLog enhancedLog) {
    final log = enhancedLog.messageLog;
    final clientAsync = ref.watch(clientByIdProvider(log.clientId));
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusBorderColor(log.status),
          width: 1,
        ),
      ),
      // TODO : try to use fluent_ui instead
      child: Material(
        child: ExpansionTile(
          leading: _buildStatusIndicator(log.status),
          title: clientAsync.when(
            data: (client) => Text(
              client?.fullName ?? 'Unknown Client',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Unknown Client'),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              clientAsync.when(
                data: (client) => Text(
                  log.type == 'email' 
                      ? (client?.email ?? 'No email')
                      : (client?.phone ?? 'No phone'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    log.type == 'email' ? FluentIcons.mail : FluentIcons.chat,
                    size: 12,
                    color: Colors.grey[100],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.type.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[100],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (enhancedLog.hasRetries) ...[
                    Icon(
                      FluentIcons.refresh,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${enhancedLog.deliveryAttempts} attempts',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusBadge(log.status),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(enhancedLog.lastAttemptTime),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[100],
                ),
              ),
            ],
          ),
          children: [
            _buildLogDetails(theme, enhancedLog),
          ],
        ),
      ),
    );
  }

  Widget _buildLogDetails(FluentThemeData theme, EnhancedMessageLog enhancedLog) {
    final log = enhancedLog.messageLog;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[200]),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic information
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Created', _formatTimestamp(log.createdAt)),
              ),
              if (log.sentAt != null)
                Expanded(
                  child: _buildDetailItem('Sent', _formatTimestamp(log.sentAt!)),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Retry information
          if (enhancedLog.hasRetries) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Retry Count', '${log.retryCount}/${log.maxRetries}'),
                ),
                if (log.nextRetryAt != null)
                  Expanded(
                    child: _buildDetailItem('Next Retry', _formatTimestamp(log.nextRetryAt!)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          
          // Error message
          if (log.errorMessage != null) ...[
            Text(
              'Error Details:',
              style: theme.typography.caption?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(
                log.errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Retry logs
          if (enhancedLog.retryLogs.isNotEmpty) ...[
            Text(
              'Retry History:',
              style: theme.typography.caption?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...enhancedLog.retryLogs.map((retryLog) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[150],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Text(
                      'Attempt ${retryLog.retryAttempt}:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        retryLog.errorMessage ?? 'No error message',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Text(
                      _formatTimestamp(retryLog.attemptedAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
          
          // Action buttons
          Row(
            children: [
              if (enhancedLog.isRetryable)
                Button(
                  onPressed: () => _retryMessage(log.id),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(FluentIcons.refresh, size: 12),
                      SizedBox(width: 4),
                      Text('Retry'),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Button(
                onPressed: () => _viewFullLog(enhancedLog),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.view, size: 12),
                    SizedBox(width: 4),
                    Text('View Full Log'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[100],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color = _getStatusColor(status);
    
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    IconData icon = _getStatusIcon(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(FluentThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.mail,
            size: 48,
            color: Colors.grey[100],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all' 
                ? 'No message logs available'
                : 'No $_selectedFilter messages found',
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          Text(
            _searchTerm.isNotEmpty
                ? 'Try adjusting your search criteria'
                : 'Messages will appear here as they are processed',
            style: theme.typography.caption?.copyWith(
              color: Colors.grey[100],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(FluentThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Logs',
            style: theme.typography.bodyStrong?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.typography.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Button(
            onPressed: () => ref.invalidate(realTimeMessageLogsProvider(widget.campaignId)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  List<EnhancedMessageLog> _filterLogs(List<EnhancedMessageLog> logs) {
    var filtered = logs;
    
    // Apply status filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((log) => log.messageLog.status == _selectedFilter).toList();
    }
    
    // Apply search filter
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((log) {
        final client = ref.read(clientByIdProvider(log.messageLog.clientId)).value;
        if (client == null) return false;
        
        final searchLower = _searchTerm.toLowerCase();
        return client.fullName.toLowerCase().contains(searchLower) ||
               (client.email?.toLowerCase().contains(searchLower) ?? false) ||
               (client.phone?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    // Sort by most recent first
    filtered.sort((a, b) => b.lastAttemptTime.compareTo(a.lastAttemptTime));
    
    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
      case 'failed_max_retries':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'retrying':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBorderColor(String status) {
    return _getStatusColor(status).withValues(alpha: 0.3);
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'sent':
        return FluentIcons.completed;
      case 'failed':
      case 'failed_max_retries':
        return FluentIcons.error;
      case 'pending':
        return FluentIcons.clock;
      case 'retrying':
        return FluentIcons.refresh;
      default:
        return FluentIcons.help;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd/MM HH:mm').format(timestamp);
    }
  }

  void _retryMessage(int messageId) async {
    try {
      await ref.read(retryManagementProvider.notifier).retryMessage(messageId);
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Retry Scheduled'),
            content: const Text('The message has been scheduled for retry.'),
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
            title: const Text('Retry Failed'),
            content: Text('Failed to schedule retry: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }

  void _viewFullLog(EnhancedMessageLog enhancedLog) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Full Message Log'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Message ID: ${enhancedLog.messageLog.id}'),
                Text('Campaign ID: ${enhancedLog.messageLog.campaignId}'),
                Text('Client ID: ${enhancedLog.messageLog.clientId}'),
                Text('Type: ${enhancedLog.messageLog.type}'),
                Text('Status: ${enhancedLog.messageLog.status}'),
                Text('Created: ${enhancedLog.messageLog.createdAt}'),
                if (enhancedLog.messageLog.sentAt != null)
                  Text('Sent: ${enhancedLog.messageLog.sentAt}'),
                Text('Retry Count: ${enhancedLog.messageLog.retryCount}/${enhancedLog.messageLog.maxRetries}'),
                if (enhancedLog.messageLog.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  const Text('Error Message:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      enhancedLog.messageLog.errorMessage!,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _exportLogs() async {
    try {
      final logs = await ref.read(realTimeMessageLogsProvider(widget.campaignId).future);
      
      // Here you would implement the actual export functionality
      // For now, we'll just show a success message
      
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Export Started'),
            content: Text('Exporting ${logs.length} message logs...'),
            severity: InfoBarSeverity.info,
            onClose: close,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        displayInfoBar(
          context,
          builder: (context, close) => InfoBar(
            title: const Text('Export Failed'),
            content: Text('Failed to export logs: $e'),
            severity: InfoBarSeverity.error,
            onClose: close,
          ),
        );
      }
    }
  }
}
