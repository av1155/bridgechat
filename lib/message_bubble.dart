import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String text;
  final String senderId;
  final String currentUserId;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.text,
    required this.senderId,
    required this.currentUserId,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = senderId == currentUserId;

    // Format the time in AM/PM, e.g. "1:45 PM"
    final timeString = DateFormat('h:mm a').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          padding: const EdgeInsets.all(12.0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // The message text
              Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              // The time, right-aligned
              Text(
                timeString,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
