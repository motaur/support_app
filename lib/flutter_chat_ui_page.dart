import 'package:chatview/chatview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FlutterChatUiPage extends StatefulWidget {
  const FlutterChatUiPage({super.key});

  @override
  State<FlutterChatUiPage> createState() => _FlutterChatUiPageState();
}

class _FlutterChatUiPageState extends State<FlutterChatUiPage> {
  List<types.Message> _messages = [];
  types.User _user = types.User(id: const Uuid().v4(), role: types.Role.user, firstName: 'You'); // User ID
  final String apiUrl = 'http://localhost:3000/chat'; // Your API endpoint

  // Define the assistant user with an avatar
  final types.User _assistant = const types.User(
    id: 'assistant',
    firstName: 'AI Assistant',
    // imageUrl: 'http://localhost:3000/avatar',
    role: types.Role.agent// Replace with your avatar URL
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  // Method to start a new chat, clears messages and generates a new user
  void _startNewChat() {
    setState(() {
      _messages = [];
      _user = types.User(id: const Uuid().v4(), role: types.Role.user, firstName: 'You'); // Generate new user ID
    });
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  // Send the message to the server and get a response
  Future<void> _sendMessageToServer(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': _user.id,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the server response
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Get assistant response
        final assistantMessage = types.TextMessage(
          author: _assistant, // Assign the assistant user with avatar
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: responseData['response'],
        );

        _addMessage(assistantMessage);
      } else {
        throw Exception('Failed to get response from server');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _handlePreviewDataFetched(
      types.TextMessage message,
      types.PreviewData previewData,
      ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    // Add user's message to the chat
    _addMessage(textMessage);

    // Send the message to the server and get a response
    _sendMessageToServer(message.text);
  }

  void _loadMessages() async {
    final messages = <types.Message>[];
    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Chat'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _startNewChat, // Call the method to start a new chat
          tooltip: 'Start New Chat',
        ),
      ],
    ),
    body: Chat(
      messages: _messages,
      onPreviewDataFetched: _handlePreviewDataFetched,
      onSendPressed: _handleSendPressed,
      showUserAvatars: true,
      showUserNames: true,
      user: _user,
    ),
  );
}
