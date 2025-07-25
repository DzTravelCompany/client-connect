import 'package:client_connect/src/features/templates/logic/tempalte_editor_providers.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AutoSaveIndicator extends ConsumerWidget {
  const AutoSaveIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

    if (!editorState.isAutoSaveEnabled) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStatusColors(editorState, theme),
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusBorderColor(editorState, theme),
        ),
        boxShadow: editorState.isAutoSaving
            ? [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (editorState.isAutoSaving) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: ProgressRing(
                strokeWidth: 2,
                value: null, // Indeterminate
              ),
            ),
          ] else ...[
            Icon(
              _getStatusIcon(editorState),
              size: 12,
              color: _getStatusIconColor(editorState, theme),
            ),
          ],
          const SizedBox(width: 6),
          Text(
            editorState.autoSaveStatusText,
            style: TextStyle(
              color: _getStatusTextColor(editorState, theme),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (editorState.autoSaveError != null) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: editorState.autoSaveError!,
              child: Icon(
                FluentIcons.info,
                size: 10,
                color: Colors.red,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Color> _getStatusColors(TemplateEditorState state, FluentThemeData theme) {
    if (state.isAutoSaving) {
      return [
        theme.accentColor.withValues(alpha: 0.15),
        theme.accentColor.withValues(alpha: 0.08),
      ];
    } else if (state.autoSaveError != null) {
      return [
        Colors.red.withValues(alpha: 0.15),
        Colors.red.withValues(alpha: 0.08),
      ];
    } else if (state.lastAutoSaved != null) {
      return [
        const Color(0xFF4CAF50).withValues(alpha: 0.15),
        const Color(0xFF4CAF50).withValues(alpha: 0.08),
      ];
    } else if (state.isDirty) {
      return [
        Colors.orange.withValues(alpha: 0.15),
        Colors.orange.withValues(alpha: 0.08),
      ];
    } else {
      return [
        theme.cardColor.withValues(alpha: 0.8),
        theme.cardColor.withValues(alpha: 0.6),
      ];
    }
  }

  Color _getStatusBorderColor(TemplateEditorState state, FluentThemeData theme) {
    if (state.isAutoSaving) {
      return theme.accentColor.withValues(alpha: 0.3);
    } else if (state.autoSaveError != null) {
      return Colors.red.withValues(alpha: 0.3);
    } else if (state.lastAutoSaved != null) {
      return const Color(0xFF4CAF50).withValues(alpha: 0.3);
    } else if (state.isDirty) {
      return Colors.orange.withValues(alpha: 0.3);
    } else {
      return theme.accentColor.withValues(alpha: 0.15);
    }
  }

  IconData _getStatusIcon(TemplateEditorState state) {
    if (state.autoSaveError != null) {
      return FluentIcons.error;
    } else if (state.lastAutoSaved != null) {
      return FluentIcons.check_mark;
    } else if (state.isDirty) {
      return FluentIcons.edit;
    } else {
      return FluentIcons.save;
    }
  }

  Color _getStatusIconColor(TemplateEditorState state, FluentThemeData theme) {
    if (state.autoSaveError != null) {
      return Colors.red;
    } else if (state.lastAutoSaved != null) {
      return const Color(0xFF4CAF50);
    } else if (state.isDirty) {
      return Colors.orange;
    } else {
      return theme.accentColor;
    }
  }

  Color _getStatusTextColor(TemplateEditorState state, FluentThemeData theme) {
    if (state.isAutoSaving) {
      return theme.accentColor;
    } else if (state.autoSaveError != null) {
      return Colors.red;
    } else if (state.lastAutoSaved != null) {
      return const Color(0xFF4CAF50);
    } else if (state.isDirty) {
      return Colors.orange;
    } else {
      return theme.accentColor;
    }
  }
}

/// A more detailed auto-save status panel for the inspector
class AutoSaveStatusPanel extends ConsumerWidget {
  const AutoSaveStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(templateEditorProvider);
    final theme = FluentTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.cardColor.withValues(alpha: 0.8),
            theme.cardColor.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FluentIcons.save,
                size: 16,
                color: theme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Auto-Save',
                style: theme.typography.bodyStrong?.copyWith(
                  color: theme.accentColor,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              ToggleSwitch(
                checked: editorState.isAutoSaveEnabled,
                onChanged: (value) {
                  ref.read(templateEditorProvider.notifier).toggleAutoSave();
                },
              ),
            ],
          ),
          if (editorState.isAutoSaveEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: theme.typography.caption?.copyWith(
                          color: theme.inactiveColor,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (editorState.isAutoSaving) ...[
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: ProgressRing(
                                strokeWidth: 2,
                                value: null,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ] else ...[
                            Icon(
                              _getStatusIcon(editorState),
                              size: 12,
                              color: _getStatusIconColor(editorState, theme),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            editorState.autoSaveStatusText,
                            style: TextStyle(
                              color: _getStatusTextColor(editorState, theme),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (editorState.autoSaveError != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      FluentIcons.error,
                      size: 12,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        editorState.autoSaveError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Auto-save is disabled. Changes will only be saved manually.',
              style: theme.typography.caption?.copyWith(
                color: theme.inactiveColor,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(TemplateEditorState state) {
    if (state.autoSaveError != null) {
      return FluentIcons.error;
    } else if (state.lastAutoSaved != null) {
      return FluentIcons.check_mark;
    } else if (state.isDirty) {
      return FluentIcons.edit;
    } else {
      return FluentIcons.save;
    }
  }

  Color _getStatusIconColor(TemplateEditorState state, FluentThemeData theme) {
    if (state.autoSaveError != null) {
      return Colors.red;
    } else if (state.lastAutoSaved != null) {
      return const Color(0xFF4CAF50);
    } else if (state.isDirty) {
      return Colors.orange;
    } else {
      return theme.accentColor;
    }
  }

  Color _getStatusTextColor(TemplateEditorState state, FluentThemeData theme) {
    if (state.isAutoSaving) {
      return theme.accentColor;
    } else if (state.autoSaveError != null) {
      return Colors.red;
    } else if (state.lastAutoSaved != null) {
      return const Color(0xFF4CAF50);
    } else if (state.isDirty) {
      return Colors.orange;
    } else {
      return theme.accentColor;
    }
  }
}
