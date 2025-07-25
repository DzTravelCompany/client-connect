import 'package:fluent_ui/fluent_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/analytics_models.dart';

class MessageTypePieChart extends StatelessWidget {
  final List<MessageTypeDistribution> data;

  const MessageTypePieChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final color = _getColorForType(item.type, index);
                
                return PieChartSectionData(
                  color: color,
                  value: item.percentage,
                  title: '${item.percentage.toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: data.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final color = _getColorForType(item.type, index);
            
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${item.type.toUpperCase()} (${item.count})',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getColorForType(String type, int index) {
    switch (type.toLowerCase()) {
      case 'email':
        return Colors.blue;
      case 'whatsapp':
        return Colors.green;
      case 'sms':
        return Colors.orange;
      default:
        final colors = [Colors.purple, Colors.teal, Colors.red, Colors.yellow];
        return colors[index % colors.length];
    }
  }
}
