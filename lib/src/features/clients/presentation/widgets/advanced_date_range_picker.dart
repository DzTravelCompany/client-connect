import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show showDatePicker;

class AdvancedDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange?) onRangeChanged;

  const AdvancedDateRangePicker({
    super.key,
    this.initialRange,
    required this.onRangeChanged,
  });

  @override
  State<AdvancedDateRangePicker> createState() => _AdvancedDateRangePickerState();
}

class _AdvancedDateRangePickerState extends State<AdvancedDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPreset = '';

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialRange?.start;
    _endDate = widget.initialRange?.end;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);

    return ContentDialog(
      title: const Text('Select Date Range'),
      content: SizedBox(
        width: 400,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick presets
            Text(
              'Quick Select',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton('Last 7 days', 7),
                _buildPresetButton('Last 30 days', 30),
                _buildPresetButton('Last 90 days', 90),
                _buildPresetButton('This year', 365),
              ],
            ),
            const SizedBox(height: 20),
            
            // Custom date selection
            Text(
              'Custom Range',
              style: theme.typography.bodyStrong,
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Date',
                        style: theme.typography.body,
                      ),
                      const SizedBox(height: 4),
                      Button(
                        onPressed: () => _selectStartDate(),
                        child: Text(
                          _startDate != null
                              ? _formatDate(_startDate!)
                              : 'Select start date',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Date',
                        style: theme.typography.body,
                      ),
                      const SizedBox(height: 4),
                      Button(
                        onPressed: () => _selectEndDate(),
                        child: Text(
                          _endDate != null
                              ? _formatDate(_endDate!)
                              : 'Select end date',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Selected range display
            if (_startDate != null && _endDate != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.resources.cardBackgroundFillColorSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.calendar,
                      size: 16,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        Button(
          child: const Text('Clear'),
          onPressed: () {
            widget.onRangeChanged(null);
            Navigator.of(context).pop();
          },
        ),
        Button(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          onPressed: _startDate != null && _endDate != null
              ? () {
                  widget.onRangeChanged(
                    DateTimeRange(start: _startDate!, end: _endDate!),
                  );
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPresetButton(String label, int days) {
    final isSelected = _selectedPreset == label;
    final theme = FluentTheme.of(context);

    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          isSelected 
              ? theme.accentColor.withValues(alpha: 0.1)
              : null,
        ),
        foregroundColor: WidgetStateProperty.all(
          isSelected 
              ? theme.accentColor
              : null,
        ),
      ),
      onPressed: () => _selectPreset(label, days),
      child: Text(label),
    );
  }

  void _selectPreset(String preset, int days) {
    setState(() {
      _selectedPreset = preset;
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(Duration(days: days));
    });
  }

  void _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _startDate = date;
        _selectedPreset = '';
      });
    }
  }

  void _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      setState(() {
        _endDate = date;
        _selectedPreset = '';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
