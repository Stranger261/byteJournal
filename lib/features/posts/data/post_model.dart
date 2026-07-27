import 'package:supabase_flutter/supabase_flutter.dart';

class PostModel {
  final String id;
  final String userId;
  final String? content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final List<PostImage> images;

  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLikedByCurrentUser;
  final bool isSharedByCurrentUser;

  PostModel({
    required this.id,
    required this.userId,
    this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.images = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLikedByCurrentUser = false,
    this.isSharedByCurrentUser = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    int extractCount(dynamic raw) {
      if (raw is List && raw.isNotEmpty) {
        final first = raw.first;
        if (first is Map && first['count'] != null)
          return first['count'] as int;
      }
      if (raw is int) return raw;
      return 0;
    }

    return PostModel(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      authorName: profile?['name'],
      authorAvatarUrl: profile?['avatar_url'],
      images:
          (map['post_images'] as List? ?? [])
              .map((e) => PostImage.fromMap(e))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      likeCount: extractCount(map['post_likes']),
      commentCount: extractCount(map['post_comments']),
      shareCount: extractCount(map['post_shares']),
      isLikedByCurrentUser: map['is_liked_by_current_user'] == true,
      isSharedByCurrentUser: map['is_shared_by_current_user'] == true,
    );
  }

  PostModel copyWith({
    String? content,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLikedByCurrentUser,
    bool? isSharedByCurrentUser,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      content: content ?? this.content,
      createdAt: createdAt,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      images: images,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      isSharedByCurrentUser:
          isSharedByCurrentUser ?? this.isSharedByCurrentUser,
    );
  }
}

class PostImage {
  final String id;
  final String storagePath;
  final int sortOrder;

  PostImage({
    required this.id,
    required this.storagePath,
    required this.sortOrder,
  });

  factory PostImage.fromMap(Map<String, dynamic> map) {
    return PostImage(
      id: map['id'],
      storagePath: map['storage_path'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  String get publicUrl => Supabase.instance.client.storage
      .from('post-images')
      .getPublicUrl(storagePath);
}

class CommentModel {
  final String id;
  final String postId;
  final String userId;
  final String? content;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatarUrl;
  final List<CommentImage> images;

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    this.content,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.images = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return CommentModel(
      id: map['id'],
      postId: map['post_id'],
      userId: map['user_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      authorName: profile?['name'],
      authorAvatarUrl: profile?['avatar_url'],
      images:
          (map['comment_images'] as List? ?? [])
              .map((e) => CommentImage.fromMap(e))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }
}

class CommentImage {
  final String id;
  final String storagePath;
  final int sortOrder;

  CommentImage({
    required this.id,
    required this.storagePath,
    required this.sortOrder,
  });

  factory CommentImage.fromMap(Map<String, dynamic> map) {
    return CommentImage(
      id: map['id'],
      storagePath: map['storage_path'],
      sortOrder: map['sort_order'] ?? 0,
    );
  }

  String get publicUrl => Supabase.instance.client.storage
      .from('post-images')
      .getPublicUrl(storagePath);
}
