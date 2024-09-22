import 'package:flutter/material.dart';
import 'flutter_chat_ui_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('he_IL'),
      title: 'smart_agent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FlutterChatUiPage()
      // const ChatViewPage(title: 'Flutter Demo Home Page'),
    );
  }
}


