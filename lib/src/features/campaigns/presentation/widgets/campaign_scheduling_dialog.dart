import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showDatePicker, showTimePicker, TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/campaigns_model.dart';
import '../../logic/campaign_providers.dart';

class CampaignSchedulingDialog extends ConsumerStatefulWidget {
  final CampaignModel campaign;

  const CampaignSchedulingDialog({
    super.key,
    required this.campaign,
  });

  @override
  ConsumerState<CampaignSchedulingDialog> createState() => _CampaignSchedulingDialogState();
}

class _CampaignSchedulingDialogState extends ConsumerState<CampaignSchedulingDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isReschedule = false;

  @override
  void initState() {
    super.initState();
    _isReschedule = widget.campaign.isScheduled;
    if (_isReschedule && widget.campaign.scheduledAt != null) {
      _selectedDate = widget.campaign.scheduledAt;
      _selectedTime = TimeOfDay.fromDateTime(widget.campaign.scheduledAt!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulingState = ref.watch(campaignSchedulingProvider);

    return ContentDialog(
      title: Text(_isReschedule ? 'Reschedule Campaign' : 'Schedule Campaign'),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campaign.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.campaign.clientIds.length} recipients',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                  if (_isReschedule && widget.campaign.scheduledAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Currently scheduled: ${_formatDateTime(widget.campaign.scheduledAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Date selection
            Text(
              'Select Date',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: _selectDate,
                child: Row(
                  children: [
                    const Icon(FluentIcons.calendar, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                          : 'Choose date',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time selection
            Text(
              'Select Time',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: Button(
                onPressed: _selectTime,
                child: Row(
                  children: [
                    const Icon(FluentIcons.clock, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'Choose time',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Preview
            if (_selectedDate != null && _selectedTime != null) ...[
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
                          'Scheduled Time',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatScheduledDateTime(),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getTimeUntilScheduled(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Unschedule option for rescheduling
            if (_isReschedule) ...[
              const Divider(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Button(
                  onPressed: schedulingState.isLoading ? null : _unschedule,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(FluentIcons.cancel, size: 16),
                      SizedBox(width: 8),
                      Text('Remove Schedule (Send Now)'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        Button(
          onPressed: schedulingState.isLoading 
              ? null 
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: schedulingState.isLoading || !_canSchedule()
              ? null
              : _schedule,
          child: schedulingState.isLoading
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressRing(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Scheduling...'),
                  ],
                )
              : Text(_isReschedule ? 'Reschedule' : 'Schedule'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null && mounted) {
      setState(() => _selectedTime = time);
    }
  }

  bool _canSchedule() {
    if (_selectedDate == null || _selectedTime == null) return false;
    
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    return scheduledDateTime.isAfter(DateTime.now());
  }

  String _formatScheduledDateTime() {
    if (_selectedDate == null || _selectedTime == null) return '';
    
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    return DateFormat('EEEE, dd MMMM yyyy \'at\' HH:mm').format(scheduledDateTime);
  }

  String _getTimeUntilScheduled() {
    if (_selectedDate == null || _selectedTime == null) return '';
    
    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final difference = scheduledDateTime.difference(DateTime.now());
    
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} days';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hours';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} minutes';
    } else {
      return 'Scheduled time has passed';
    }
  }

  void _schedule() async {
    if (!_canSchedule()) return;

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await ref.read(campaignSchedulingProvider.notifier)
        .scheduleCampaign(widget.campaign.id, scheduledDateTime);

    if (mounted) {
      final state = ref.read(campaignSchedulingProvider);
      if (state.error == null) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      } else {
        _showErrorMessage(state.error!);
      }
    }
  }

  void _unschedule() async {
    await ref.read(campaignSchedulingProvider.notifier)
        .unschedule(widget.campaign.id);

    if (mounted) {
      final state = ref.read(campaignSchedulingProvider);
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
        title: Text(_isReschedule ? 'Campaign Rescheduled' : 'Campaign Scheduled'),
        content: Text(
          _isReschedule 
              ? 'The campaign has been rescheduled successfully.'
              : 'The campaign has been scheduled successfully.',
        ),
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
