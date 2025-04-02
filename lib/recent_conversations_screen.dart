import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'chat_service.dart';

class RecentConversationsScreen extends StatelessWidget {
  RecentConversationsScreen({super.key});

  final User currentUser = FirebaseAuth.instance.currentUser!;
  final ChatService _chatService = ChatService();

  Stream<QuerySnapshot> getRecentConversations() {
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  String _getOtherUserId(List<dynamic> participants) {
    try {
      return participants.firstWhere((id) => id != currentUser.uid);
    } catch (e) {
      return "Unknown";
    }
  }

  // NEW: Show a confirmation dialog for deleting the conversation
  void _confirmDeleteConversation(
    BuildContext context,
    String conversationId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Conversation'),
            content: const Text(
              'Are you sure you want to delete this conversation for yourself? '
              'All your messages will be removed. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      // Call our chat service to delete conversation for the current user
      await _chatService.deleteConversationForUser(
        conversationId,
        currentUser.uid,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Conversation deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recent Conversations',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/newConversation');
            },
          ),
          // 3) NEW: The settings cog icon
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: StreamBuilder<QuerySnapshot>(
            stream: getRecentConversations(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No conversations yet.'));
              }
              final convos = snapshot.data!.docs;
              return ListView.builder(
                itemCount: convos.length,
                itemBuilder: (context, index) {
                  final convRef = convos[index];
                  final data = convRef.data() as Map<String, dynamic>;
                  final participants = data['participants'] as List<dynamic>;
                  final otherUserId = _getOtherUserId(participants);

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .get(),
                    builder: (context, userSnapshot) {
                      String displayName = otherUserId;
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        displayName = userSnapshot.data!.get('username');
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(context).colorScheme.secondary,
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : '?',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              'Conversation with $displayName',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            subtitle: Text(
                              data['lastMessage'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatScreen(
                                        conversationId: convRef.id,
                                        otherUserName: displayName,
                                      ),
                                ),
                              );
                            },
                            // NEW: The 3-dot icon for conversation actions
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDeleteConversation(
                                    context,
                                    convRef.id,
                                  );
                                }
                              },
                              itemBuilder:
                                  (ctx) => [
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Conversation'),
                                    ),
                                  ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
