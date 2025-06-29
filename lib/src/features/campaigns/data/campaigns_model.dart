class CampaignModel {
  final int id;
  final String name;
  final int templateId;
  final String status; // 'pending', 'in_progress', 'completed', 'failed'
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<int> clientIds;

  const CampaignModel({
    required this.id,
    required this.name,
    required this.templateId,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
    this.completedAt,
    required this.clientIds,
  });

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  CampaignModel copyWith({
    int? id,
    String? name,
    int? templateId,
    String? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? completedAt,
    List<int>? clientIds,
  }) {
    return CampaignModel(
      id: id ?? this.id,
      name: name ?? this.name,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      clientIds: clientIds ?? this.clientIds,
    );
  }
}

class MessageLogModel {
  final int id;
  final int campaignId;
  final int clientId;
  final String type; // 'email' or 'whatsapp'
  final String status; // 'pending', 'sent', 'failed'
  final String? errorMessage;
  final DateTime? sentAt;
  final DateTime createdAt;

  const MessageLogModel({
    required this.id,
    required this.campaignId,
    required this.clientId,
    required this.type,
    required this.status,
    this.errorMessage,
    this.sentAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';
}