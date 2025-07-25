import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'navigation_context.dart';
import 'navigation_providers.dart';

class KeyboardShortcutsHandler extends ConsumerWidget {
  final Widget child;

  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: _buildShortcuts(),
      child: Actions(
        actions: _buildActions(context, ref),
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }

  Map<ShortcutActivator, Intent> _buildShortcuts() {
    return {
      // Command palette
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): const ShowCommandPaletteIntent(),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): const ShowCommandPaletteIntent(),
      
      // Quick navigation (Ctrl/Cmd + 1-9)
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): const NavigateToContextIntent(NavigationContext.dashboard),
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true): const NavigateToContextIntent(NavigationContext.dashboard),
      
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): const NavigateToContextIntent(NavigationContext.clients),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true): const NavigateToContextIntent(NavigationContext.clients),
      
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): const NavigateToContextIntent(NavigationContext.templates),
      const SingleActivator(LogicalKeyboardKey.digit3, meta: true): const NavigateToContextIntent(NavigationContext.templates),
      
      const SingleActivator(LogicalKeyboardKey.digit4, control: true): const NavigateToContextIntent(NavigationContext.campaigns),
      const SingleActivator(LogicalKeyboardKey.digit4, meta: true): const NavigateToContextIntent(NavigationContext.campaigns),
      
      const SingleActivator(LogicalKeyboardKey.digit5, control: true): const NavigateToContextIntent(NavigationContext.analytics),
      const SingleActivator(LogicalKeyboardKey.digit5, meta: true): const NavigateToContextIntent(NavigationContext.analytics),
      
      // Quick actions
      const SingleActivator(LogicalKeyboardKey.keyN, control: true): const QuickCreateIntent(),
      const SingleActivator(LogicalKeyboardKey.keyN, meta: true): const QuickCreateIntent(),
      
      // Help
      const SingleActivator(LogicalKeyboardKey.slash, control: true): const ShowHelpIntent(),
      const SingleActivator(LogicalKeyboardKey.slash, meta: true): const ShowHelpIntent(),
    };
  }

  Map<Type, Action<Intent>> _buildActions(BuildContext context, WidgetRef ref) {
    return {
      ShowCommandPaletteIntent: CallbackAction<ShowCommandPaletteIntent>(
        onInvoke: (intent) {
          ref.read(commandPaletteProvider.notifier).show();
          return null;
        },
      ),
      
      NavigateToContextIntent: CallbackAction<NavigateToContextIntent>(
        onInvoke: (intent) {
          ref.read(navigationStateProvider.notifier).navigateToContext(intent.context);
          context.go(intent.context.route);
          return null;
        },
      ),
      
      QuickCreateIntent: CallbackAction<QuickCreateIntent>(
        onInvoke: (intent) {
          _showQuickCreateDialog(context, ref);
          return null;
        },
      ),
      
      ShowHelpIntent: CallbackAction<ShowHelpIntent>(
        onInvoke: (intent) {
          _showKeyboardShortcutsDialog(context);
          return null;
        },
      ),
    };
  }

  void _showQuickCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Quick Create'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(FluentIcons.add_friend),
              title: const Text('New Client'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/clients/add');
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.send),
              title: const Text('New Campaign'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/campaigns/create');
              },
            ),
            ListTile(
              leading: const Icon(FluentIcons.page_add),
              title: const Text('New Template'),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/templates/editor');
              },
            ),
          ],
        ),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcutsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Keyboard Shortcuts'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutItem('Ctrl/Cmd + K', 'Open command palette'),
              _buildShortcutItem('Ctrl/Cmd + 1-5', 'Quick navigation'),
              _buildShortcutItem('Ctrl/Cmd + N', 'Quick create'),
              _buildShortcutItem('Ctrl/Cmd + /', 'Show this help'),
              _buildShortcutItem('Esc', 'Close dialogs/panels'),
            ],
          ),
        ),
        actions: [
          Button(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}

// Intent classes
class ShowCommandPaletteIntent extends Intent {
  const ShowCommandPaletteIntent();
}

class NavigateToContextIntent extends Intent {
  final NavigationContext context;
  const NavigateToContextIntent(this.context);
}

class QuickCreateIntent extends Intent {
  const QuickCreateIntent();
}

class ShowHelpIntent extends Intent {
  const ShowHelpIntent();
}
