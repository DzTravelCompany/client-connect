import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_connect/src/core/services/retry_service.dart';
import 'package:client_connect/src/features/campaigns/data/campaigns_model.dart' hide RetryLogModel;
import '../../../../constants.dart';


// Provider for retry management state
final retryManagementProvider = StateNotifierProvider<RetryManagementNotifier, RetryManagementState>((ref) {
  return RetryManagementNotifier();
});

// Provider for retryable messages
final retryableMessagesProvider = FutureProvider.family<List<MessageLogModel>, int>((ref, campaignId) async {
  final retryService = RetryService.instance;
  try {
    return await retryService.getRetryableMessagesForCampaign(campaignId);
  } catch (e) {
    logger.e('Error fetching retryable messages: $e');
    throw Exception('Failed to load retryable messages: $e');
  }
});

// Provider for campaign statistics with retry data
final campaignStatisticsProvider = FutureProvider.family<CampaignStatistics, int>((ref, campaignId) async {
  try {
    final retryService = RetryService.instance;
    final retryStats = await retryService.getRetryStatistics(campaignId);
    
    // Calculate basic campaign statistics from retry statistics
    final totalMessages = retryStats.totalMessages;
    final failedMessages = retryStats.messagesWithRetries;
    final sentMessages = totalMessages - failedMessages - retryStats.pendingRetries;
    final pendingMessages = retryStats.pendingRetries;
    final successRate = totalMessages > 0 ? sentMessages / totalMessages : 0.0;
    
    return CampaignStatistics(
      totalMessages: totalMessages,
      sentMessages: sentMessages,
      failedMessages: failedMessages,
      pendingMessages: pendingMessages,
      successRate: successRate,
      retryStatistics: retryStats,
    );
  } catch (e) {
    logger.e('Error fetching campaign statistics: $e');
    throw Exception('Failed to load campaign statistics: $e');
  }
});

class RetryManagementState {
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const RetryManagementState({
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  RetryManagementState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return RetryManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class RetryManagementNotifier extends StateNotifier<RetryManagementState> {
  RetryManagementNotifier() : super(const RetryManagementState());

  final RetryService _retryService = RetryService.instance;

  Future<void> retryCampaign(int campaignId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _retryService.retryFailedMessagesForCampaign(campaignId, reason: reason);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Successfully scheduled retries for all failed messages in the campaign.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to schedule campaign retries: ${e.toString()}',
      );
    }
  }

  Future<void> retryMessage(int messageLogId, {String? reason}) async {
    state = state.copyWith(isLoading: true, error: null, successMessage: null);
    
    try {
      await _retryService.triggerManualRetry(messageLogId, reason: reason);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Successfully scheduled retry for the message.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to schedule message retry: ${e.toString()}',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

class RetryManagementDialog extends ConsumerStatefulWidget {
  final int campaignId;
  final String campaignName;

  const RetryManagementDialog({
    super.key,
    required this.campaignId,
    required this.campaignName,
  });

  @override
  ConsumerState<RetryManagementDialog> createState() => _RetryManagementDialogState();
}

class _RetryManagementDialogState extends ConsumerState<RetryManagementDialog> {
  final TextEditingController _reasonController = TextEditingController();
  int _selectedTabIndex = 0;
  
  // Local state for data loading
  bool _isLoadingData = true;
  String? _dataError;
  List<RetryConfiguration> _retryConfigurations = [];
  List<RetryLogModel> _recentRetryLogs = [];
  StreamSubscription<RetryEvent>? _retryEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenToRetryEvents();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _retryEventSubscription?.cancel();
    super.dispose();
  }

  void _listenToRetryEvents() {
    _retryEventSubscription = RetryService.instance.retryEventStream.listen((event) {
      // Check if this event is for our campaign
      if (mounted && event.campaignId == widget.campaignId) {
        // Refresh data when retry events occur for this campaign
        _loadData();
        // Also refresh providers
        ref.invalidate(retryableMessagesProvider(widget.campaignId));
        ref.invalidate(campaignStatisticsProvider(widget.campaignId));
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingData = true;
      _dataError = null;
    });

    try {
      final retryService = RetryService.instance;
      
      // Load retry statistics with error handling
      RetryStatistics? retryStats;
      try {
        retryStats = await retryService.getRetryStatistics(widget.campaignId);
      } catch (e) {
        logger.e('Error loading retry statistics: $e');
        // Continue with other data loading even if this fails
      }
      
      // Load retry configurations with error handling
      List<RetryConfiguration> configs = [];
      try {
        configs = await retryService.getAllRetryConfigurations();
      } catch (e) {
        logger.e('Error loading retry configurations: $e');
        // Continue with other data loading even if this fails
      }
      
      // Load recent retry logs for this campaign with error handling
      List<RetryLogModel> recentLogs = [];
      try {
        recentLogs = await retryService.getRecentRetryLogsForCampaign(widget.campaignId, limit: 50);
      } catch (e) {
        logger.e('Error loading recent retry logs: $e');
        // Continue with other data loading even if this fails
      }
      
      if (mounted) {
        setState(() {
          _retryConfigurations = configs;
          _recentRetryLogs = recentLogs;
          _isLoadingData = false;
          
          // Set error only if all critical data failed to load
          if (retryStats == null && configs.isEmpty && recentLogs.isEmpty) {
            _dataError = 'Failed to load retry management data. Some features may not be available.';
          }
        });
      }
    } catch (e, stackTrace) {
      logger.e('Critical error loading retry management data: $e');
      logger.e('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() {
          _dataError = 'Critical error loading retry data: ${e.toString()}';
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final retryableMessagesAsync = ref.watch(retryableMessagesProvider(widget.campaignId));
    final campaignStatsAsync = ref.watch(campaignStatisticsProvider(widget.campaignId));
    final retryManagementState = ref.watch(retryManagementProvider);

    return ContentDialog(
      constraints: const BoxConstraints(maxWidth: 800),
      title: Row(
        children: [
          const Icon(FluentIcons.refresh, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Retry Management'),
                Text(
                  'Campaign: ${widget.campaignName}',
                  style: FluentTheme.of(context).typography.caption?.copyWith(
                    color: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Show success/error messages
            if (retryManagementState.successMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.completed, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(retryManagementState.successMessage!)),
                    IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: () => ref.read(retryManagementProvider.notifier).clearMessages(),
                    ),
                  ],
                ),
              ),

            if (retryManagementState.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.error, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(retryManagementState.error!)),
                    IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: () => ref.read(retryManagementProvider.notifier).clearMessages(),
                    ),
                  ],
                ),
              ),

            if (_dataError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(FluentIcons.warning, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_dataError!)),
                    Button(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Tab view
            Expanded(
              child: _isLoadingData
                  ? const Center(child: ProgressRing())
                  : TabView(
                      currentIndex: _selectedTabIndex,
                      onChanged: (index) => setState(() => _selectedTabIndex = index),
                      tabs: [
                        Tab(
                          text: const Text('Overview'),
                          body: _buildOverviewTab(campaignStatsAsync),
                        ),
                        Tab(
                          text: const Text('Failed Messages'),
                          body: _buildFailedMessagesTab(retryableMessagesAsync),
                        ),
                        Tab(
                          text: const Text('Retry Logs'),
                          body: _buildRetryLogsTab(),
                        ),
                        Tab(
                          text: const Text('Bulk Actions'),
                          body: _buildBulkActionsTab(),
                        ),
                        Tab(
                          text: const Text('Configuration'),
                          body: _buildConfigurationTab(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(AsyncValue<CampaignStatistics> statsAsync) {
    return statsAsync.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Statistics',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            // Message statistics
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Messages', stats.totalMessages, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Sent', stats.sentMessages, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Failed', stats.failedMessages, Colors.red)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', stats.pendingMessages, Colors.orange)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Retry Statistics',
              style: FluentTheme.of(context).typography.subtitle,
            ),
            const SizedBox(height: 16),
            
            // Retry statistics
            Row(
              children: [
                Expanded(child: _buildStatCard('Messages with Retries', stats.retryStatistics.messagesWithRetries, Colors.purple)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Total Retry Attempts', stats.retryStatistics.totalRetryAttempts, Colors.teal)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Successful Retries', stats.retryStatistics.successfulRetries, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Failed Retries', stats.retryStatistics.failedRetries, Colors.red)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Success rate
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Success Rates',
                      style: FluentTheme.of(context).typography.bodyStrong,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Overall Success Rate'),
                              const SizedBox(height: 8),
                              ProgressBar(value: stats.successRate * 100),
                              const SizedBox(height: 4),
                              Text('${(stats.successRate * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Retry Success Rate'),
                              const SizedBox(height: 8),
                              ProgressBar(value: stats.retryStatistics.retrySuccessRate * 100),
                              const SizedBox(height: 4),
                              Text('${(stats.retryStatistics.retrySuccessRate * 100).toStringAsFixed(1)}%'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: FluentTheme.of(context).typography.bodyStrong,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Button(
                          onPressed: _loadData,
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(FluentIcons.refresh, size: 16),
                              SizedBox(width: 4),
                              Text('Refresh Data'),
                            ],
                          ),
                        ),
                        if (stats.failedMessages > 0)
                          FilledButton(
                            onPressed: () => _retryAllFailed(),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(FluentIcons.play, size: 16),
                                SizedBox(width: 4),
                                Text('Retry All Failed'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => _buildErrorWidget('Error loading statistics', error.toString(), () {
        ref.invalidate(campaignStatisticsProvider(widget.campaignId));
      }),
    );
  }

  Widget _buildFailedMessagesTab(AsyncValue<List<MessageLogModel>> messagesAsync) {
    return messagesAsync.when(
      data: (messages) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Failed Messages (${messages.length})',
                  style: FluentTheme.of(context).typography.subtitle,
                ),
                const Spacer(),
                if (messages.isNotEmpty) ...[
                  Button(
                    onPressed: () => _showBulkRetryDialog(messages),
                    child: const Text('Retry Selected'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _retryAllFailed(),
                    child: const Text('Retry All'),
                  ),
                ],
              ],
            ),
          ),
          
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.completed, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        const Text('No failed messages to retry'),
                        const SizedBox(height: 8),
                        Text(
                          'All messages in this campaign have been sent successfully.',
                          style: FluentTheme.of(context).typography.caption,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageTile(message);
                    },
                  ),
          ),
        ],
      ),
      loading: () => const Center(child: ProgressRing()),
      error: (error, stack) => _buildErrorWidget('Error loading messages', error.toString(), () {
        ref.invalidate(retryableMessagesProvider(widget.campaignId));
      }),
    );
  }

  Widget _buildRetryLogsTab() {
    if (_recentRetryLogs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.history, size: 64),
            SizedBox(height: 16),
            Text('No retry logs available'),
            SizedBox(height: 8),
            Text('Retry logs will appear here once retry attempts are made.'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Recent Retry Logs (${_recentRetryLogs.length})',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const Spacer(),
              Button(
                onPressed: _loadData,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.refresh, size: 16),
                    SizedBox(width: 4),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentRetryLogs.length,
            itemBuilder: (context, index) {
              final log = _recentRetryLogs[index];
              return _buildRetryLogTile(log);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBulkActionsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Retry Actions',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          
          // Reason input
          TextBox(
            controller: _reasonController,
            placeholder: 'Reason for retry (optional)',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Action buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: ref.watch(retryManagementProvider).isLoading ? null : () => _retryAllFailed(),
                child: ref.watch(retryManagementProvider).isLoading
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: ProgressRing(),
                          ),
                          SizedBox(width: 8),
                          Text('Processing...'),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(FluentIcons.play, size: 16),
                          SizedBox(width: 4),
                          Text('Retry All Failed Messages'),
                        ],
                      ),
              ),
              Button(
                onPressed: ref.watch(retryManagementProvider).isLoading ? null : () => _retryMaxRetriesExceeded(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.reset, size: 16),
                    SizedBox(width: 4),
                    Text('Retry Max Retries Exceeded'),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Information card
          InfoBar(
            title: const Text('Bulk Retry Information'),
            content: const Text(
              '• Bulk retry will reset retry counts for selected messages\n'
              '• Messages will be queued for retry based on the default configuration\n'
              '• You can monitor progress in the campaign details screen\n'
              '• Failed retries will be logged for troubleshooting',
            ),
            severity: InfoBarSeverity.info,
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Retry Configurations',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const Spacer(),
              Button(
                onPressed: () => _showRetryConfigurationDialog(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FluentIcons.add, size: 16),
                    SizedBox(width: 4),
                    Text('New Configuration'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_retryConfigurations.isEmpty)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FluentIcons.settings, size: 64),
                  SizedBox(height: 16),
                  Text('No retry configurations found'),
                  SizedBox(height: 8),
                  Text('Create a configuration to customize retry behavior.'),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _retryConfigurations.length,
                itemBuilder: (context, index) {
                  final config = _retryConfigurations[index];
                  return _buildConfigurationTile(config);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String title, String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.error, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(title, style: FluentTheme.of(context).typography.bodyStrong),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Button(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: FluentTheme.of(context).typography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(MessageLogModel message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: message.canRetry ? Colors.orange : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            
            // Message info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        message.type == 'email' ? FluentIcons.mail : FluentIcons.chat,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Client ID: ${message.clientId}',
                        style: FluentTheme.of(context).typography.bodyStrong,
                      ),
                      const Spacer(),
                      Text(
                        'Status: ${message.status}',
                        style: TextStyle(
                          color: message.status == 'failed' ? Colors.red : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (message.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      message.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[100],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Retries: ${message.retryCount}/${message.maxRetries}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      if (message.nextRetryAt != null) ...[
                        const SizedBox(width: 16),
                        Text(
                          'Next: ${_formatDateTime(message.nextRetryAt!)}',
                          style: FluentTheme.of(context).typography.caption,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Retry button
            const SizedBox(width: 12),
            Button(
              onPressed: message.canRetry ? () => _retryIndividualMessage(message) : null,
              child: Text(message.canRetry ? 'Retry' : 'Max Reached'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryLogTile(RetryLogModel log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status icon
            Icon(
              log.status == 'success' ? FluentIcons.completed : 
              log.status == 'failed' ? FluentIcons.error : FluentIcons.clock,
              color: log.status == 'success' ? Colors.green : 
                     log.status == 'failed' ? Colors.red : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 12),
            
            // Log info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Message ID: ${log.messageLogId}',
                        style: FluentTheme.of(context).typography.bodyStrong,
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(log.attemptedAt),
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Attempt: ${log.attemptNumber}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Status: ${log.status.toUpperCase()}',
                        style: TextStyle(
                          color: log.status == 'success' ? Colors.green : 
                                 log.status == 'failed' ? Colors.red : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Trigger: ${log.triggerType}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                  if (log.errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      log.errorMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[100],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildConfigurationTile(RetryConfiguration config) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Default indicator
            if (config.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'DEFAULT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            if (config.isDefault) const SizedBox(width: 12),
            
            // Configuration info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.name,
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Max Retries: ${config.maxRetries}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Strategy: ${config.backoffStrategy}',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Delay: ${config.initialDelayMinutes}-${config.maxDelayMinutes}min',
                        style: FluentTheme.of(context).typography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Button(
              onPressed: () => _editConfiguration(config),
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkRetryDialog(List<MessageLogModel> messages) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Bulk Retry Confirmation'),
        content: Text(
          'Are you sure you want to retry ${messages.length} failed messages?\n\n'
          'This will reset their retry counts and schedule them for immediate retry.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryMessages(messages);
            },
            child: const Text('Retry All'),
          ),
        ],
      ),
    );
  }

  void _showRetryConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => const RetryConfigurationDialog(),
    ).then((_) => _loadData()); // Refresh data after dialog closes
  }

  void _retryAllFailed() {
    ref.read(retryManagementProvider.notifier).retryCampaign(
      widget.campaignId,
      reason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
    );
  }

  void _retryMaxRetriesExceeded() {
    ref.read(retryManagementProvider.notifier).retryCampaign(
      widget.campaignId,
      reason: 'Manual retry for max retries exceeded messages: ${_reasonController.text}',
    );
  }

  void _retryIndividualMessage(MessageLogModel message) {
    ref.read(retryManagementProvider.notifier).retryMessage(
      message.id,
      reason: 'Manual individual retry: ${_reasonController.text}',
    );
  }

  void _retryMessages(List<MessageLogModel> messages) {
    for (final message in messages) {
      ref.read(retryManagementProvider.notifier).retryMessage(
        message.id,
        reason: 'Bulk manual retry: ${_reasonController.text}',
      );
    }
  }

  void _editConfiguration(RetryConfiguration config) {
    showDialog(
      context: context,
      builder: (context) => RetryConfigurationDialog(existingConfig: config),
    ).then((_) => _loadData()); // Refresh data after dialog closes
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// Configuration dialog for creating/editing retry configurations
class RetryConfigurationDialog extends ConsumerStatefulWidget {
  final RetryConfiguration? existingConfig;

  const RetryConfigurationDialog({
    super.key,
    this.existingConfig,
  });

  @override
  ConsumerState<RetryConfigurationDialog> createState() => _RetryConfigurationDialogState();
}

class _RetryConfigurationDialogState extends ConsumerState<RetryConfigurationDialog> {
  final RetryService _retryService = RetryService.instance;
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _maxRetriesController;
  late TextEditingController _initialDelayController;
  late TextEditingController _maxDelayController;
  
  String _backoffStrategy = 'exponential';
  bool _retryOnNetworkError = true;
  bool _retryOnServerError = true;
  bool _retryOnTimeout = true;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    final config = widget.existingConfig;
    _nameController = TextEditingController(text: config?.name ?? 'Custom Configuration');
    _maxRetriesController = TextEditingController(text: (config?.maxRetries ?? 3).toString());
    _initialDelayController = TextEditingController(text: (config?.initialDelayMinutes ?? 5).toString());
    _maxDelayController = TextEditingController(text: (config?.maxDelayMinutes ?? 60).toString());
    
    if (config != null) {
      _backoffStrategy = config.backoffStrategy;
      _retryOnNetworkError = config.retryOnNetworkError;
      _retryOnServerError = config.retryOnServerError;
      _retryOnTimeout = config.retryOnTimeout;
      _isDefault = config.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxRetriesController.dispose();
    _initialDelayController.dispose();
    _maxDelayController.dispose();
    super.dispose();
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = RetryConfiguration(
        id: widget.existingConfig?.id,
        name: _nameController.text,
        maxRetries: int.parse(_maxRetriesController.text),
        initialDelayMinutes: int.parse(_initialDelayController.text),
        maxDelayMinutes: int.parse(_maxDelayController.text),
        backoffStrategy: _backoffStrategy,
        retryOnNetworkError: _retryOnNetworkError,
        retryOnServerError: _retryOnServerError,
        retryOnTimeout: _retryOnTimeout,
        isDefault: _isDefault,
        createdAt: widget.existingConfig?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _retryService.saveRetryConfiguration(config);

      if (mounted) {
        Navigator.of(context).pop();
        // Show success message in parent dialog
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Error'),
            content: Text('Failed to save configuration: $e'),
            actions: [
              Button(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.existingConfig == null ? 'New Retry Configuration' : 'Edit Retry Configuration'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Configuration name
                InfoLabel(
                  label: 'Configuration Name',
                  child: TextFormBox(
                    controller: _nameController,
                    placeholder: 'Enter configuration name',
                    validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                  ),
                ),
                const SizedBox(height: 16),

                // Max retries and backoff strategy
                Row(
                  children: [
                    Expanded(
                      child: InfoLabel(
                        label: 'Max Retries',
                        child: TextFormBox(
                          controller: _maxRetriesController,
                          placeholder: '3',
                          validator: (value) {
                            final num = int.tryParse(value ?? '');
                            if (num == null || num < 1) return 'Must be a positive number';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Backoff Strategy'),
                          const SizedBox(height: 8),
                          ComboBox<String>(
                            value: _backoffStrategy,
                            items: const [
                              ComboBoxItem(value: 'fixed', child: Text('Fixed')),
                              ComboBoxItem(value: 'linear', child: Text('Linear')),
                              ComboBoxItem(value: 'exponential', child: Text('Exponential')),
                            ],
                            onChanged: (value) => setState(() => _backoffStrategy = value!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Delay settings
                Row(
                  children: [
                    Expanded(
                      child: InfoLabel(
                        label: 'Initial Delay (minutes)',
                        child: TextFormBox(
                          controller: _initialDelayController,
                          placeholder: '5',
                          validator: (value) {
                            final num = int.tryParse(value ?? '');
                            if (num == null || num < 1) return 'Must be a positive number';
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InfoLabel(
                        label: 'Max Delay (minutes)', // Use the label property of InfoLabel
                        child: TextFormBox(
                          controller: _maxDelayController,
                          placeholder: '60',
                          validator: (value) {
                            final num = int.tryParse(value ?? '');
                            if (num == null || num < 1) {
                              return 'Must be a positive number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Retry conditions
                Text(
                  'Retry Conditions',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _retryOnNetworkError,
                  onChanged: (value) => setState(() => _retryOnNetworkError = value!),
                  content: const Text('Network Errors'),
                ),
                Checkbox(
                  checked: _retryOnServerError,
                  onChanged: (value) => setState(() => _retryOnServerError = value!),
                  content: const Text('Server Errors'),
                ),
                Checkbox(
                  checked: _retryOnTimeout,
                  onChanged: (value) => setState(() => _retryOnTimeout = value!),
                  content: const Text('Timeout Errors'),
                ),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value!),
                  content: const Text('Set as Default Configuration'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveConfiguration,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressRing(),
                )
              : Text(widget.existingConfig == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

// Mock statistics class - you should implement this properly in your campaign models
class CampaignStatistics {
  final int totalMessages;
  final int sentMessages;
  final int failedMessages;
  final int pendingMessages;
  final double successRate;
  final RetryStatistics retryStatistics;

  CampaignStatistics({
    required this.totalMessages,
    required this.sentMessages,
    required this.failedMessages,
    required this.pendingMessages,
    required this.successRate,
    required this.retryStatistics,
  });
}
