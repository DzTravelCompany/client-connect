import 'package:fluent_ui/fluent_ui.dart';
import '../../data/analytics_models.dart';

class TopTemplatesList extends StatelessWidget {
  final List<TopPerformingTemplate> templates;

  const TopTemplatesList({super.key, required this.templates});

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No template data available'),
        ),
      );
    }

    return Column(
      children: templates.asMap().entries.map((entry) {
        final index = entry.key;
        final template = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[10],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[40]),
          ),
          child: Row(
            children: [
              // Rank
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _getRankColor(index),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Template info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.templateName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used in ${template.usageCount} campaigns',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Metrics
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${template.successRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(template.successRate),
                    ),
                  ),
                  Text(
                    '${template.totalMessages} messages',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[100],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 12),
              
              // Success rate bar
              Container(
                width: 60,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey[40],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: template.successRate / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getSuccessRateColor(template.successRate),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.yellow; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.blue;
    }
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }
}
