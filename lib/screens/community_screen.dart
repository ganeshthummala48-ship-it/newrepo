import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/community_post.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import '../widgets/voice_wrapper.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate a real-time incoming post for demonstration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CommunityProvider>(context, listen: false).simulateIncomingPost();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.farmersCommunity),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Simple visual refresh
            },
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, child) {
          final lang = Provider.of<LocaleProvider>(context).locale.languageCode;
          provider.translatePosts(lang);
          final posts = provider.posts;
          return VoiceWrapper(
            screenTitle: 'Community',
            textToRead: "Welcome to the farmer community. There are ${posts.length} recent discussions. " + 
              (posts.isNotEmpty ? "Latest post from ${posts.first.author} in ${posts.first.location} says: ${posts.first.content}" : ""),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(post: post);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreatePostSheet(context);
        },
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  void _showCreatePostSheet(BuildContext context) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a Post',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share your thoughts, tips, or ask for advice...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    Provider.of<CommunityProvider>(context, listen: false).addPost(
                      'You',
                      'Your Farm',
                      textController.text,
                      'U',
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post shared with the community!')),
                    );
                  }
                },
                child: const Text('Post'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final isLiked = post.likes.contains('currentUser'); // Mock user ID

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  child: Text(
                    post.avatar,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${post.translatedLocation ?? post.location} • ${DateFormat('jm').format(post.timestamp)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              post.translatedContent ?? post.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                  '${post.likes.length} Likes',
                  isLiked ? AppConstants.primaryColor : Colors.grey.shade700,
                  () {
                    Provider.of<CommunityProvider>(context, listen: false)
                        .toggleLike(post.id, 'currentUser');
                  },
                ),
                _buildActionButton(
                  Icons.comment_outlined,
                  '${post.comments.length} Comments',
                  Colors.grey.shade700,
                  () {
                    _showCommentDialog(context);
                  },
                ),
                _buildActionButton(
                  Icons.share_outlined,
                  'Share',
                  Colors.grey.shade700,
                  () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(icon, key: ValueKey(icon.codePoint), size: 20, color: color),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentDialog(BuildContext context) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comments'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: post.comments.length,
                  itemBuilder: (context, i) {
                    final comment = post.comments[i];
                    return ListTile(
                      title: Text(comment.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.translatedContent ?? comment.content),
                      trailing: Text(DateFormat('jm').format(comment.timestamp), style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
              ),
              const Divider(),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(hintText: 'Add a comment...'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                Provider.of<CommunityProvider>(context, listen: false)
                    .addComment(post.id, 'You', commentController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Comment'),
          ),
        ],
      ),
    );
  }
}

