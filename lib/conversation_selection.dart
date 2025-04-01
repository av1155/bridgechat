import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import 'chat_screen.dart';

class ConversationSelection extends StatelessWidget {
  final User currentUser = FirebaseAuth.instance.currentUser!;
  final ChatService _chatService = ChatService();

  // For demonstration, we query the 'users' collection.
  // In your implementation, make sure each user document includes a 'username' field.
  Stream<QuerySnapshot> getUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots();
  }

  Future<void> _startConversation(
    BuildContext context,
    String otherUserId,
  ) async {
    // Create or get an existing conversation.
    String conversationId = await _chatService.createOrGetConversation(
      currentUser.uid,
      otherUserId,
    );
    // Navigate to the chat screen with the conversation ID.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a User')),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;
              // Exclude the current user from the list.
              if (userId == currentUser.uid) return const SizedBox.shrink();
              final username = data['username'] ?? 'No Name';
              return ListTile(
                title: Text(username),
                onTap: () => _startConversation(context, userId),
              );
            },
          );
        },
      ),
    );
  }
}
