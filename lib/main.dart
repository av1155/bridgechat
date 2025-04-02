import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'recent_conversations_screen.dart';
import 'new_conversation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgeChat',
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/recentConversations': (context) => RecentConversationsScreen(),
        '/newConversation': (context) => const NewConversationScreen(),
      },
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
