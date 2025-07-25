import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_tokens.dart';
import 'navigation_providers.dart';

class CommandPalette extends ConsumerStatefulWidget {
  const CommandPalette({super.key});

  @override
  ConsumerState<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(commandPaletteProvider.notifier).updateQuery(_searchController.text);
    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paletteState = ref.watch(commandPaletteProvider);
    
    if (!paletteState.isVisible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ref.read(commandPaletteProvider.notifier).hide(),
      child: Container(
        color: DesignTokens.withOpacity(Colors.grey, 0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when clicking on palette
            child: Container(
              width: 600,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: BoxDecoration(
                color: DesignTokens.surfacePrimary,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLarge),
                boxShadow: DesignTokens.shadowHigh,
                border: Border.all(
                  color: DesignTokens.borderPrimary,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchHeader(),
                  if (paletteState.filteredItems.isNotEmpty) ...[
                    const Divider(style: DividerThemeData(
                      decoration: BoxDecoration(
                        color: DesignTokens.borderPrimary,
                      ),
                    )),
                    _buildResultsList(paletteState.filteredItems),
                  ] else if (paletteState.query.isNotEmpty) ...[
                    _buildEmptyState(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.space2),
            decoration: BoxDecoration(
              color: DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            ),
            child: Icon(
              FluentIcons.lightning_bolt,
              size: DesignTokens.iconSizeMedium,
              color: DesignTokens.accentPrimary,
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Focus(
              autofocus: true,
              child: TextFormBox(
                controller: _searchController,
                focusNode: _searchFocusNode,
                placeholder: 'Type a command or search...',
                style: DesignTextStyles.bodyLarge,
                decoration: null, // TODO verefy this
                onFieldSubmitted: (_) => _executeSelectedCommand(),
              ),
            ),
          ),
          SizedBox(width: DesignTokens.space3),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space2,
              vertical: DesignTokens.space1,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.surfaceSecondary,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
              border: Border.all(color: DesignTokens.borderPrimary),
            ),
            child: Text(
              'ESC',
              style: DesignTextStyles.caption.copyWith(
                color: DesignTokens.textTertiary,
                fontWeight: DesignTokens.fontWeightMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<CommandPaletteItem> items) {
    return Flexible(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = index == _selectedIndex;
          
          return HoverButton(
            onPressed: () => _executeCommand(item),
            builder: (context, states) {
              final isHovered = states.contains(WidgetState.hovered);
              
              return Container(
                padding: const EdgeInsets.all(DesignTokens.space4),
                decoration: BoxDecoration(
                  color: isSelected || isHovered
                      ? DesignTokens.withOpacity(DesignTokens.accentPrimary, 0.1)
                      : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? DesignTokens.accentPrimary
                            : DesignTokens.withOpacity(DesignTokens.textTertiary, 0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                      ),
                      child: Icon(
                        item.icon,
                        size: DesignTokens.iconSizeSmall,
                        color: isSelected
                            ? DesignTokens.textInverse
                            : DesignTokens.textTertiary,
                      ),
                    ),
                    SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: DesignTextStyles.body.copyWith(
                              fontWeight: DesignTokens.fontWeightMedium,
                              color: isSelected
                                  ? DesignTokens.accentPrimary
                                  : DesignTokens.textPrimary,
                            ),
                          ),
                          if (item.subtitle != null) ...[
                            SizedBox(height: DesignTokens.space1),
                            Text(
                              item.subtitle!,
                              style: DesignTextStyles.caption.copyWith(
                                color: DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space2,
                          vertical: DesignTokens.space1,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.surfaceSecondary,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                          border: Border.all(color: DesignTokens.borderPrimary),
                        ),
                        child: Text(
                          '↵',
                          style: DesignTextStyles.caption.copyWith(
                            color: DesignTokens.textTertiary,
                            fontWeight: DesignTokens.fontWeightMedium,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space8),
      child: Column(
        children: [
          Icon(
            FluentIcons.search,
            size: 48,
            color: DesignTokens.textTertiary,
          ),
          SizedBox(height: DesignTokens.space4),
          Text(
            'No results found',
            style: DesignTextStyles.subtitle.copyWith(
              color: DesignTokens.textSecondary,
            ),
          ),
          SizedBox(height: DesignTokens.space2),
          Text(
            'Try a different search term',
            style: DesignTextStyles.body.copyWith(
              color: DesignTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _executeSelectedCommand() {
    final paletteState = ref.read(commandPaletteProvider);
    if (paletteState.filteredItems.isNotEmpty && _selectedIndex < paletteState.filteredItems.length) {
      _executeCommand(paletteState.filteredItems[_selectedIndex]);
    }
  }

  void _executeCommand(CommandPaletteItem item) {
    ref.read(commandPaletteProvider.notifier).hide();
    
    // Execute the command based on its type
    switch (item.title) {
      case 'Go to Dashboard':
        context.go('/dashboard');
        break;
      case 'Go to Clients':
        context.go('/clients');
        break;
      case 'Go to Templates':
        context.go('/templates');
        break;
      case 'Go to Campaigns':
        context.go('/campaigns');
        break;
      case 'Add New Client':
        context.go('/clients/add');
        break;
      case 'Create Campaign':
        context.go('/campaigns/create');
        break;
      case 'New Template':
        context.go('/templates/editor');
        break;
      default:
        item.onExecute();
    }
  }
}
