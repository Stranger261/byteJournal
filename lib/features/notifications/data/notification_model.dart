class NotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final String type;
  final String postId;
  final String? commentId;
  final bool isRead;
  final DateTime createdAt;

  final String? actorName;
  final String? actorAvatarUrl;
  final String? postContentPreview;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    required this.type,
    required this.postId,
    this.commentId,
    required this.isRead,
    required this.createdAt,
    this.actorName,
    this.actorAvatarUrl,
    this.postContentPreview,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    final actor = map['actor'] as Map<String, dynamic>?;
    final post = map['post'] as Map<String, dynamic>?;

    return NotificationModel(
      id: map['id'],
      recipientId: map['recipient_id'],
      actorId: map['actor_id'],
      type: map['type'],
      postId: map['post_id'],
      commentId: map['comment_id'],
      isRead: map['is_read'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      actorName: actor?['name'],
      actorAvatarUrl: actor?['avatar_url'],
      postContentPreview: post?['content'],
    );
  }

  String get message {
    switch (type) {
      case 'like':
        return '${actorName ?? 'Someone'} liked your post';
      case 'comment':
        return '${actorName ?? 'Someone'} commented on your post';
      case 'share':
        return '${actorName ?? 'Someone'} shared your post';
      default:
        return '${actorName ?? 'Someone'} interacted with your post';
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      recipientId: recipientId,
      actorId: actorId,
      type: type,
      postId: postId,
      commentId: commentId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      actorName: actorName,
      actorAvatarUrl: actorAvatarUrl,
      postContentPreview: postContentPreview,
    );
  }
}
