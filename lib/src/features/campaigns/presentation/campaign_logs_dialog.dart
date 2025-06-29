import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart';
import 'package:client_connect/src/features/clients/logic/client_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logic/campaign_providers.dart';


class MessageLogsDialog extends ConsumerStatefulWidget {
  final int campaignId;
  
  const MessageLogsDialog({super.key, required this.campaignId});

  @override
  ConsumerState<MessageLogsDialog> createState() => _MessageLogsDialogState();
}

class _MessageLogsDialogState extends ConsumerState<MessageLogsDialog> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final messageLogsAsync = ref.watch(campaignMessageLogsProvider(widget.campaignId));
    final campaignAsync = ref.watch(campaignByIdProvider(widget.campaignId));

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
      title: campaignAsync.when(
        data: (campaign) => Text('Message Logs - ${campaign?.name ?? 'Campaign'}'),
        loading: () => const Text('Message Logs'),
        error: (_, __) => const Text('Message Logs'),
      ),
      content: Column(
        children: [
          // Filter tabs
          Row(
            children: [
              _buildFilterTab('all', 'All Messages'),
              const SizedBox(width: 8),
              _buildFilterTab('sent', 'Sent'),
              const SizedBox(width: 8),
              _buildFilterTab('failed', 'Failed'),
              const SizedBox(width: 8),
              _buildFilterTab('pending', 'Pending'),
            ],
          ),
          const SizedBox(height: 16),
          
          // Message logs list
          Expanded(
            child: messageLogsAsync.when(
              data: (logs) {
                final filteredLogs = _filterLogs(logs);
                
                if (filteredLogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(FluentIcons.mail, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'all' 
                              ? 'No messages found'
                              : 'No $_selectedFilter messages',
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];
                    return _buildMessageLogItem(log);
                  },
                );
              },
              loading: () => const Center(child: ProgressRing()),
              error: (error, stack) => Center(
                child: Text('Error loading logs: $error'),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Button(
          child: const Text('Close'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String value, String label) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FluentTheme.of(context).accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? FluentTheme.of(context).accentColor : Colors.grey[60],
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : null,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageLogItem(MessageLogModel log) {
    final clientAsync = ref.watch(clientByIdProvider(log.clientId));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getStatusColor(log.status),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Message type icon
            Icon(
              log.type == 'email' ? FluentIcons.mail : FluentIcons.chat,
              size: 16,
              color: Colors.grey[100],
            ),
            const SizedBox(width: 12),
            
            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  clientAsync.when(
                    data: (client) => Text(
                      client?.fullName ?? 'Unknown Client',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    loading: () => const Text('Loading...'),
                    error: (_, __) => const Text('Unknown Client'),
                  ),
                  const SizedBox(height: 2),
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
                ],
              ),
            ),
            
            // Status and timestamp
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(log.status),
                const SizedBox(height: 4),
                Text(
                  log.sentAt != null 
                      ? _formatDate(log.sentAt!)
                      : _formatDate(log.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
            
            // Error details button
            if (log.isFailed && log.errorMessage != null)
              IconButton(
                icon: Icon(FluentIcons.error, size: 16, color: Colors.red),
                onPressed: () => _showErrorDetails(log.errorMessage!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);
    IconData icon;
    
    switch (status) {
      case 'sent':
        icon = FluentIcons.completed;
        break;
      case 'failed':
        icon = FluentIcons.error;
        break;
      case 'pending':
        icon = FluentIcons.clock;
        break;
      default:
        icon = FluentIcons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'sent':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<MessageLogModel> _filterLogs(List<MessageLogModel> logs) {
    if (_selectedFilter == 'all') return logs;
    return logs.where((log) => log.status == _selectedFilter).toList();
  }

  void _showErrorDetails(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Error Details'),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This message failed to send with the following error:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}