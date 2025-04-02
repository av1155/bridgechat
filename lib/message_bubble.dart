import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String senderId;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.text,
    required this.senderId,
    required this.currentUserId,
  });

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
            margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF4A90E2) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                // Instead of using withOpacity(0.05), we use a constant color with an alpha value of 0x0D (≈5% opacity).
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  senderName,
                  style: TextStyle(
                    fontSize: 12,
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
