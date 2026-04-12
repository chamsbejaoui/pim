class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String notificationType;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final String deliveryStatus;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.notificationType,
    this.relatedEntityType,
    this.relatedEntityId,
    this.isRead = false,
    this.readAt,
    this.deliveryStatus = 'pending',
    this.createdAt,
  });

  String get typeLabel {
    switch (notificationType) {
      case 'event_reminder': return 'Rappel';
      case 'new_event': return 'Nouvel Événement';
      case 'event_cancelled': return 'Annulation';
      case 'event_updated': return 'Modification';
      case 'status_change': return 'Changement Statut';
      case 'participation_request': return 'Participation';
      default: return 'Général';
    }
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      notificationType: json['notificationType'] ?? 'general',
      relatedEntityType: json['relatedEntityType'],
      relatedEntityId: json['relatedEntityId'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      deliveryStatus: json['deliveryStatus'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
