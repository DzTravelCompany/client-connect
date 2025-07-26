class TagModel {
  final int id;
  final String name;
  final String color;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TagModel({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  TagModel copyWith({
    int? id,
    String? name,
    String? color,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TagModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ClientTagModel {
  final int id;
  final int clientId;
  final int tagId;
  final DateTime createdAt;

  const ClientTagModel({
    required this.id,
    required this.clientId,
    required this.tagId,
    required this.createdAt,
  });
}

class ClientWithTags {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? jobTitle;
  final List<TagModel> tags;

  const ClientWithTags({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.jobTitle,
    required this.tags,
  });

  String get fullName => '$firstName $lastName';
}