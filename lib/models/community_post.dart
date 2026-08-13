class CommunityPost {
  final String id;
  final String author;
  final String location;
  final String content;
  final List<String> likes; // List of user IDs
  final DateTime timestamp;
  final String avatar;
  final List<CommunityComment> comments;
  final String? translatedContent;
  final String? translatedLocation;

  CommunityPost({
    required this.id,
    required this.author,
    required this.location,
    required this.content,
    required this.likes,
    required this.timestamp,
    required this.avatar,
    this.comments = const [],
    this.translatedContent,
    this.translatedLocation,
  });

  CommunityPost copyWith({
    List<String>? likes,
    List<CommunityComment>? comments,
    String? translatedContent,
    String? translatedLocation,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      location: location,
      content: content,
      likes: likes ?? this.likes,
      timestamp: timestamp,
      avatar: avatar,
      comments: comments ?? this.comments,
      translatedContent: translatedContent ?? this.translatedContent,
      translatedLocation: translatedLocation ?? this.translatedLocation,
    );
  }

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      author: json['author'] as String,
      location: json['location'] as String,
      content: json['content'] as String,
      likes: List<String>.from(json['likes'] ?? []),
      timestamp: DateTime.parse(json['timestamp']),
      avatar: json['avatar'] as String,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => CommunityComment.fromJson(c))
              .toList() ??
          [],
      translatedContent: json['translatedContent'] as String?,
      translatedLocation: json['translatedLocation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'location': location,
      'content': content,
      'likes': likes,
      'timestamp': timestamp.toIso8601String(),
      'avatar': avatar,
      'comments': comments.map((c) => c.toJson()).toList(),
      'translatedContent': translatedContent,
      'translatedLocation': translatedLocation,
    };
  }
}

class CommunityComment {
  final String id;
  final String author;
  final String content;
  final DateTime timestamp;
  final String? translatedContent;

  CommunityComment({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    this.translatedContent,
  });

  CommunityComment copyWith({
    String? translatedContent,
  }) {
    return CommunityComment(
      id: id,
      author: author,
      content: content,
      timestamp: timestamp,
      translatedContent: translatedContent ?? this.translatedContent,
    );
  }

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String,
      author: json['author'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp']),
      translatedContent: json['translatedContent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'translatedContent': translatedContent,
    };
  }
}
