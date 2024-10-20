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
import 'package:uuid/uuid.dart';

class FlutterChatUiPage extends StatefulWidget {
  const FlutterChatUiPage({super.key});

  @override
  State<FlutterChatUiPage> createState() => _FlutterChatUiPageState();
}

class _FlutterChatUiPageState extends State<FlutterChatUiPage> {
  List<types.Message> _messages = [];
  types.User _user = types.User(id: const Uuid().v4(), role: types.Role.user, firstName: 'You');
  final String apiUrl = 'https://support-backend-test.onrender.com/chat';
      // 'http://localhost:3000/chat';

  final types.User _assistant = const types.User(
      id: 'assistant',
      firstName: 'AI Assistant',
      imageUrl: 'https://support-backend-test.onrender.com/avatar',
      role: types.Role.agent
  );

  // Suggested questions for the user to ask
  final List<String> _suggestedQuestions = [
    'I have a problem with camera',
    'How to Bulk delete data',
  ];



  // New variable to track if the first message has been sent
  bool _firstMessageSent = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _startNewChat() {
    setState(() {
      _suggestedQuestions.clear();
      _suggestedQuestions.addAll(_suggestedQuestions);
      _messages = [];
      _user = types.User(id: const Uuid().v4(), role: types.Role.user, firstName: 'You');
      _firstMessageSent = false; // Resetting the message status
    });
  }

  void _addMessage(types.Message message, {String? suggestedQuestions}) {
    setState(() {
      _messages.insert(0, message);
      // Mark that the first message has been sent
      if (!_firstMessageSent) {
        _firstMessageSent = true;
      }

      _suggestedQuestions.clear();
      if (suggestedQuestions != null) {
        _suggestedQuestions.add(suggestedQuestions);
      }
    });
  }

  Future<void> _sendMessageToServer(String message) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': '3000'
        },
        body: jsonEncode({
          'userId': _user.id,
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final assistantMessage = types.TextMessage(
          author: _assistant,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: responseData['response'],
        );

        _addMessage(assistantMessage, suggestedQuestions: responseData['suggestions']);

      } else {
        throw Exception('Failed to get response from server');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  void _handlePreviewDataFetched(types.TextMessage message, types.PreviewData previewData) {
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

    _addMessage(textMessage);
    _sendMessageToServer(message.text);
  }

  void _loadMessages() async {
    final messages = <types.Message>[];
    setState(() {
      _messages = messages..add(types.TextMessage(author: _assistant, id: '0', type: types.MessageType.text, text: '''
        Hi there! 👋
        How can I help you today?
      '''));
    });
  }

  // Method to handle sending a suggested question
  void _handleSuggestedQuestion(String question) {
    _handleSendPressed(types.PartialText(text: question));
  }

  @override
  Widget build(BuildContext context) =>
      Directionality(
      textDirection: TextDirection.rtl,
      child:
      Scaffold(
    appBar: AppBar(
      // title: const Text('Chat'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _startNewChat,
          tooltip: 'Start New Chat',
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: Chat(
            messages: _messages,
            onPreviewDataFetched: _handlePreviewDataFetched,
            onSendPressed: _handleSendPressed,
            showUserAvatars: true,
            showUserNames: true,
            user: _user,
          ),
        ),
        // if (!_firstMessageSent) // Only show suggested questions if the first message hasn't been sent
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _handleSuggestedQuestion(question),
                    child: Text(question),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  ));
}
