class TextSegment {
  final String text;
  final TextFormatting formatting;

  const TextSegment({
    required this.text,
    this.formatting = const TextFormatting(),
  });

  TextSegment copyWith({
    String? text,
    TextFormatting? formatting,
  }) {
    return TextSegment(
      text: text ?? this.text,
      formatting: formatting ?? this.formatting,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'formatting': formatting.toJson(),
  };

  static TextSegment fromJson(Map<String, dynamic> json) => TextSegment(
    text: json['text'] ?? '',
    formatting: TextFormatting.fromJson(json['formatting'] ?? {}),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextSegment &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          formatting == other.formatting;

  @override
  int get hashCode => text.hashCode ^ formatting.hashCode;
}

/// Represents formatting properties for text
class TextFormatting {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final double? fontSize;
  final String? fontFamily;
  final String? color;
  final String? backgroundColor;

  const TextFormatting({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.fontSize,
    this.fontFamily,
    this.color,
    this.backgroundColor,
  });

  TextFormatting copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSize,
    String? fontFamily,
    String? color,
    String? backgroundColor,
  }) {
    return TextFormatting(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikethrough': strikethrough,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
    'color': color,
    'backgroundColor': backgroundColor,
  };

  static TextFormatting fromJson(Map<String, dynamic> json) => TextFormatting(
    bold: json['bold'] ?? false,
    italic: json['italic'] ?? false,
    underline: json['underline'] ?? false,
    strikethrough: json['strikethrough'] ?? false,
    fontSize: json['fontSize']?.toDouble(),
    fontFamily: json['fontFamily'],
    color: json['color'],
    backgroundColor: json['backgroundColor'],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextFormatting &&
          runtimeType == other.runtimeType &&
          bold == other.bold &&
          italic == other.italic &&
          underline == other.underline &&
          strikethrough == other.strikethrough &&
          fontSize == other.fontSize &&
          fontFamily == other.fontFamily &&
          color == other.color &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
    bold,
    italic,
    underline,
    strikethrough,
    fontSize,
    fontFamily,
    color,
    backgroundColor,
  );
}

/// Represents rich text content as a list of formatted segments
class RichTextContent {
  final List<TextSegment> segments;

  const RichTextContent({this.segments = const []});

  /// Convert to plain text
  String get plainText => segments.map((s) => s.text).join();

  /// Check if content is empty
  bool get isEmpty => segments.isEmpty || plainText.trim().isEmpty;

  /// Get length of all text
  int get length => plainText.length;

  /// Create from plain text
  static RichTextContent fromPlainText(String text) {
    if (text.isEmpty) return const RichTextContent();
    return RichTextContent(segments: [
      TextSegment(text: text, formatting: const TextFormatting())
    ]);
  }

  /// Apply formatting to a specific range
  RichTextContent applyFormatting(int start, int end, TextFormatting formatting) {
    if (start >= end || start < 0 || end > length) return this;

    final newSegments = <TextSegment>[];
    int currentPos = 0;

    for (final segment in segments) {
      final segmentStart = currentPos;
      final segmentEnd = currentPos + segment.text.length;

      if (segmentEnd <= start || segmentStart >= end) {
        // Segment is outside the range, keep as is
        newSegments.add(segment);
      } else if (segmentStart >= start && segmentEnd <= end) {
        // Segment is completely within the range, apply formatting
        newSegments.add(segment.copyWith(formatting: formatting));
      } else {
        // Segment is partially within the range, split it
        final beforeText = segment.text.substring(0, (start - segmentStart).clamp(0, segment.text.length));
        final withinText = segment.text.substring(
          (start - segmentStart).clamp(0, segment.text.length),
          (end - segmentStart).clamp(0, segment.text.length),
        );
        final afterText = segment.text.substring((end - segmentStart).clamp(0, segment.text.length));

        if (beforeText.isNotEmpty) {
          newSegments.add(TextSegment(text: beforeText, formatting: segment.formatting));
        }
        if (withinText.isNotEmpty) {
          newSegments.add(TextSegment(text: withinText, formatting: formatting));
        }
        if (afterText.isNotEmpty) {
          newSegments.add(TextSegment(text: afterText, formatting: segment.formatting));
        }
      }

      currentPos = segmentEnd;
    }

    return RichTextContent(segments: _mergeAdjacentSegments(newSegments));
  }

  /// Insert text at a specific position
  RichTextContent insertText(int position, String text, TextFormatting formatting) {
    if (text.isEmpty) return this;
    if (position < 0 || position > length) return this;

    final newSegments = <TextSegment>[];
    int currentPos = 0;
    bool inserted = false;

    for (final segment in segments) {
      final segmentStart = currentPos;
      final segmentEnd = currentPos + segment.text.length;

      if (position <= segmentStart && !inserted) {
        // Insert before this segment
        newSegments.add(TextSegment(
          text: text,
          formatting: formatting,
        ));
        newSegments.add(segment);
        inserted = true;
      } else if (position > segmentStart && position < segmentEnd) {
        // Insert within this segment
        final beforeText = segment.text.substring(0, position - segmentStart);
        final afterText = segment.text.substring(position - segmentStart);

        if (beforeText.isNotEmpty) {
          newSegments.add(TextSegment(text: beforeText, formatting: segment.formatting));
        }
        newSegments.add(TextSegment(
          text: text,
          formatting: formatting,
        ));
        if (afterText.isNotEmpty) {
          newSegments.add(TextSegment(text: afterText, formatting: segment.formatting));
        }
        inserted = true;
      } else {
        newSegments.add(segment);
      }

      currentPos = segmentEnd;
    }

    if (!inserted) {
      // Insert at the end
      newSegments.add(TextSegment(
        text: text,
        formatting: formatting,
      ));
    }

    return RichTextContent(segments: _mergeAdjacentSegments(newSegments));
  }

  /// Delete text in a specific range
  RichTextContent deleteText(int start, int end) {
    if (start >= end || start < 0 || end > length) return this;

    final newSegments = <TextSegment>[];
    int currentPos = 0;

    for (final segment in segments) {
      final segmentStart = currentPos;
      final segmentEnd = currentPos + segment.text.length;

      if (segmentEnd <= start || segmentStart >= end) {
        // Segment is outside the deletion range
        newSegments.add(segment);
      } else if (segmentStart >= start && segmentEnd <= end) {
        // Segment is completely within the deletion range, skip it
        continue;
      } else {
        // Segment is partially within the deletion range
        final beforeText = segment.text.substring(0, (start - segmentStart).clamp(0, segment.text.length));
        final afterText = segment.text.substring((end - segmentStart).clamp(0, segment.text.length));

        if (beforeText.isNotEmpty) {
          newSegments.add(TextSegment(text: beforeText, formatting: segment.formatting));
        }
        if (afterText.isNotEmpty) {
          newSegments.add(TextSegment(text: afterText, formatting: segment.formatting));
        }
      }

      currentPos = segmentEnd;
    }

    return RichTextContent(segments: _mergeAdjacentSegments(newSegments));
  }

  /// Get formatting at a specific position
  TextFormatting getFormattingAt(int position) {
    if (position < 0 || position >= length) return const TextFormatting();

    int currentPos = 0;
    for (final segment in segments) {
      if (position >= currentPos && position < currentPos + segment.text.length) {
        return segment.formatting;
      }
      currentPos += segment.text.length;
    }

    return const TextFormatting();
  }

  /// Merge adjacent segments with identical formatting
  static List<TextSegment> _mergeAdjacentSegments(List<TextSegment> segments) {
    if (segments.length <= 1) return segments;

    final merged = <TextSegment>[];
    TextSegment current = segments.first;

    for (int i = 1; i < segments.length; i++) {
      final next = segments[i];
      if (current.formatting == next.formatting) {
        current = current.copyWith(text: current.text + next.text);
      } else {
        if (current.text.isNotEmpty) merged.add(current);
        current = next;
      }
    }

    if (current.text.isNotEmpty) merged.add(current);
    return merged;
  }

  RichTextContent copyWith({List<TextSegment>? segments}) {
    return RichTextContent(segments: segments ?? this.segments);
  }

  Map<String, dynamic> toJson() => {
    'segments': segments.map((s) => s.toJson()).toList(),
  };

  static RichTextContent fromJson(Map<String, dynamic> json) {
    final segmentsList = json['segments'] as List<dynamic>? ?? [];
    return RichTextContent(
      segments: segmentsList
          .map((s) => TextSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RichTextContent &&
          runtimeType == other.runtimeType &&
          _listEquals(other.segments, segments);

  @override
  int get hashCode => Object.hashAll(segments);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}