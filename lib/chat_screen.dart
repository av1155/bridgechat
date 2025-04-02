import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

  bool _isUserScrolling = false;
  Timer? _scrollDebounce;
  String _pinnedDayString =
      ''; // The date string displayed in the pinned bubble

  // We'll store a processed list of messages (with date checks)
  List<Map<String, dynamic>> _msgList = [];

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // The user is scrolling, show the pinned day bubble
    setState(() {
      _isUserScrolling = true;
    });

    // Cancel existing debounce and set a new one to hide bubble after 1.5s
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _isUserScrolling = false;
      });
    });

    // Figure out the top visible item and update _pinnedDayString
    _updatePinnedDate();
  }

  void _updatePinnedDate() {
    if (_msgList.isEmpty) return;

    // Approx approach: get offset, estimate top item index
    // We'll assume ~80px average item height.
    final offset = _scrollController.offset;
    final itemHeight = 80.0;
    final firstVisibleIndex = (offset / itemHeight).floor();

    if (firstVisibleIndex >= 0 && firstVisibleIndex < _msgList.length) {
      final msg = _msgList[firstVisibleIndex];
      final DateTime dateTime = msg['timestamp'];
      final newDayString = DateFormat('EEEE').format(dateTime); // e.g. "Monday"

      if (newDayString != _pinnedDayString) {
        setState(() {
          _pinnedDayString = newDayString;
        });
      }
    }
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
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 1,
              maxLines: 5,
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

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('User not authenticated.')),
      );
    }

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Main Column
            Column(
              children: [
                _buildHeader(isMobile),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _chatService.getMessages(widget.conversationId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }

                      // Convert messages to local list
                      _msgList =
                          docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final text = data['text'] ?? '';
                            final senderId = data['senderId'] ?? '';
                            final ts = data['timestamp'] as Timestamp?;
                            final dateTime = ts?.toDate() ?? DateTime.now();
                            return {
                              'text': text,
                              'senderId': senderId,
                              'timestamp': dateTime,
                            };
                          }).toList();

                      // Build the ListView with day grouping
                      return _buildMessagesList();
                    },
                  ),
                ),
                const Divider(height: 1),
                _buildMessageInput(isMobile),
              ],
            ),

            // The pinned date bubble at top center
            if (_isUserScrolling && _pinnedDayString.isNotEmpty)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _pinnedDayString,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _msgList.length,
      itemBuilder: (context, index) {
        final current = _msgList[index];
        final text = current['text'];
        final senderId = current['senderId'];
        final DateTime dt = current['timestamp'];
        final dateOnly = DateTime(dt.year, dt.month, dt.day);

        // Compare with previous
        DateTime? previousDate;
        if (index > 0) {
          final prev = _msgList[index - 1];
          final prevDt = prev['timestamp'] as DateTime;
          previousDate = DateTime(prevDt.year, prevDt.month, prevDt.day);
        }

        bool isNewDay = false;
        if (previousDate == null || dateOnly.compareTo(previousDate) != 0) {
          isNewDay = true;
        }

        List<Widget> children = [];
        // If it's a new day, show a day marker
        if (isNewDay) {
          children.add(_buildDayMarker(dt));
        }

        // The message bubble
        children.add(
          MessageBubble(
            text: text,
            senderId: senderId,
            currentUserId: _currentUser!.uid,
            timestamp:
                dt, // We'll pass the DateTime so the bubble can show the time
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Widget _buildDayMarker(DateTime date) {
    // Example: "Monday" or "Mar 14, 2025"
    final dayString = DateFormat('EEEE').format(date); // e.g. "Monday"
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Text(
            dayString,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
