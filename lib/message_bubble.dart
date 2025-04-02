import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final bool isMe = senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        // Limit max bubble width (70% of screen, for example)
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF4A90E2) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
