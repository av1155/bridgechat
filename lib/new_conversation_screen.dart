import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import 'chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({Key? key}) : super(key: key);

  @override
  _NewConversationScreenState createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  final User currentUser = FirebaseAuth.instance.currentUser!;

  // Search users by email or username.
  Future<QuerySnapshot> _searchUsers(String query) {
    // For simplicity, this example searches the 'users' collection by username.
    return _firestore
        .collection('users')
        .where('username', isEqualTo: query)
        .get();
  }

  void _startConversationWithUser(String otherUserId) async {
    String conversationId = await _chatService.createOrGetConversation(
      currentUser.uid,
      otherUserId,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversationId: conversationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Conversation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Enter email or username',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final query = _searchController.text.trim();
                if (query.isNotEmpty) {
                  QuerySnapshot snapshot = await _searchUsers(query);
                  if (snapshot.docs.isNotEmpty) {
                    // For now, take the first matching user.
                    final otherUserId = snapshot.docs.first.id;
                    _startConversationWithUser(otherUserId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not found')),
                    );
                  }
                }
              },
              child: const Text('Start Conversation'),
            ),
          ],
        ),
      ),
    );
  }
}
