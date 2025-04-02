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

  Future<QuerySnapshot> _searchUsers(String query) {
    // For simplicity, searches 'users' collection by username
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
    // Responsive logic
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Conversation',
          style: TextStyle(fontSize: isMobile ? 18 : 20),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: isMobile ? 14 : 16),
                  decoration: InputDecoration(
                    labelText: 'Enter username',
                    labelStyle: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    final query = _searchController.text.trim();
                    if (query.isNotEmpty) {
                      final snapshot = await _searchUsers(query);
                      if (snapshot.docs.isNotEmpty) {
                        final otherUserId = snapshot.docs.first.id;
                        _startConversationWithUser(otherUserId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User not found')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 24,
                      vertical: isMobile ? 12 : 16,
                    ),
                  ),
                  child: Text(
                    'Start Conversation',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
