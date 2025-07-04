import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:fluent_ui/fluent_ui.dart';


class DividerBlockWidget extends StatelessWidget {
  final DividerBlock block;

  const DividerBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: block.thickness,
        decoration: BoxDecoration(
          color: _parseColor(block.color),
          borderRadius: BorderRadius.circular(block.thickness / 2),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
