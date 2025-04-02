import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String senderId;
  final String currentUserId;

  const MessageBubble({
    Key? key,
    required this.text,
    required this.senderId,
    required this.currentUserId,
  }) : super(key: key);

  Future<String> _getSenderUsername() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
    return doc.exists ? doc.get('username') : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    bool isMe = senderId == currentUserId;
    return FutureBuilder<String>(
      future: _getSenderUsername(),
      builder: (context, snapshot) {
        String senderName = snapshot.data ?? 'Loading...';
        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 4.0),
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: isMe ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
