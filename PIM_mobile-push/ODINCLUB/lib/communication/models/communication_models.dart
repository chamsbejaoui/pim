class ChatUserModel {
  ChatUserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.photoUrl,
    this.email,
    this.phone,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String role;
  final String? photoUrl;
  final String? email;
  final String? phone;

  String get displayName => '$firstName $lastName'.trim();

  factory ChatUserModel.fromJson(Map<String, dynamic> json) {
    return ChatUserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class ConversationParticipantModel {
  ConversationParticipantModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.photoUrl,
    this.lastReadAt,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String role;
  final String? photoUrl;
  final DateTime? lastReadAt;

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) {
    return ConversationParticipantModel(
      userId: (json['userId'] ?? '').toString(),
      firstName: (json['firstName'] ?? '').toString(),
      lastName: (json['lastName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      photoUrl: json['photoUrl']?.toString(),
      lastReadAt: json['lastReadAt'] != null
          ? DateTime.tryParse(json['lastReadAt'].toString())
          : null,
    );
  }
}

class ConversationModel {
  ConversationModel({
    required this.id,
    required this.type,
    required this.displayTitle,
    required this.lastMessagePreview,
    this.title,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participants = const [],
  });

  final String id;
  final String type;
  final String displayTitle;
  final String lastMessagePreview;
  final String? title;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<ConversationParticipantModel> participants;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantsRaw =
        (json['participants'] as List<dynamic>? ?? const []);
    return ConversationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      displayTitle: (json['displayTitle'] ?? json['title'] ?? 'Conversation')
          .toString(),
      title: json['title']?.toString(),
      lastMessagePreview: (json['lastMessagePreview'] ?? '').toString(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'].toString())
          : null,
      unreadCount: int.tryParse((json['unreadCount'] ?? '0').toString()) ?? 0,
      participants: participantsRaw
          .whereType<Map<String, dynamic>>()
          .map(ConversationParticipantModel.fromJson)
          .toList(),
    );
  }
}

class UploadedDocumentModel {
  UploadedDocumentModel({
    required this.url,
    required this.mimeType,
    required this.name,
    required this.size,
  });

  final String url;
  final String mimeType;
  final String name;
  final int size;

  Map<String, dynamic> toJson() {
    return {'url': url, 'mimeType': mimeType, 'name': name, 'size': size};
  }

  factory UploadedDocumentModel.fromJson(Map<String, dynamic> json) {
    return UploadedDocumentModel(
      url: (json['url'] ?? '').toString(),
      mimeType: (json['mimeType'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      size: int.tryParse((json['size'] ?? '0').toString()) ?? 0,
    );
  }
}

class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.contentType,
    required this.createdAt,
    this.text,
    this.file,
    this.deletedAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String contentType;
  final DateTime createdAt;
  final String? text;
  final UploadedDocumentModel? file;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null || text == 'Message deleted';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      senderRole: (json['senderRole'] ?? '').toString(),
      contentType: (json['contentType'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      text: json['text']?.toString(),
      file: json['file'] is Map<String, dynamic>
          ? UploadedDocumentModel.fromJson(json['file'] as Map<String, dynamic>)
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'].toString())
          : null,
    );
  }
}

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    this.readAt,
    this.data = const {},
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String status;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic> data;

  bool get isUnread => status == 'UNREAD';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      data: json['data'] is Map<String, dynamic>
          ? (json['data'] as Map<String, dynamic>)
          : <String, dynamic>{},
    );
  }
}
