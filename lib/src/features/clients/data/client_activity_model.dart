enum ClientActivityType {
  created,
  updated,
  emailSent,
  campaignSent,
  tagAdded,
  tagRemoved,
  noteAdded,
  exported,
  imported,
}

class ClientActivityModel {
  final int id;
  final int clientId;
  final ClientActivityType activityType;
  final String description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const ClientActivityModel({
    required this.id,
    required this.clientId,
    required this.activityType,
    required this.description,
    this.metadata,
    required this.createdAt,
  });

  factory ClientActivityModel.fromJson(Map<String, dynamic> json) {
    return ClientActivityModel(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      activityType: ClientActivityType.values.firstWhere(
        (e) => e.name == json['activityType'],
        orElse: () => ClientActivityType.updated,
      ),
      description: json['description'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'activityType': activityType.name,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
