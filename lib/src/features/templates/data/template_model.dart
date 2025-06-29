class TemplateModel {
  final int id;
  final String name;
  final String type; // 'email' or 'whatsapp'
  final String? subject; // For email templates only
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TemplateModel({
    required this.id,
    required this.name,
    required this.type,
    this.subject,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmail => type == 'email';
  bool get isWhatsApp => type == 'whatsapp';

  TemplateModel copyWith({
    int? id,
    String? name,
    String? type,
    String? subject,
    String? body,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}