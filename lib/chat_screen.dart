import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'utils/languages.dart';
import 'secrets.dart';

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

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final User _currentUser = FirebaseAuth.instance.currentUser!;

  bool _autoScrollAllowed = true;
  String _pinnedDayString = '';
  Timer? _scrollDebounce;

  String? _otherUserId;
  String _otherUserLanguage = 'English';
  String _myLanguage = 'English';
  List<Map<String, dynamic>> _msgList = [];

  bool _isInitialLoad = true;
  bool _shouldShowLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _fetchParticipantsAndLanguages().then((_) {
      if (mounted)
        setState(() {
          _isInitialLoad = false;
        });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Keyboard opened or closed
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _fetchParticipantsAndLanguages() async {
    final myUid = _currentUser.uid;

    final convDoc =
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(widget.conversationId)
            .get();
    if (!convDoc.exists) return;

    final data = convDoc.data();
    if (data == null) return;

    final participants = data['participants'] as List<dynamic>? ?? [];
    for (String uid in participants.cast<String>()) {
      if (uid != myUid) {
        _otherUserId = uid;
        break;
      }
    }
    if (_otherUserId == null) return;

    final otherDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_otherUserId!)
            .get();
    if (otherDoc.exists) {
      _otherUserLanguage =
          (otherDoc.data()?['preferredLanguage'] ?? 'English') as String;
    }

    final myDoc =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    if (myDoc.exists) {
      _myLanguage = (myDoc.data()?['preferredLanguage'] ?? 'English') as String;
    }
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection !=
        ScrollDirection.idle) {
      _autoScrollAllowed = false;
    }
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 200), () {
      _updatePinnedDate();
    });
  }

  void _updatePinnedDate() {
    if (_msgList.isEmpty) {
      setState(() => _pinnedDayString = '');
      return;
    }
    final offset = _scrollController.offset;
    final itemHeight = 80.0;
    final firstVisibleIndex = (offset / itemHeight).floor();

    if (firstVisibleIndex < 0 || firstVisibleIndex >= _msgList.length) return;

    final msg = _msgList[firstVisibleIndex];
    final dt = msg['timestamp'] as DateTime;
    final dayStr = DateFormat('EEEE').format(dt);

    if (dayStr != _pinnedDayString) {
      setState(() => _pinnedDayString = dayStr);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    _autoScrollAllowed = true;

    final myUid = _currentUser.uid;

    final myDoc =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    if (myDoc.exists) {
      _myLanguage = (myDoc.data()?['preferredLanguage'] ?? 'English') as String;
    }

    if (_otherUserId != null) {
      final otherDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_otherUserId!)
              .get();
      if (otherDoc.exists) {
        _otherUserLanguage =
            (otherDoc.data()?['preferredLanguage'] ?? 'English') as String;
      }
    }

    final originalText = text;
    String translatedText = text;

    if (_myLanguage.toLowerCase() != _otherUserLanguage.toLowerCase()) {
      translatedText = await _translateText(
        text,
        sourceLang: _langToIso(_myLanguage),
        targetLang: _langToIso(_otherUserLanguage),
      );
    }

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .collection('messages')
        .add({
          'senderId': _currentUser.uid,
          'originalText': originalText,
          'translatedText': translatedText,
          'timestamp': FieldValue.serverTimestamp(),
          'sourceLang': _langToIso(_myLanguage),
          'targetLang': _langToIso(_otherUserLanguage),
        });

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(widget.conversationId)
        .update({
          'lastMessage': originalText,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<String> _translateText(
    String text, {
    required String sourceLang,
    required String targetLang,
  }) async {
    final uri = Uri.parse('$kTranslateApiUrl/translate');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'q': text,
          'source': sourceLang,
          'target': targetLang,
        }),
      );
      if (response.statusCode == 200) {
        final raw = utf8.decode(response.bodyBytes);
        final data = jsonDecode(raw) as Map<String, dynamic>;
        return data['translatedText'] ?? text;
      }
    } catch (e) {
      debugPrint('Translation error: $e');
    }
    return text;
  }

  String _langToIso(String lang) {
    return supportedLanguages[lang] ?? 'en';
  }

  void _scrollToBottom() {
    if (!_autoScrollAllowed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child:
            _isInitialLoad
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMessagesStream(),
                          if (_pinnedDayString.isNotEmpty)
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
                    _buildMessageInput(),
                  ],
                ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.otherUserName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('conversations')
              .doc(widget.conversationId)
              .collection('messages')
              .orderBy('timestamp', descending: false)
              .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No messages yet.'));
        }

        _msgList =
            docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final senderId = data['senderId'] ?? '';
              final originalText = data['originalText'] ?? '';
              final translatedText = data['translatedText'] ?? '';
              final ts = data['timestamp'] as Timestamp?;
              final dt = ts?.toDate() ?? DateTime.now();
              return {
                'senderId': senderId,
                'originalText': originalText,
                'translatedText': translatedText,
                'timestamp': dt,
                'sourceLang': data['sourceLang'] ?? 'en',
                'targetLang': data['targetLang'] ?? 'en',
              };
            }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _msgList.length,
          itemBuilder: (ctx, index) {
            final msg = _msgList[index];
            final senderId = msg['senderId'] as String;
            final originalText = msg['originalText'] as String;
            final translatedText = msg['translatedText'] as String;
            final dt = msg['timestamp'] as DateTime;

            Widget? dayMarker;
            if (index == 0) {
              dayMarker = _buildDayMarker(dt);
            } else {
              final prevDt = _msgList[index - 1]['timestamp'] as DateTime;
              final isNewDay =
                  dt.year != prevDt.year ||
                  dt.month != prevDt.month ||
                  dt.day != prevDt.day;
              if (isNewDay) {
                dayMarker = _buildDayMarker(dt);
              }
            }

            final sourceLang = msg['sourceLang'] as String?;
            final targetLang = msg['targetLang'] as String?;

            final bubble = MessageBubble(
              senderId: senderId,
              currentUserId: _currentUser.uid,
              originalText: originalText,
              translatedText: translatedText,
              timestamp: dt,
              sourceLang: sourceLang,
              targetLang: targetLang,
            );

            if (dayMarker != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [dayMarker, bubble],
              );
            } else {
              return bubble;
            }
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Enter message'),
              onTap: _scrollToBottom,
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  Widget _buildDayMarker(DateTime date) {
    final dayString = DateFormat('EEEE, MMM d').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dayString,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
