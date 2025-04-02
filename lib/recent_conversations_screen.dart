import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class RecentConversationsScreen extends StatelessWidget {
  RecentConversationsScreen({super.key});

  final User currentUser = FirebaseAuth.instance.currentUser!;

  Stream<QuerySnapshot> getRecentConversations() {
    // Return conversations where the current user is a participant.
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Helper to get the other user's ID from a conversation.
  String _getOtherUserId(List<dynamic> participants) {
    try {
      return participants.firstWhere((id) => id != currentUser.uid);
    } catch (e) {
      return "Unknown";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/newConversation');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getRecentConversations(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No data available.'));
          }
          final convos = snapshot.data!.docs;
          if (convos.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.builder(
            itemCount: convos.length,
            itemBuilder: (context, index) {
              final data = convos[index].data() as Map<String, dynamic>;
              final participants = data['participants'] as List<dynamic>;
              final otherUserId = _getOtherUserId(participants);
              // Use a FutureBuilder to fetch and display the other user's username.
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
                                ? displayName.substring(0, 1).toUpperCase()
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
                                    conversationId: convos[index].id,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
