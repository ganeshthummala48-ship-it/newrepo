import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box? notifBox = Hive.isBoxOpen('notificationsBox')
        ? Hive.box('notificationsBox')
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Alerts'),
        actions: [
          if (notifBox != null && notifBox.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear Notifications',
              onPressed: () => notifBox.clear(),
            ),
        ],
      ),
      body: notifBox == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: notifBox.listenable(),
              builder: (context, Box box, _) {
                final items = box.values.toList().reversed.toList();

                if (items.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final raw = items[index];
                    final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                    return _buildNotificationCard(data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Community posts, comments & contract updates will appear here in real time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Notice';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'community';
    final rawTs = data['timestamp'];

    String timeString = 'Just now';
    if (rawTs != null) {
      try {
        final dt = DateTime.parse(rawTs.toString());
        timeString = DateFormat('MMM d, hh:mm a').format(dt);
      } catch (_) {}
    }

    IconData icon = Icons.notifications_active_rounded;
    Color iconColor = AppConstants.primaryColor;

    if (type == 'community') {
      icon = Icons.forum_rounded;
      iconColor = Colors.teal;
    } else if (type == 'contract') {
      icon = Icons.assignment_turned_in_rounded;
      iconColor = Colors.orange.shade700;
    } else if (type == 'risk') {
      icon = Icons.warning_amber_rounded;
      iconColor = Colors.red.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              body,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5),
            ),
            const SizedBox(height: 6),
            Text(
              timeString,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
