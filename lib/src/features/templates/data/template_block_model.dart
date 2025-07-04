enum TemplateType {
  email,
  whatsapp,
}

enum TemplateBlockType {
  text,
  richText,
  image,
  button,
  spacer,
  divider,
  list,
  table,
  social,
  qrCode,
  countdown,
  rating,
  progress,
}

abstract class TemplateBlock {
  final String id;
  final TemplateBlockType type;
  final Map<String, dynamic> properties;
  final int sortOrder;

  TemplateBlock({
    required this.id,
    required this.type,
    required this.properties,
    this.sortOrder = 0,
  });

  TemplateBlock copyWith({
    Map<String, dynamic>? properties,
    int? sortOrder,
  });
  
  Map<String, dynamic> toJson();
  
  static TemplateBlock fromJson(Map<String, dynamic> json) {
    final type = TemplateBlockType.values[json['type']];
    switch (type) {
      case TemplateBlockType.text:
        return TextBlock.fromJson(json);
      case TemplateBlockType.richText:
        return RichTextBlock.fromJson(json);
      case TemplateBlockType.image:
        return ImageBlock.fromJson(json);
      case TemplateBlockType.button:
        return ButtonBlock.fromJson(json);
      case TemplateBlockType.spacer:
        return SpacerBlock.fromJson(json);
      case TemplateBlockType.divider:
        return DividerBlock.fromJson(json);
      case TemplateBlockType.list:
        return ListBlock.fromJson(json);
      case TemplateBlockType.table:
        return TableBlock.fromJson(json);
      case TemplateBlockType.social:
        return SocialBlock.fromJson(json);
      case TemplateBlockType.qrCode:
        return QRCodeBlock.fromJson(json);
      case TemplateBlockType.countdown:
        return CountdownBlock.fromJson(json);
      case TemplateBlockType.rating:
        return RatingBlock.fromJson(json);
      case TemplateBlockType.progress:
        return ProgressBlock.fromJson(json);
    }
  }

  bool isCompatibleWith(TemplateType templateType) {
    // Define which blocks are compatible with which template types
    switch (type) {
      case TemplateBlockType.text:
      case TemplateBlockType.richText:
      case TemplateBlockType.image:
      case TemplateBlockType.spacer:
      case TemplateBlockType.divider:
        return true; // Compatible with both
      case TemplateBlockType.button:
      case TemplateBlockType.list:
      case TemplateBlockType.table:
      case TemplateBlockType.social:
      case TemplateBlockType.countdown:
      case TemplateBlockType.rating:
      case TemplateBlockType.progress:
        return templateType == TemplateType.email; // Email only
      case TemplateBlockType.qrCode:
        return templateType == TemplateType.whatsapp; // WhatsApp only
    }
  }
}

// Enhanced Text Block with placeholder support
class TextBlock extends TemplateBlock {
  String get text => properties['text'] ?? '';
  double get fontSize => properties['fontSize'] ?? 14.0;
  String get fontWeight => properties['fontWeight'] ?? 'normal';
  String get color => properties['color'] ?? '#000000';
  String get alignment => properties['alignment'] ?? 'left';
  String get fontFamily => properties['fontFamily'] ?? 'default';
  double get lineHeight => properties['lineHeight'] ?? 1.4;
  double get letterSpacing => properties['letterSpacing'] ?? 0.0;
  bool get italic => properties['italic'] ?? false;
  bool get underline => properties['underline'] ?? false;

  TextBlock({
    required super.id,
    String text = 'Sample Text',
    double fontSize = 14.0,
    String fontWeight = 'normal',
    String color = '#000000',
    String alignment = 'left',
    String fontFamily = 'default',
    double lineHeight = 1.4,
    double letterSpacing = 0.0,
    bool italic = false,
    bool underline = false,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.text,
          properties: {
            'text': text,
            'fontSize': fontSize,
            'fontWeight': fontWeight,
            'color': color,
            'alignment': alignment,
            'fontFamily': fontFamily,
            'lineHeight': lineHeight,
            'letterSpacing': letterSpacing,
            'italic': italic,
            'underline': underline,
          },
        );

  // Get all placeholders in the text
  List<String> get placeholders {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(text);
    return matches.map((match) => match.group(1)!.trim()).toList();
  }

  // Replace placeholders with actual values
  String renderWithData(Map<String, String> data) {
    String renderedText = text;
    for (final entry in data.entries) {
      renderedText = renderedText.replaceAll('{{${entry.key}}}', entry.value);
    }
    return renderedText;
  }

  // Check if text contains placeholders
  bool get hasPlaceholders => placeholders.isNotEmpty;

  @override
  TextBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return TextBlock(
      id: id,
      text: newProps['text'],
      fontSize: newProps['fontSize'],
      fontWeight: newProps['fontWeight'],
      color: newProps['color'],
      alignment: newProps['alignment'],
      fontFamily: newProps['fontFamily'],
      lineHeight: newProps['lineHeight'],
      letterSpacing: newProps['letterSpacing'],
      italic: newProps['italic'],
      underline: newProps['underline'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static TextBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return TextBlock(
      id: json['id'],
      text: props['text'] ?? '',
      fontSize: props['fontSize'] ?? 14.0,
      fontWeight: props['fontWeight'] ?? 'normal',
      color: props['color'] ?? '#000000',
      alignment: props['alignment'] ?? 'left',
      fontFamily: props['fontFamily'] ?? 'default',
      lineHeight: props['lineHeight'] ?? 1.4,
      letterSpacing: props['letterSpacing'] ?? 0.0,
      italic: props['italic'] ?? false,
      underline: props['underline'] ?? false,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Rich Text Block with HTML support
class RichTextBlock extends TemplateBlock {
  String get htmlContent => properties['htmlContent'] ?? '';
  double get fontSize => properties['fontSize'] ?? 14.0;
  String get fontFamily => properties['fontFamily'] ?? 'default';
  double get lineHeight => properties['lineHeight'] ?? 1.4;

  RichTextBlock({
    required super.id,
    String htmlContent = '<p>Rich text content</p>',
    double fontSize = 14.0,
    String fontFamily = 'default',
    double lineHeight = 1.4,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.richText,
          properties: {
            'htmlContent': htmlContent,
            'fontSize': fontSize,
            'fontFamily': fontFamily,
            'lineHeight': lineHeight,
          },
        );

  // Get all placeholders in the HTML content
  List<String> get placeholders {
    final regex = RegExp(r'\{\{([^}]+)\}\}');
    final matches = regex.allMatches(htmlContent);
    return matches.map((match) => match.group(1)!.trim()).toList();
  }

  // Replace placeholders with actual values
  String renderWithData(Map<String, String> data) {
    String renderedContent = htmlContent;
    for (final entry in data.entries) {
      renderedContent = renderedContent.replaceAll('{{${entry.key}}}', entry.value);
    }
    return renderedContent;
  }

  // Check if content contains placeholders
  bool get hasPlaceholders => placeholders.isNotEmpty;

  @override
  RichTextBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return RichTextBlock(
      id: id,
      htmlContent: newProps['htmlContent'],
      fontSize: newProps['fontSize'],
      fontFamily: newProps['fontFamily'],
      lineHeight: newProps['lineHeight'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static RichTextBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return RichTextBlock(
      id: json['id'],
      htmlContent: props['htmlContent'] ?? '',
      fontSize: props['fontSize'] ?? 14.0,
      fontFamily: props['fontFamily'] ?? 'default',
      lineHeight: props['lineHeight'] ?? 1.4,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Enhanced Image Block
class ImageBlock extends TemplateBlock {
  String get imageUrl => properties['imageUrl'] ?? '';
  String get altText => properties['altText'] ?? '';
  double get width => properties['width'] ?? 200.0;
  double get height => properties['height'] ?? 150.0;
  String get fit => properties['fit'] ?? 'cover';
  String get alignment => properties['alignment'] ?? 'center';
  double get borderRadius => properties['borderRadius'] ?? 0.0;
  String get borderColor => properties['borderColor'] ?? '#000000';
  double get borderWidth => properties['borderWidth'] ?? 0.0;
  bool get isResponsive => properties['isResponsive'] ?? true;

  ImageBlock({
    required super.id,
    String imageUrl = '',
    String altText = '',
    double width = 200.0,
    double height = 150.0,
    String fit = 'cover',
    String alignment = 'center',
    double borderRadius = 0.0,
    String borderColor = '#000000',
    double borderWidth = 0.0,
    bool isResponsive = true,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.image,
          properties: {
            'imageUrl': imageUrl,
            'altText': altText,
            'width': width,
            'height': height,
            'fit': fit,
            'alignment': alignment,
            'borderRadius': borderRadius,
            'borderColor': borderColor,
            'borderWidth': borderWidth,
            'isResponsive': isResponsive,
          },
        );

  @override
  ImageBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return ImageBlock(
      id: id,
      imageUrl: newProps['imageUrl'],
      altText: newProps['altText'],
      width: newProps['width'],
      height: newProps['height'],
      fit: newProps['fit'],
      alignment: newProps['alignment'],
      borderRadius: newProps['borderRadius'],
      borderColor: newProps['borderColor'],
      borderWidth: newProps['borderWidth'],
      isResponsive: newProps['isResponsive'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static ImageBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return ImageBlock(
      id: json['id'],
      imageUrl: props['imageUrl'] ?? '',
      altText: props['altText'] ?? '',
      width: props['width'] ?? 200.0,
      height: props['height'] ?? 150.0,
      fit: props['fit'] ?? 'cover',
      alignment: props['alignment'] ?? 'center',
      borderRadius: props['borderRadius'] ?? 0.0,
      borderColor: props['borderColor'] ?? '#000000',
      borderWidth: props['borderWidth'] ?? 0.0,
      isResponsive: props['isResponsive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Enhanced Button Block
class ButtonBlock extends TemplateBlock {
  String get text => properties['text'] ?? 'Button';
  String get backgroundColor => properties['backgroundColor'] ?? '#007ACC';
  String get textColor => properties['textColor'] ?? '#FFFFFF';
  String get action => properties['action'] ?? '';
  String get actionType => properties['actionType'] ?? 'url'; // 'url', 'email', 'phone'
  double get borderRadius => properties['borderRadius'] ?? 4.0;
  String get borderColor => properties['borderColor'] ?? 'transparent';
  double get borderWidth => properties['borderWidth'] ?? 0.0;
  String get size => properties['size'] ?? 'medium'; // 'small', 'medium', 'large'
  String get alignment => properties['alignment'] ?? 'center';
  bool get fullWidth => properties['fullWidth'] ?? false;
  String get hoverColor => properties['hoverColor'] ?? '';

  ButtonBlock({
    required super.id,
    String text = 'Button',
    String backgroundColor = '#007ACC',
    String textColor = '#FFFFFF',
    String action = '',
    String actionType = 'url',
    double borderRadius = 4.0,
    String borderColor = 'transparent',
    double borderWidth = 0.0,
    String size = 'medium',
    String alignment = 'center',
    bool fullWidth = false,
    String hoverColor = '',
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.button,
          properties: {
            'text': text,
            'backgroundColor': backgroundColor,
            'textColor': textColor,
            'action': action,
            'actionType': actionType,
            'borderRadius': borderRadius,
            'borderColor': borderColor,
            'borderWidth': borderWidth,
            'size': size,
            'alignment': alignment,
            'fullWidth': fullWidth,
            'hoverColor': hoverColor,
          },
        );

  @override
  ButtonBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return ButtonBlock(
      id: id,
      text: newProps['text'],
      backgroundColor: newProps['backgroundColor'],
      textColor: newProps['textColor'],
      action: newProps['action'],
      actionType: newProps['actionType'],
      borderRadius: newProps['borderRadius'],
      borderColor: newProps['borderColor'],
      borderWidth: newProps['borderWidth'],
      size: newProps['size'],
      alignment: newProps['alignment'],
      fullWidth: newProps['fullWidth'],
      hoverColor: newProps['hoverColor'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static ButtonBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return ButtonBlock(
      id: json['id'],
      text: props['text'] ?? 'Button',
      backgroundColor: props['backgroundColor'] ?? '#007ACC',
      textColor: props['textColor'] ?? '#FFFFFF',
      action: props['action'] ?? '',
      actionType: props['actionType'] ?? 'url',
      borderRadius: props['borderRadius'] ?? 4.0,
      borderColor: props['borderColor'] ?? 'transparent',
      borderWidth: props['borderWidth'] ?? 0.0,
      size: props['size'] ?? 'medium',
      alignment: props['alignment'] ?? 'center',
      fullWidth: props['fullWidth'] ?? false,
      hoverColor: props['hoverColor'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// List Block
class ListBlock extends TemplateBlock {
  List<String> get items => List<String>.from(properties['items'] ?? []);
  String get listType => properties['listType'] ?? 'bullet'; // 'bullet', 'numbered'
  String get bulletStyle => properties['bulletStyle'] ?? '•';
  double get fontSize => properties['fontSize'] ?? 14.0;
  String get color => properties['color'] ?? '#000000';
  double get spacing => properties['spacing'] ?? 4.0;

  ListBlock({
    required super.id,
    List<String> items = const ['Item 1', 'Item 2', 'Item 3'],
    String listType = 'bullet',
    String bulletStyle = '•',
    double fontSize = 14.0,
    String color = '#000000',
    double spacing = 4.0,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.list,
          properties: {
            'items': items,
            'listType': listType,
            'bulletStyle': bulletStyle,
            'fontSize': fontSize,
            'color': color,
            'spacing': spacing,
          },
        );

  @override
  ListBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return ListBlock(
      id: id,
      items: List<String>.from(newProps['items'] ?? []),
      listType: newProps['listType'],
      bulletStyle: newProps['bulletStyle'],
      fontSize: newProps['fontSize'],
      color: newProps['color'],
      spacing: newProps['spacing'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static ListBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return ListBlock(
      id: json['id'],
      items: List<String>.from(props['items'] ?? []),
      listType: props['listType'] ?? 'bullet',
      bulletStyle: props['bulletStyle'] ?? '•',
      fontSize: props['fontSize'] ?? 14.0,
      color: props['color'] ?? '#000000',
      spacing: props['spacing'] ?? 4.0,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// QR Code Block (WhatsApp specific)
class QRCodeBlock extends TemplateBlock {
  String get data => properties['data'] ?? '';
  double get size => properties['size'] ?? 150.0;
  String get errorCorrectionLevel => properties['errorCorrectionLevel'] ?? 'M';
  String get foregroundColor => properties['foregroundColor'] ?? '#000000';
  String get backgroundColor => properties['backgroundColor'] ?? '#FFFFFF';

  QRCodeBlock({
    required super.id,
    String data = '',
    double size = 150.0,
    String errorCorrectionLevel = 'M',
    String foregroundColor = '#000000',
    String backgroundColor = '#FFFFFF',
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.qrCode,
          properties: {
            'data': data,
            'size': size,
            'errorCorrectionLevel': errorCorrectionLevel,
            'foregroundColor': foregroundColor,
            'backgroundColor': backgroundColor,
          },
        );

  @override
  QRCodeBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return QRCodeBlock(
      id: id,
      data: newProps['data'],
      size: newProps['size'],
      errorCorrectionLevel: newProps['errorCorrectionLevel'],
      foregroundColor: newProps['foregroundColor'],
      backgroundColor: newProps['backgroundColor'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static QRCodeBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return QRCodeBlock(
      id: json['id'],
      data: props['data'] ?? '',
      size: props['size'] ?? 150.0,
      errorCorrectionLevel: props['errorCorrectionLevel'] ?? 'M',
      foregroundColor: props['foregroundColor'] ?? '#000000',
      backgroundColor: props['backgroundColor'] ?? '#FFFFFF',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Social Media Block
class SocialBlock extends TemplateBlock {
  List<Map<String, String>> get socialLinks => 
      List<Map<String, String>>.from(properties['socialLinks'] ?? []);
  String get layout => properties['layout'] ?? 'horizontal'; // 'horizontal', 'vertical'
  double get iconSize => properties['iconSize'] ?? 24.0;
  String get style => properties['style'] ?? 'icons'; // 'icons', 'buttons'

  SocialBlock({
    required super.id,
    List<Map<String, String>> socialLinks = const [],
    String layout = 'horizontal',
    double iconSize = 24.0,
    String style = 'icons',
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.social,
          properties: {
            'socialLinks': socialLinks,
            'layout': layout,
            'iconSize': iconSize,
            'style': style,
          },
        );

  @override
  SocialBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return SocialBlock(
      id: id,
      socialLinks: List<Map<String, String>>.from(newProps['socialLinks'] ?? []),
      layout: newProps['layout'],
      iconSize: newProps['iconSize'],
      style: newProps['style'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static SocialBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return SocialBlock(
      id: json['id'],
      socialLinks: List<Map<String, String>>.from(props['socialLinks'] ?? []),
      layout: props['layout'] ?? 'horizontal',
      iconSize: props['iconSize'] ?? 24.0,
      style: props['style'] ?? 'icons',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Keep existing SpacerBlock and DividerBlock with minor enhancements
class SpacerBlock extends TemplateBlock {
  double get height => properties['height'] ?? 20.0;

  SpacerBlock({
    required super.id,
    double height = 20.0,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.spacer,
          properties: {'height': height},
        );

  @override
  SpacerBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return SpacerBlock(
      id: id,
      height: newProps['height'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static SpacerBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return SpacerBlock(
      id: json['id'],
      height: props['height'] ?? 20.0,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class DividerBlock extends TemplateBlock {
  String get color => properties['color'] ?? '#CCCCCC';
  double get thickness => properties['thickness'] ?? 1.0;
  String get style => properties['style'] ?? 'solid'; // 'solid', 'dashed', 'dotted'
  double get width => properties['width'] ?? 100.0; // percentage

  DividerBlock({
    required super.id,
    String color = '#CCCCCC',
    double thickness = 1.0,
    String style = 'solid',
    double width = 100.0,
    super.sortOrder = 0,
  }) : super(
          type: TemplateBlockType.divider,
          properties: {
            'color': color,
            'thickness': thickness,
            'style': style,
            'width': width,
          },
        );

  @override
  DividerBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) {
    final newProps = Map<String, dynamic>.from(this.properties);
    if (properties != null) {
      newProps.addAll(properties);
    }
    return DividerBlock(
      id: id,
      color: newProps['color'],
      thickness: newProps['thickness'],
      style: newProps['style'],
      width: newProps['width'],
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'sortOrder': sortOrder,
        'properties': properties,
      };

  static DividerBlock fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    return DividerBlock(
      id: json['id'],
      color: props['color'] ?? '#CCCCCC',
      thickness: props['thickness'] ?? 1.0,
      style: props['style'] ?? 'solid',
      width: props['width'] ?? 100.0,
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

// Add placeholder implementations for other blocks
class TableBlock extends TemplateBlock {
  TableBlock({required super.id, super.sortOrder = 0}) : super(
    type: TemplateBlockType.table, 
    properties: {},
  );
  
  @override
  TableBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) => this;
  
  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type.index, 'sortOrder': sortOrder, 'properties': properties};
  
  static TableBlock fromJson(Map<String, dynamic> json) => TableBlock(id: json['id'], sortOrder: json['sortOrder'] ?? 0);
}

class CountdownBlock extends TemplateBlock {
  CountdownBlock({required super.id, super.sortOrder = 0}) : super(
    type: TemplateBlockType.countdown, 
    properties: {},
  );
  
  @override
  CountdownBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) => this;
  
  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type.index, 'sortOrder': sortOrder, 'properties': properties};
  
  static CountdownBlock fromJson(Map<String, dynamic> json) => CountdownBlock(id: json['id'], sortOrder: json['sortOrder'] ?? 0);
}

class RatingBlock extends TemplateBlock {
  RatingBlock({required super.id, super.sortOrder = 0}) : super(
    type: TemplateBlockType.rating, 
    properties: {},
  );
  
  @override
  RatingBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) => this;
  
  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type.index, 'sortOrder': sortOrder, 'properties': properties};
  
  static RatingBlock fromJson(Map<String, dynamic> json) => RatingBlock(id: json['id'], sortOrder: json['sortOrder'] ?? 0);
}

class ProgressBlock extends TemplateBlock {
  ProgressBlock({required super.id, super.sortOrder = 0}) : super(
    type: TemplateBlockType.progress, 
    properties: {},
  );
  
  @override
  ProgressBlock copyWith({Map<String, dynamic>? properties, int? sortOrder}) => this;
  
  @override
  Map<String, dynamic> toJson() => {'id': id, 'type': type.index, 'sortOrder': sortOrder, 'properties': properties};
  
  static ProgressBlock fromJson(Map<String, dynamic> json) => ProgressBlock(id: json['id'], sortOrder: json['sortOrder'] ?? 0);
}

// Placeholder management utilities
class PlaceholderManager {
  static const Map<String, String> defaultPlaceholders = {
    'first_name': 'First Name',
    'last_name': 'Last Name',
    'full_name': 'Full Name',
    'email': 'Email Address',
    'phone': 'Phone Number',
    'company': 'Company Name',
    'job_title': 'Job Title',
    'address': 'Address',
    'date': 'Current Date',
    'time': 'Current Time',
  };

  static const Map<String, String> sampleData = {
    'first_name': 'John',
    'last_name': 'Doe',
    'full_name': 'John Doe',
    'email': 'john.doe@example.com',
    'phone': '+1 (555) 123-4567',
    'company': 'Acme Corporation',
    'job_title': 'Software Engineer',
    'address': '123 Main St, Anytown, USA',
    'date': '2024-01-15',
    'time': '10:30 AM',
  };

  static List<String> getAvailablePlaceholders() {
    return defaultPlaceholders.keys.toList();
  }

  static String getPlaceholderLabel(String key) {
    return defaultPlaceholders[key] ?? key;
  }

  static String getSampleValue(String key) {
    return sampleData[key] ?? '[${key.toUpperCase()}]';
  }

  static Map<String, String> getAllSampleData() {
    return Map.from(sampleData);
  }

  // Extract all placeholders from a list of blocks
  static Set<String> extractPlaceholdersFromBlocks(List<TemplateBlock> blocks) {
    final placeholders = <String>{};
    
    for (final block in blocks) {
      if (block is TextBlock && block.hasPlaceholders) {
        placeholders.addAll(block.placeholders);
      } else if (block is RichTextBlock && block.hasPlaceholders) {
        placeholders.addAll(block.placeholders);
      }
    }
    
    return placeholders;
  }
}
