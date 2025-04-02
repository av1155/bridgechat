import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'auth_screen.dart';
import 'recent_conversations_screen.dart';
import 'new_conversation_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Check if someone is already logged in.
  final User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(MyApp(isLoggedIn: currentUser != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BridgeChat',
      // If user is logged in, jump straight to recent conversations; else, show Home/Auth.
      initialRoute: isLoggedIn ? '/recentConversations' : '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/auth': (context) {
          final bool? isSignUp =
              ModalRoute.of(context)?.settings.arguments as bool?;
          return AuthScreen(isSignUp: isSignUp ?? false);
        },
        '/recentConversations': (context) => RecentConversationsScreen(),
        '/newConversation': (context) => const NewConversationScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF4A90E2),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
        ).copyWith(secondary: const Color(0xFF50E3C2)),
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          bodyMedium: TextStyle(fontFamily: 'OpenSans', fontSize: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.black54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFF4A90E2), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }
}
