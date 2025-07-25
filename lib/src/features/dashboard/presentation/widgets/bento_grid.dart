import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class BentoGrid extends StatelessWidget {
  final List<BentoCard> children;
  final EdgeInsets padding;

  const BentoGrid({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: StaggeredGrid.count(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: children,
      ),
    );
  }
}

class BentoCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const BentoCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.resources.dividerStrokeColorDefault.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
