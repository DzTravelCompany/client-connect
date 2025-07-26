import 'package:client_connect/src/core/models/database.dart';
import 'package:fluent_ui/fluent_ui.dart';


class CampaignModel {
  final int id;
  final String name;
  final int templateId;
  final String status; // 'pending', 'queued', 'in_progress', 'paused', 'completed', 'failed', 'cancelled'
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
  bool get isScheduled => status == 'scheduled';
  bool get isQueued => status == 'queued';
  bool get isPaused => status == 'paused';
  bool get isCancelled => status == 'cancelled';

  // Progress tracking
  double get progressPercentage {
    if (clientIds.isEmpty) return 0.0;
    // This will be calculated based on message logs in the UI layer
    return 0.0;
  }

  DateTime? get estimatedCompletionTime {
    if (!isInProgress || clientIds.isEmpty) return null;
    // Estimation logic will be implemented in the service layer
    return null;
  }

  // Status display helpers
  String get statusDisplayName {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'queued':
        return 'Queued';
      case 'in_progress':
        return 'Sending';
      case 'paused':
        return 'Paused';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      case 'scheduled':
        return 'Scheduled';
      default:
        return status.toUpperCase();
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
      case 'queued':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'paused':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'scheduled':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'pending':
        return FluentIcons.clock;
      case 'queued':
        return FluentIcons.list;
      case 'in_progress':
        return FluentIcons.send;
      case 'paused':
        return FluentIcons.pause;
      case 'completed':
        return FluentIcons.completed;
      case 'failed':
        return FluentIcons.error;
      case 'cancelled':
        return FluentIcons.cancel;
      case 'scheduled':
        return FluentIcons.calendar;
      default:
        return FluentIcons.help;
    }
  }

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
  final String status; // 'pending', 'sent', 'failed', 'retrying', 'failed_max_retries'
  final String? errorMessage;
  final DateTime? sentAt;
  final DateTime createdAt;

  // Retry-related fields
  final int retryCount;
  final int maxRetries;
  final DateTime? nextRetryAt;
  final DateTime? lastRetryAt;
  final String? retryReason;

  const MessageLogModel({
    required this.id,
    required this.campaignId,
    required this.clientId,
    required this.type,
    required this.status,
    this.errorMessage,
    this.sentAt,
    required this.createdAt,
    required this.retryCount,
    required this.maxRetries,
    this.nextRetryAt,
    this.lastRetryAt,
    this.retryReason,
  });

  factory MessageLogModel.fromDriftRow(MessageLog row) {
    return MessageLogModel(
      id: row.id,
      campaignId: row.campaignId,
      clientId: row.clientId,
      type: row.type,
      status: row.status,
      errorMessage: row.errorMessage,
      sentAt: row.sentAt,
      createdAt: row.createdAt,
      retryCount: row.retryCount,
      maxRetries: row.maxRetries,
      nextRetryAt: row.nextRetryAt,
      lastRetryAt: row.lastRetryAt,
      retryReason: row.retryReason,
    );
  }

  bool get isPending => status == 'pending';
  bool get isSent => status == 'sent';
  bool get isFailed => status == 'failed';
  bool get isRetrying => status == 'retrying';
  bool get isFailedMaxRetries => status == 'failed_max_retries';
  bool get canRetry => (isFailed || isFailedMaxRetries) && retryCount < maxRetries;
  bool get hasRetryScheduled => nextRetryAt != null && nextRetryAt!.isAfter(DateTime.now());
}

// New model for retry logs
class RetryLogModel {
  final int id;
  final int messageLogId;
  final int retryAttempt;
  final String status;
  final String? errorMessage;
  final String? errorType;
  final DateTime attemptedAt;
  final int? delayMinutes;
  final String triggerType;

  const RetryLogModel({
    required this.id,
    required this.messageLogId,
    required this.retryAttempt,
    required this.status,
    this.errorMessage,
    this.errorType,
    required this.attemptedAt,
    this.delayMinutes,
    required this.triggerType,
  });

  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isScheduled => status == 'scheduled';
  bool get isAttempting => status == 'attempting';
  bool get isManualTrigger => triggerType == 'manual';
}