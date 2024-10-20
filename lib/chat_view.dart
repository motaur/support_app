import 'package:chatview/chatview.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ChatViewPage extends StatefulWidget {
  const ChatViewPage({super.key});

  @override
  State<ChatViewPage> createState() => _ChatViewPageState();
}

class _ChatViewPageState extends State<ChatViewPage> {
  List<Message> _messages = [];
  final String apiUrl = 'http://localhost:3000/chat'; // Your API endpoint

  // Define the assistant user
  final ChatUser _assistant = ChatUser(
    id: 'assistant',
    name: 'AI Assistant',
    // avatar: 'http://localhost:3000/avatar', // Replace with your avatar URL
  );

  // Define the current user
  ChatUser _user = ChatUser(
    id: const Uuid().v4(),
    name: 'You',
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
      _user = ChatUser(
        id: const Uuid().v4(),
        name: 'You',
      );
    });
  }

  // Add a new message to the list
  void _addMessage(Message message) {
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

        // Get assistant's response
        final assistantMessage = Message(
          id: const Uuid().v4(),
          message: responseData['response'],
          createdAt: DateTime.now(),
          sentBy: _assistant.id,
        );

        _addMessage(assistantMessage);
      } else {
        throw Exception('Failed to get response from server');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  // Handle sending a message
  void _handleSendPressed(String messageText) {
    final textMessage = Message(
      id: const Uuid().v4(),
      message: messageText,
      createdAt: DateTime.now(),
      sentBy: _user.id,
    );

    // Add user's message to the chat
    _addMessage(textMessage);

    // Send the message to the server
    _sendMessageToServer(messageText);
  }

  void _loadMessages() {
    final messages = <Message>[];
    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startNewChat, // Restart chat
            tooltip: 'Start New Chat',
          ),
        ],
      ),
      body: ChatView(
        replySuggestionsConfig: const ReplySuggestionsConfig(

        ),
        chatBackgroundConfig: const ChatBackgroundConfiguration(
          backgroundColor: Colors.blueGrey,
        ),
        onSendTap: (text, _, __) => _handleSendPressed(text),
        chatController: ChatController(initialMessageList: _messages,
            scrollController: ScrollController(),
            otherUsers: [_assistant],
            currentUser: _user,
        ),
        chatViewState: ChatViewState.hasMessages,
      ),
    );
  }
}
