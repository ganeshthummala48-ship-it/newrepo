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
}
