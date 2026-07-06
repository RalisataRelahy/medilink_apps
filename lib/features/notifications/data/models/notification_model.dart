class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String? type;
  final String?
  payload; // Précédemment callBack, contient les données de routage
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    this.type,
    this.payload,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '') as String,
      userId: (json['user_id'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      type: json['type'] as String?,
      payload: (json['payload'] ?? json['callBack']) as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isRead: (json['is_read'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      if (type != null) 'type': type,
      if (payload != null) 'payload': payload,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? type,
    String? payload,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
