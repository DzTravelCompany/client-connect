import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text('Client Connect CRM'),
        automaticallyImplyLeading: false,
      ),
      pane: NavigationPane(
        selected: selectedIndex,
        onChanged: (index) {
          setState(() => selectedIndex = index);
          switch (index) {
            case 0:
              context.go('/clients');
              break;
            case 1:
              context.go('/templates');
              break;
            case 2:
              context.go('/campaigns');
              break;
            case 3:
              context.go('/settings');
              break;
            case 4:
              context.go('/analytics');
              break;
            case 5:
              context.go('/tags');
              break;
          }
        },
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.people),
            title: const Text('Clients'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.mail),
            title: const Text('Templates'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.send),
            title: const Text('Campaigns'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.chart),
            title: const Text('Analytics'),
            body: const SizedBox.shrink(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.tag),
            title: const Text('Tags'),
            body: const SizedBox.shrink(),
          ),
        ],
      ),
      paneBodyBuilder: (item, child) {
        // Insert the ShellRoute child into the view:
        return widget.child;
      },
    );
  }
}