import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _currentUser != null) {
      final user = _currentUser;
      await _chatService.sendMessage(
        widget.conversationId,
        _messageController.text.trim(),
        user!.uid,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('User not authenticated.')),
      );
    }

    // Responsive logic
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat', style: TextStyle(fontSize: isMobile ? 18 : 20)),
      ),
      body: Center(
        child: ConstrainedBox(
          // Limit width on bigger screens so text isn’t super wide
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              // Expanded area for messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessages(widget.conversationId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }
                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final data =
                            messages[index].data() as Map<String, dynamic>;
                        final text = data['text'] ?? '';
                        final senderId = data['senderId'] ?? 'Unknown';
                        return MessageBubble(
                          text: text,
                          senderId: senderId,
                          currentUserId: _currentUser!.uid,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Input row at bottom
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                        decoration: const InputDecoration(
                          labelText: 'Enter message',
                        ),
                      ),
                    ),
                    // Send button
                    IconButton(
                      icon: Icon(Icons.send, size: isMobile ? 20 : 24),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
