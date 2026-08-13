import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/community_post.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import '../services/cache_service.dart';
import 'dart:convert';

class CommunityProvider with ChangeNotifier {
  List<CommunityPost> _posts = [];
  String? _currentLang;
  WebSocketChannel? _channel;
  bool _isConnected = false;

  List<CommunityPost> get posts => [..._posts];

  CommunityProvider() {
    _initWebSocket();
  }

  void _initWebSocket() {
    final box = Hive.box('userBox');
    final userId = box.get('phone', defaultValue: 'guest_${DateTime.now().millisecondsSinceEpoch}');
    final wsUrl = '${AppConstants.baseUrl.replaceFirst('http', 'ws')}/ws/community/$userId';
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;
      
      _channel!.stream.listen((message) {
        final data = jsonDecode(message);
        _handleIncomingMessage(data);
      }, onDone: () {
        _isConnected = false;
        // Reconnect logic can be added here if needed
      }, onError: (error) {
        _isConnected = false;
        debugPrint('WebSocket error: $error');
      });
    } catch (e) {
      debugPrint('Error connecting to websocket: $e');
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'];
    final payload = data['data'];

    if (type == 'init') {
      _posts = (payload as List).map((p) => CommunityPost.fromJson(p)).toList();
      if (_currentLang != null) {
        translatePosts(_currentLang!);
      } else {
        notifyListeners();
      }
    } else if (type == 'new_post') {
      final post = CommunityPost.fromJson(payload);
      _posts.insert(0, post);
      
      if (_currentLang != null) {
        _translatePost(0, _currentLang!);
      } else {
        notifyListeners();
      }
      
      NotificationService.showCommunityNotification(
        id: post.id.hashCode,
        title: 'New Community Post',
        body: '${post.author}: ${post.content}',
      );
    } else if (type == 'new_comment') {
      final postId = payload['post_id'];
      final comment = CommunityComment.fromJson(payload['comment']);
      
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final newComments = List<CommunityComment>.from(post.comments)..add(comment);
        _posts[postIndex] = post.copyWith(comments: newComments);
        
        if (_currentLang != null) {
          _translateComment(postIndex, newComments.length - 1, _currentLang!);
        } else {
          notifyListeners();
        }
      }
    } else if (type == 'update_likes') {
      final postId = payload['post_id'];
      final likes = List<String>.from(payload['likes']);
      
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        _posts[postIndex] = _posts[postIndex].copyWith(likes: likes);
        notifyListeners();
      }
    }
  }

  Future<void> translatePosts(String lang) async {
    if (lang == 'en' || lang == _currentLang) return;
    _currentLang = lang;

    for (int i = 0; i < _posts.length; i++) {
      _translatePost(i, lang);
    }
  }

  Future<void> _translatePost(int index, String lang) async {
    if (index >= _posts.length) return;
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
      if (index < _posts.length) {
        _posts[index] = _posts[index].copyWith(
          translatedContent: transContent,
          translatedLocation: transLoc,
        );
        notifyListeners();
      }
    }

    // Also translate comments
    if (index < _posts.length) {
      for (int j = 0; j < _posts[index].comments.length; j++) {
        _translateComment(index, j, lang);
      }
    }
  }

  Future<void> _translateComment(int postIndex, int commentIndex, String lang) async {
    if (postIndex >= _posts.length || commentIndex >= _posts[postIndex].comments.length) return;
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
      if (postIndex < _posts.length && commentIndex < _posts[postIndex].comments.length) {
        final List<CommunityComment> newComments = List.from(_posts[postIndex].comments);
        newComments[commentIndex] = newComments[commentIndex].copyWith(translatedContent: transContent);
        _posts[postIndex] = _posts[postIndex].copyWith(comments: newComments);
        notifyListeners();
      }
    }
  }

  void addPost(String author, String location, String content, String avatar) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'new_post',
        'author': author,
        'location': location,
        'content': content,
        'avatar': avatar,
      }));
    }
  }

  void toggleLike(String postId, String userId) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'toggle_like',
        'post_id': postId,
        'user_id': userId,
      }));
    }
  }

  void addComment(String postId, String author, String content) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': 'add_comment',
        'post_id': postId,
        'author': author,
        'content': content,
      }));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
