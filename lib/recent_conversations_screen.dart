import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class RecentConversationsScreen extends StatelessWidget {
  RecentConversationsScreen({Key? key}) : super(key: key);

  final User currentUser = FirebaseAuth.instance.currentUser!;

  Stream<QuerySnapshot> getRecentConversations() {
    // Print the current user's UID for debugging.
    print("Current User UID: ${currentUser.uid}");
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
      print("Error determining other user: $e");
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
          print(
            "Found ${convos.length} conversations for user ${currentUser.uid}",
          );
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
                  return ListTile(
                    title: Text('Conversation with $displayName'),
                    subtitle: Text(data['lastMessage'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  ChatScreen(conversationId: convos[index].id),
                        ),
                      );
                    },
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
