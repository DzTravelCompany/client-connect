import 'package:client_connect/src/features/templates/data/template_block_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class TemplateEditorState {
  final List<TemplateBlock> blocks;
  final String? selectedBlockId;
  final List<List<TemplateBlock>> history;
  final int historyIndex;
  final bool isDirty;
  final TemplateType templateType;
  final String templateName;
  final String templateSubject;
  final bool isLoading;
  final String? error;
  final DateTime? createdAt;
  final bool isPreviewMode;
  final Map<String, String> previewData;

  const TemplateEditorState({
    this.blocks = const [],
    this.selectedBlockId,
    this.history = const [],
    this.historyIndex = -1,
    this.isDirty = false,
    this.templateType = TemplateType.email,
    this.templateName = '',
    this.templateSubject = '',
    this.isLoading = false,
    this.error,
    this.createdAt,
    this.isPreviewMode = false,
    this.previewData = const {},
  });

  TemplateEditorState copyWith({
    List<TemplateBlock>? blocks,
    String? selectedBlockId,
    List<List<TemplateBlock>>? history,
    int? historyIndex,
    bool? isDirty,
    TemplateType? templateType,
    String? templateName,
    String? templateSubject,
    bool? isLoading,
    String? error,
    DateTime? createdAt,
    bool? isPreviewMode,
    Map<String, String>? previewData,
  }) {
    return TemplateEditorState(
      blocks: blocks ?? this.blocks,
      selectedBlockId: selectedBlockId ?? this.selectedBlockId,
      history: history ?? this.history,
      historyIndex: historyIndex ?? this.historyIndex,
      isDirty: isDirty ?? this.isDirty,
      templateType: templateType ?? this.templateType,
      templateName: templateName ?? this.templateName,
      templateSubject: templateSubject ?? this.templateSubject,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      createdAt: createdAt ?? this.createdAt,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      previewData: previewData ?? this.previewData,
    );
  }

  bool get canUndo => historyIndex > 0;
  bool get canRedo => historyIndex < history.length - 1;

  TemplateBlock? get selectedBlock {
    if (selectedBlockId == null) return null;
    try {
      return blocks.firstWhere((block) => block.id == selectedBlockId);
    } catch (e) {
      return null;
    }
  }

  List<TemplateBlockType> get availableBlockTypes {
    return TemplateBlockType.values
        .where((type) => _createDummyBlock(type).isCompatibleWith(templateType))
        .toList();
  }

  // Get all placeholders used in the template
  Set<String> get usedPlaceholders {
    return PlaceholderManager.extractPlaceholdersFromBlocks(blocks);
  }

  TemplateBlock _createDummyBlock(TemplateBlockType type) {
    const uuid = Uuid();
    switch (type) {
      case TemplateBlockType.text:
        return TextBlock(id: uuid.v4());
      case TemplateBlockType.richText:
        return RichTextBlock(id: uuid.v4());
      case TemplateBlockType.image:
        return ImageBlock(id: uuid.v4());
      case TemplateBlockType.button:
        return ButtonBlock(id: uuid.v4());
      case TemplateBlockType.spacer:
        return SpacerBlock(id: uuid.v4());
      case TemplateBlockType.divider:
        return DividerBlock(id: uuid.v4());
      case TemplateBlockType.list:
        return ListBlock(id: uuid.v4());
      case TemplateBlockType.table:
        return TableBlock(id: uuid.v4());
      case TemplateBlockType.social:
        return SocialBlock(id: uuid.v4());
      case TemplateBlockType.qrCode:
        return QRCodeBlock(id: uuid.v4());
      case TemplateBlockType.countdown:
        return CountdownBlock(id: uuid.v4());
      case TemplateBlockType.rating:
        return RatingBlock(id: uuid.v4());
      case TemplateBlockType.progress:
        return ProgressBlock(id: uuid.v4());
    }
  }
}

class TemplateEditorNotifier extends StateNotifier<TemplateEditorState> {
  static const _uuid = Uuid();

  TemplateEditorNotifier() : super(const TemplateEditorState()) {
    _addToHistory([]);
    // Initialize with sample data
    state = state.copyWith(previewData: PlaceholderManager.getAllSampleData());
  }

  void _addToHistory(List<TemplateBlock> blocks) {
    final newHistory = state.history.take(state.historyIndex + 1).toList();
    newHistory.add(List.from(blocks));
    
    // Limit history to 50 entries
    if (newHistory.length > 50) {
      newHistory.removeAt(0);
    }
    
    state = state.copyWith(
      history: newHistory,
      historyIndex: newHistory.length - 1,
    );
  }

  void setTemplateType(TemplateType type) {
    if (state.templateType == type) return;
    
    // Filter out incompatible blocks when switching template types
    final compatibleBlocks = state.blocks
        .where((block) => block.isCompatibleWith(type))
        .toList();
    
    _addToHistory(compatibleBlocks);
    state = state.copyWith(
      templateType: type,
      blocks: compatibleBlocks,
      selectedBlockId: compatibleBlocks.any((b) => b.id == state.selectedBlockId) 
          ? state.selectedBlockId 
          : null,
      isDirty: true,
    );
  }

  void setTemplateInfo({String? name, String? subject}) {
    state = state.copyWith(
      templateName: name ?? state.templateName,
      templateSubject: subject ?? state.templateSubject,
      isDirty: true,
    );
  }

  void addBlock(TemplateBlock block, {int? index}) {
    final newBlocks = [...state.blocks];
    if (index != null && index >= 0 && index <= newBlocks.length) {
      newBlocks.insert(index, block);
    } else {
      newBlocks.add(block);
    }
    
    // Update sort orders
    for (int i = 0; i < newBlocks.length; i++) {
      newBlocks[i] = newBlocks[i].copyWith(sortOrder: i);
    }
    
    _addToHistory(newBlocks);
    state = state.copyWith(
      blocks: newBlocks,
      selectedBlockId: block.id,
      isDirty: true,
    );
  }

  void removeBlock(String blockId) {
    final newBlocks = state.blocks.where((block) => block.id != blockId).toList();
    
    // Update sort orders
    for (int i = 0; i < newBlocks.length; i++) {
      newBlocks[i] = newBlocks[i].copyWith(sortOrder: i);
    }
    
    _addToHistory(newBlocks);
    state = state.copyWith(
      blocks: newBlocks,
      selectedBlockId: state.selectedBlockId == blockId ? null : state.selectedBlockId,
      isDirty: true,
    );
  }

  void updateBlock(String blockId, Map<String, dynamic> properties) {
    final blockIndex = state.blocks.indexWhere((block) => block.id == blockId);
    if (blockIndex == -1) return;

    final updatedBlock = state.blocks[blockIndex].copyWith(properties: properties);
    final newBlocks = [...state.blocks];
    newBlocks[blockIndex] = updatedBlock;
    
    _addToHistory(newBlocks);
    state = state.copyWith(
      blocks: newBlocks,
      isDirty: true,
    );
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    final newBlocks = [...state.blocks];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = newBlocks.removeAt(oldIndex);
    newBlocks.insert(newIndex, item);
    
    // Update sort orders
    for (int i = 0; i < newBlocks.length; i++) {
      newBlocks[i] = newBlocks[i].copyWith(sortOrder: i);
    }
    
    _addToHistory(newBlocks);
    state = state.copyWith(
      blocks: newBlocks,
      isDirty: true,
    );
  }

  void moveBlock(String blockId, int targetIndex) {
    final currentIndex = state.blocks.indexWhere((block) => block.id == blockId);
    if (currentIndex == -1 || currentIndex == targetIndex) return;
    
    reorderBlocks(currentIndex, targetIndex);
  }

  void selectBlock(String? blockId) {
    state = state.copyWith(selectedBlockId: blockId);
  }

  void duplicateBlock(String blockId) {
    final blockIndex = state.blocks.indexWhere((block) => block.id == blockId);
    if (blockIndex == -1) return;

    final originalBlock = state.blocks[blockIndex];
    final duplicatedBlock = _duplicateBlock(originalBlock);
    
    addBlock(duplicatedBlock, index: blockIndex + 1);
  }

  // Insert placeholder into selected text block
  void insertPlaceholder(String placeholderKey) {
    if (state.selectedBlockId == null) return;
    
    final selectedBlock = state.selectedBlock;
    if (selectedBlock is TextBlock) {
      final currentText = selectedBlock.text;
      final placeholder = '{{$placeholderKey}}';
      final newText = currentText.isEmpty ? placeholder : '$currentText $placeholder';
      
      updateBlock(selectedBlock.id, {'text': newText});
    } else if (selectedBlock is RichTextBlock) {
      final currentContent = selectedBlock.htmlContent;
      final placeholder = '{{$placeholderKey}}';
      final newContent = currentContent.isEmpty ? placeholder : '$currentContent $placeholder';
      
      updateBlock(selectedBlock.id, {'htmlContent': newContent});
    }
  }

  // Toggle preview mode
  void togglePreviewMode() {
    state = state.copyWith(isPreviewMode: !state.isPreviewMode);
  }

  // Update preview data
  void updatePreviewData(Map<String, String> data) {
    state = state.copyWith(previewData: data);
  }

  TemplateBlock _duplicateBlock(TemplateBlock original) {
    final newId = _uuid.v4();
    switch (original.type) {
      case TemplateBlockType.text:
        final textBlock = original as TextBlock;
        return textBlock.copyWith(properties: {'text': '${textBlock.text} (Copy)'});
      case TemplateBlockType.richText:
        final richTextBlock = original as RichTextBlock;
        return RichTextBlock(
          id: newId,
          htmlContent: richTextBlock.htmlContent,
          fontSize: richTextBlock.fontSize,
          fontFamily: richTextBlock.fontFamily,
          lineHeight: richTextBlock.lineHeight,
        );
      case TemplateBlockType.image:
        final imageBlock = original as ImageBlock;
        return ImageBlock(
          id: newId,
          imageUrl: imageBlock.imageUrl,
          altText: imageBlock.altText,
          width: imageBlock.width,
          height: imageBlock.height,
          fit: imageBlock.fit,
          alignment: imageBlock.alignment,
          borderRadius: imageBlock.borderRadius,
          borderColor: imageBlock.borderColor,
          borderWidth: imageBlock.borderWidth,
          isResponsive: imageBlock.isResponsive,
        );
      case TemplateBlockType.button:
        final buttonBlock = original as ButtonBlock;
        return ButtonBlock(
          id: newId,
          text: buttonBlock.text,
          backgroundColor: buttonBlock.backgroundColor,
          textColor: buttonBlock.textColor,
          action: buttonBlock.action,
          actionType: buttonBlock.actionType,
          borderRadius: buttonBlock.borderRadius,
          borderColor: buttonBlock.borderColor,
          borderWidth: buttonBlock.borderWidth,
          size: buttonBlock.size,
          alignment: buttonBlock.alignment,
          fullWidth: buttonBlock.fullWidth,
          hoverColor: buttonBlock.hoverColor,
        );
      default:
        // For other block types, create a basic copy
        return TemplateBlock.fromJson({
          ...original.toJson(),
          'id': newId,
        });
    }
  }

  void undo() {
    if (!state.canUndo) return;
    
    final newIndex = state.historyIndex - 1;
    state = state.copyWith(
      blocks: List.from(state.history[newIndex]),
      historyIndex: newIndex,
      isDirty: true,
    );
  }

  void redo() {
    if (!state.canRedo) return;
    
    final newIndex = state.historyIndex + 1;
    state = state.copyWith(
      blocks: List.from(state.history[newIndex]),
      historyIndex: newIndex,
      isDirty: true,
    );
  }

  void loadTemplate({
    required List<TemplateBlock> blocks,
    required TemplateType templateType,
    String? templateName,
    String? templateSubject,
  }) {
    _addToHistory(blocks);
    state = state.copyWith(
      blocks: blocks,
      templateType: templateType,
      templateName: templateName ?? '',
      templateSubject: templateSubject ?? '',
      selectedBlockId: null,
      isDirty: false,
      isLoading: false,
      error: null,
    );
  }

  void clearTemplate() {
    _addToHistory([]);
    state = state.copyWith(
      blocks: [],
      selectedBlockId: null,
      templateName: '',
      templateSubject: '',
      isDirty: false,
    );
  }

  void markSaved() {
    state = state.copyWith(isDirty: false);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  // Factory methods for creating blocks
  TemplateBlock createTextBlock() => TextBlock(id: _uuid.v4());
  TemplateBlock createRichTextBlock() => RichTextBlock(id: _uuid.v4());
  TemplateBlock createImageBlock() => ImageBlock(id: _uuid.v4());
  TemplateBlock createButtonBlock() => ButtonBlock(id: _uuid.v4());
  TemplateBlock createSpacerBlock() => SpacerBlock(id: _uuid.v4());
  TemplateBlock createDividerBlock() => DividerBlock(id: _uuid.v4());
  TemplateBlock createListBlock() => ListBlock(id: _uuid.v4());
  TemplateBlock createQRCodeBlock() => QRCodeBlock(id: _uuid.v4());
  TemplateBlock createSocialBlock() => SocialBlock(id: _uuid.v4());
}

final templateEditorProvider = StateNotifierProvider<TemplateEditorNotifier, TemplateEditorState>(
  (ref) => TemplateEditorNotifier(),
);

// Provider for drag and drop state
final dragDropStateProvider = StateProvider<DragDropState>((ref) => const DragDropState());

class DragDropState {
  final bool isDragging;
  final String? draggedBlockId;
  final TemplateBlockType? draggedBlockType;
  final int? dropTargetIndex;

  const DragDropState({
    this.isDragging = false,
    this.draggedBlockId,
    this.draggedBlockType,
    this.dropTargetIndex,
  });

  DragDropState copyWith({
    bool? isDragging,
    String? draggedBlockId,
    TemplateBlockType? draggedBlockType,
    int? dropTargetIndex,
  }) {
    return DragDropState(
      isDragging: isDragging ?? this.isDragging,
      draggedBlockId: draggedBlockId ?? this.draggedBlockId,
      draggedBlockType: draggedBlockType ?? this.draggedBlockType,
      dropTargetIndex: dropTargetIndex ?? this.dropTargetIndex,
    );
  }
}
