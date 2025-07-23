import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';
import '../../../clients/logic/client_providers.dart';
import '../../../clients/data/client_model.dart';

class CampaignDuplicationDialog extends ConsumerStatefulWidget {
  final CampaignModel campaign;

  const CampaignDuplicationDialog({
    super.key,
    required this.campaign,
  });

  @override
  ConsumerState<CampaignDuplicationDialog> createState() => _CampaignDuplicationDialogState();
}

class _CampaignDuplicationDialogState extends ConsumerState<CampaignDuplicationDialog> {
  final _nameController = TextEditingController();
  final List<ClientModel> _selectedClients = [];
  bool _useOriginalClients = true;
  bool _scheduleNow = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = '${widget.campaign.name} (Copy)';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duplicationState = ref.watch(campaignDuplicationProvider);
    final clientsAsync = ref.watch(allClientsProvider);

    return ContentDialog(
      title: const Text('Duplicate Campaign'),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original campaign info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(FluentIcons.copy, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Duplicating Campaign',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.campaign.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.campaign.clientIds.length} recipients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // New campaign name
              Text(
                'Campaign Name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormBox(
                controller: _nameController,
                placeholder: 'Enter campaign name...',
              ),

              const SizedBox(height: 20),

              // Recipients selection
              Text(
                'Recipients',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              // Use original clients option
              Checkbox(
                checked: _useOriginalClients,
                onChanged: (value) {
                  setState(() {
                    _useOriginalClients = value ?? true;
                    if (_useOriginalClients) {
                      _selectedClients.clear();
                    }
                  });
                },
                content: Text(
                  'Use original recipients (${widget.campaign.clientIds.length} clients)',
                ),
              ),

              const SizedBox(height: 12),

              // Custom recipients selection
              if (!_useOriginalClients) ...[
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[200]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: clientsAsync.when(
                    data: (clients) => _buildClientsList(clients),
                    loading: () => const Center(child: ProgressRing()),
                    error: (error, _) => Center(child: Text('Error: $error')),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_selectedClients.length} clients selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[100],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Scheduling options
              Text(
                'Scheduling',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              RadioButton(
                checked: _scheduleNow,
                onChanged: (value) => setState(() => _scheduleNow = true),
                content: const Text('Start immediately'),
              ),
              
              const SizedBox(height: 8),
              
              RadioButton(
                checked: !_scheduleNow,
                onChanged: (value) => setState(() => _scheduleNow = false),
                content: const Text('Save as draft'),
              ),

              const SizedBox(height: 20),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FluentIcons.info, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Duplication Summary',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Name', _nameController.text.isNotEmpty 
                        ? _nameController.text 
                        : 'Campaign name required'),
                    _buildSummaryRow('Recipients', _useOriginalClients 
                        ? '${widget.campaign.clientIds.length} (original)'
                        : '${_selectedClients.length} (custom)'),
                    _buildSummaryRow('Status', _scheduleNow ? 'Will start immediately' : 'Saved as draft'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Button(
          onPressed: duplicationState.isLoading 
              ? null 
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: duplicationState.isLoading || !_canDuplicate()
              ? null
              : _duplicate,
          child: duplicationState.isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Duplicating...'),
                  ],
                )
              : const Text('Duplicate Campaign'),
        ),
      ],
    );
  }

  Widget _buildClientsList(List<ClientModel> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final client = clients[index];
        final isSelected = _selectedClients.any((c) => c.id == client.id);

        void handleStateChange(bool? checked) {
          setState(() {
            if (checked == true) {
              _selectedClients.add(client);
            } else {
              _selectedClients.removeWhere((c) => c.id == client.id);
            }
          });
        }

        return ListTile(
          onPressed: () {
            handleStateChange(!isSelected);
          },
          leading: Checkbox(
            checked: isSelected,
            onChanged: handleStateChange,
          ),
          title: Text(client.fullName),
          subtitle: Text(client.email ?? client.phone ?? ''),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[100],
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

  bool _canDuplicate() {
    if (_nameController.text.trim().isEmpty) return false;
    if (!_useOriginalClients && _selectedClients.isEmpty) return false;
    return true;
  }

  void _duplicate() async {
    final clientIds = _useOriginalClients 
        ? widget.campaign.clientIds
        : _selectedClients.map((c) => c.id).toList();

    await ref.read(campaignDuplicationProvider.notifier).duplicateCampaign(
      widget.campaign.id,
      newName: _nameController.text.trim(),
      newClientIds: clientIds,
      newScheduledAt: _scheduleNow ? null : DateTime.now().add(const Duration(days: 1)),
    );

    if (mounted) {
      final state = ref.read(campaignDuplicationProvider);
      if (state.error == null) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      } else {
        _showErrorMessage(state.error!);
      }
    }
  }

  void _showSuccessMessage() {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Campaign Duplicated'),
        content: const Text('The campaign has been duplicated successfully.'),
        severity: InfoBarSeverity.success,
        onClose: close,
      ),
    );
  }

  void _showErrorMessage(String error) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: const Text('Error'),
        content: Text(error),
        severity: InfoBarSeverity.error,
        onClose: close,
      ),
    );
  }
}