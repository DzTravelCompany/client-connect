import 'package:client_connect/src/core/services/retry_service.dart';
import 'package:client_connect/src/features/campaigns/logic/campaign_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _maxRetriesController = TextEditingController();
  final _initialDelayController = TextEditingController();
  final _maxDelayController = TextEditingController();
  
  String _backoffStrategy = 'exponential';
  bool _retryOnNetworkError = true;
  bool _retryOnServerError = true;
  bool _retryOnTimeout = true;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingConfig != null) {
      _populateFields(widget.existingConfig!);
    } else {
      _setDefaults();
    }
  }

  void _populateFields(RetryConfiguration config) {
    _nameController.text = config.name;
    _maxRetriesController.text = config.maxRetries.toString();
    _initialDelayController.text = config.initialDelayMinutes.toString();
    _maxDelayController.text = config.maxDelayMinutes.toString();
    _backoffStrategy = config.backoffStrategy;
    _retryOnNetworkError = config.retryOnNetworkError;
    _retryOnServerError = config.retryOnServerError;
    _retryOnTimeout = config.retryOnTimeout;
    _isDefault = config.isDefault;
  }

  void _setDefaults() {
    _nameController.text = 'New Configuration';
    _maxRetriesController.text = '3';
    _initialDelayController.text = '5';
    _maxDelayController.text = '60';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _maxRetriesController.dispose();
    _initialDelayController.dispose();
    _maxDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final retryManagementState = ref.watch(retryManagementProvider);

    return ContentDialog(
      title: Text(widget.existingConfig != null ? 'Edit Retry Configuration' : 'New Retry Configuration'),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      ],
                    ),
                  ),

                // Configuration name
                const Text('Configuration Name'),
                const SizedBox(height: 8),
                TextBox(
                  controller: _nameController,
                  placeholder: 'Enter configuration name',
                ),
                const SizedBox(height: 16),

                // Max retries
                const Text('Maximum Retries'),
                const SizedBox(height: 8),
                TextBox(
                  controller: _maxRetriesController,
                  placeholder: 'Enter maximum number of retries',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Initial delay
                const Text('Initial Delay (minutes)'),
                const SizedBox(height: 8),
                TextBox(
                  controller: _initialDelayController,
                  placeholder: 'Enter initial delay in minutes',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Max delay
                const Text('Maximum Delay (minutes)'),
                const SizedBox(height: 8),
                TextBox(
                  controller: _maxDelayController,
                  placeholder: 'Enter maximum delay in minutes',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Backoff strategy
                const Text('Backoff Strategy'),
                const SizedBox(height: 8),
                ComboBox<String>(
                  value: _backoffStrategy,
                  items: const [
                    ComboBoxItem(value: 'fixed', child: Text('Fixed Delay')),
                    ComboBoxItem(value: 'linear', child: Text('Linear Backoff')),
                    ComboBoxItem(value: 'exponential', child: Text('Exponential Backoff')),
                  ],
                  onChanged: (value) => setState(() => _backoffStrategy = value ?? 'exponential'),
                ),
                const SizedBox(height: 16),

                // Retry conditions
                const Text('Retry Conditions'),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _retryOnNetworkError,
                  onChanged: (value) => setState(() => _retryOnNetworkError = value ?? false),
                  content: const Text('Retry on Network Errors'),
                ),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _retryOnServerError,
                  onChanged: (value) => setState(() => _retryOnServerError = value ?? false),
                  content: const Text('Retry on Server Errors'),
                ),
                const SizedBox(height: 8),
                Checkbox(
                  checked: _retryOnTimeout,
                  onChanged: (value) => setState(() => _retryOnTimeout = value ?? false),
                  content: const Text('Retry on Timeout'),
                ),
                const SizedBox(height: 16),

                // Default configuration
                Checkbox(
                  checked: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value ?? false),
                  content: const Text('Set as Default Configuration'),
                ),
                const SizedBox(height: 16),

                // Preview section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[150],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retry Schedule Preview',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._generateRetrySchedulePreview(),
                    ],
                  ),
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
          onPressed: retryManagementState.isLoading ? null : _saveConfiguration,
          child: retryManagementState.isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: ProgressRing(),
                    ),
                    SizedBox(width: 8),
                    Text('Saving...'),
                  ],
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  List<Widget> _generateRetrySchedulePreview() {
    final maxRetries = int.tryParse(_maxRetriesController.text) ?? 3;
    final initialDelay = int.tryParse(_initialDelayController.text) ?? 5;
    final maxDelay = int.tryParse(_maxDelayController.text) ?? 60;

    List<Widget> preview = [];
    int cumulativeDelay = 0;

    for (int i = 0; i < maxRetries; i++) {
      int delay;
      switch (_backoffStrategy) {
        case 'linear':
          delay = initialDelay * (i + 1);
          break;
        case 'exponential':
          delay = (initialDelay * (1 << i)).clamp(initialDelay, maxDelay);
          break;
        case 'fixed':
        default:
          delay = initialDelay;
          break;
      }
      
      delay = delay.clamp(initialDelay, maxDelay);
      cumulativeDelay += delay;

      preview.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Retry ${i + 1}: After ${delay}min (${cumulativeDelay}min total)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[100],
            ),
          ),
        ),
      );
    }

    return preview;
  }

  void _saveConfiguration() {
    if (!_formKey.currentState!.validate()) return;

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

    ref.read(retryManagementProvider.notifier).saveRetryConfiguration(config);
  }
}
