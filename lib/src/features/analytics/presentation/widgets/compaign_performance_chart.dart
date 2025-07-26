import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../data/analytics_models.dart';


class CampaignPerformanceChart extends StatelessWidget {
  final List<CampaignPerformanceData> data;

  const CampaignPerformanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.map((e) => e.messagesDelivered + e.messagesFailed).reduce((a, b) => a > b ? a : b).toDouble() + 10,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dataPoint = data[group.x.toInt()];
              final date = '${dataPoint.date.day}/${dataPoint.date.month}';
              
              if (rodIndex == 0) {
                return BarTooltipItem(
                  '$date\nDelivered: ${dataPoint.messagesDelivered}',
                  const TextStyle(color: Colors.white),
                );
              } else {
                return BarTooltipItem(
                  '$date\nFailed: ${dataPoint.messagesFailed}',
                  const TextStyle(color: Colors.white),
                );
              }
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  final date = data[index].date;
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[60]),
        ),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final dataPoint = entry.value;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataPoint.messagesDelivered.toDouble(),
                color: Colors.green,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: dataPoint.messagesFailed.toDouble(),
                color: Colors.red,
                width: 12,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}