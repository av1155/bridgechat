import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_service.dart';
import 'message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserName,
  }) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isNotEmpty && _currentUser != null) {
      await _chatService.sendMessage(
        widget.conversationId,
        _messageController.text.trim(),
        _currentUser!.uid,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated.')),
      );
    }

    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                // Top "AppBar" row
                _buildHeader(isMobile),
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

                      // Scroll to bottom once the messages load
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
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
                _buildMessageInput(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              // Multi-line input:
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5, // The TextField will grow up to 5 lines
              decoration: const InputDecoration(labelText: 'Enter message'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, size: isMobile ? 20 : 24),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
