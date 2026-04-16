import 'package:flutter/material.dart';
import '../models/community_post.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import 'dart:convert';

class CommunityProvider with ChangeNotifier {
  final List<CommunityPost> _posts = [
    CommunityPost(
      id: 'post_1',
      author: 'Ramesh Kumar',
      location: 'Kurnool, AP',
      content: 'Has anyone tried the new Hybrid Rice Seeds? I\'m seeing great results in the first few weeks!',
      likes: ['user_2', 'user_3'],
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      avatar: 'RK',
      comments: [
        CommunityComment(
          id: 'c1',
          author: 'Sita Ram',
          content: 'Yes, Ramesh! The yield is much better than traditional seeds.',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ],
    ),
    CommunityPost(
      id: 'post_2',
      author: 'Suresh Reddy',
      location: 'Warangal, TS',
      content: 'Tip for the season: Using Urea along with Organic Manure has significantly improved my soil texture this year.',
      likes: ['user_1'],
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      avatar: 'SR',
    ),
  ];
  String? _currentLang;

  List<CommunityPost> get posts => [..._posts];

  Future<void> translatePosts(String lang) async {
    if (lang == 'en' || lang == _currentLang) return;
    _currentLang = lang;

    for (int i = 0; i < _posts.length; i++) {
      _translatePost(i, lang);
    }
  }

  Future<void> _translatePost(int index, String lang) async {
    final post = _posts[index];
    final cacheKeyContent = 'trans_post_${post.id}_$lang';
    final cacheKeyLoc = 'trans_loc_${post.id}_$lang';

    String? transContent;
    String? transLoc;

    if (CacheService.isFresh(cacheKeyContent)) {
      transContent = CacheService.load(cacheKeyContent);
      transLoc = CacheService.load(cacheKeyLoc);
    } else {
      try {
        final prompt = "Translate this farmer's post and its location to ${AppConstants.langNames[lang] ?? lang}. "
            "Respond ONLY with a JSON object: {\"content\": \"...\", \"location\": \"...\"}. "
            "Post: \"${post.content}\" Location: \"${post.location}\"";
        
        final response = await AIService.getAIResponse(prompt, language: lang);
        final cleanJson = response.replaceAll('```json', '').replaceAll('```', '').trim();
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        transContent = data['content'];
        transLoc = data['location'];

        if (transContent != null) CacheService.save(cacheKeyContent, transContent);
        if (transLoc != null) CacheService.save(cacheKeyLoc, transLoc);
      } catch (e) {
        debugPrint("Error translating post ${post.id}: $e");
      }
    }

    if (transContent != null || transLoc != null) {
      _posts[index] = post.copyWith(
        translatedContent: transContent,
        translatedLocation: transLoc,
      );
      notifyListeners();
    }

    // Also translate comments
    for (int j = 0; j < post.comments.length; j++) {
      _translateComment(index, j, lang);
    }
  }

  Future<void> _translateComment(int postIndex, int commentIndex, String lang) async {
    final post = _posts[postIndex];
    final comment = post.comments[commentIndex];
    final cacheKey = 'trans_comment_${comment.id}_$lang';

    String? transContent;
    if (CacheService.isFresh(cacheKey)) {
      transContent = CacheService.load(cacheKey);
    } else {
      try {
        final prompt = "Translate this comment to ${AppConstants.langNames[lang] ?? lang}. "
            "Respond with ONLY the translated text. "
            "Comment: \"${comment.content}\"";
        transContent = await AIService.getAIResponse(prompt, language: lang);
        CacheService.save(cacheKey, transContent);
      } catch (e) {
        debugPrint("Error translating comment ${comment.id}: $e");
      }
    }

    if (transContent != null) {
      final List<CommunityComment> newComments = List.from(_posts[postIndex].comments);
      newComments[commentIndex] = comment.copyWith(translatedContent: transContent);
      _posts[postIndex] = _posts[postIndex].copyWith(comments: newComments);
      notifyListeners();
    }
  }

  // Add the imports needed for LANG_NAMES check or define them here too
  // For simplicity, I'll copy the map here if needed, but it's better to share.
  // Actually, SchemesScreen is already in the project.
  // Wait, I need to import SchemesScreen if I use its static member.
  // Better yet, just put the map in constants.


  void addPost(String author, String location, String content, String avatar) {
    final newPost = CommunityPost(
      id: DateTime.now().toString(),
      author: author,
      location: location,
      content: content,
      likes: [],
      timestamp: DateTime.now(),
      avatar: avatar,
    );
    _posts.insert(0, newPost);
    notifyListeners();
  }

  void toggleLike(String postId, String userId) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final List<String> newlikes = List.from(post.likes);
      if (newlikes.contains(userId)) {
        newlikes.remove(userId);
      } else {
        newlikes.add(userId);
      }
      _posts[postIndex] = post.copyWith(likes: newlikes);
      notifyListeners();
    }
  }

  void addComment(String postId, String author, String content) {
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final newComment = CommunityComment(
        id: DateTime.now().toString(),
        author: author,
        content: content,
        timestamp: DateTime.now(),
      );
      final List<CommunityComment> newComments = List.from(post.comments)..add(newComment);
      _posts[postIndex] = post.copyWith(comments: newComments);
      notifyListeners();
    }
  }

  // Simulation of a real-time notification from another farmer
  void simulateIncomingPost() {
    Future.delayed(const Duration(seconds: 5), () {
      const author = 'Venkat Rao';
      const content = 'Quick question: Any recommendations for a good irrigation system for small farms?';
      addPost(author, 'Nizamabad, TS', content, 'VR');
      
      NotificationService.showCommunityNotification(
        id: 100,
        title: 'New Community Post',
        body: '$author: $content',
      );
    });
  }
}
