import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatefulWidget {
  final String senderId;
  final String currentUserId;
  final String originalText;
  final String translatedText;
  final DateTime timestamp;

  const MessageBubble({
    Key? key,
    required this.senderId,
    required this.currentUserId,
    required this.originalText,
    required this.translatedText,
    required this.timestamp,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late bool _showOriginal; // We'll set this in initState based on who sent it

  @override
  void initState() {
    super.initState();
    final bool isMe = (widget.senderId == widget.currentUserId);
    // If I'm the sender, default = original text
    // If I'm the recipient, default = translated text
    _showOriginal = isMe;
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = (widget.senderId == widget.currentUserId);
    final timeString = DateFormat('h:mm a').format(widget.timestamp);

    // If the text is identical, toggling is pointless
    final bool hasDifferentTranslation =
        widget.originalText != widget.translatedText &&
        widget.translatedText.isNotEmpty;

    final String displayText =
        _showOriginal ? widget.originalText : widget.translatedText;

    // Bubble alignment: right if isMe, left if not
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final crossAxis = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMe ? const Color(0xFF4A90E2) : Colors.grey.shade200;
    final textColor = isMe ? Colors.white : Colors.black87;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: bubbleColor,
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
            crossAxisAlignment: crossAxis,
            children: [
              Text(
                displayText,
                style: TextStyle(color: textColor, fontSize: 16),
                textAlign: isMe ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 4),
              Text(
                timeString,
                style: TextStyle(
                  color: isMe ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
                textAlign: isMe ? TextAlign.right : TextAlign.left,
              ),
              // Show a toggle only if there's a different translation
              if (hasDifferentTranslation)
                Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _showOriginal = !_showOriginal);
                    },
                    child: Text(
                      _showOriginal ? 'View Translated' : 'View Original',
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
