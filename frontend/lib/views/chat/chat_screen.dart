// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../blocs/auth/auth_bloc.dart';
// import '../../blocs/auth/auth_state.dart';
// import '../../blocs/chat/chat_bloc.dart';
// import '../../blocs/chat/chat_event.dart';
// import '../../blocs/chat/chat_state.dart';
// import '../../models/user_model.dart';
// import '../../models/message_model.dart';
// import '../../services/socket_service.dart';

// class ChatScreen extends StatefulWidget {
//   final User otherUser;

//   const ChatScreen({super.key, required this.otherUser});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   late ChatBloc _chatBloc;
//   bool _isSocketInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _chatBloc = ChatBloc();
//     _initializeSocketAndChat();
//   }

//   Future<void> _initializeSocketAndChat() async {
//     try {
//       // Ensure socket is connected before starting chat
//       print('🔄 Ensuring socket connection...');
//       print('🔍 Debug info: ${SocketService.getDebugInfo()}');
      
//       await SocketService.ensureConnected();
      
//       // Wait a bit for connection to stabilize
//       await Future.delayed(Duration(milliseconds: 800));
      
//       if (SocketService.isConnected) {
//         print('✅ Socket connected, starting chat with ${widget.otherUser.id}');
//         _chatBloc.add(ChatStarted(otherUserId: widget.otherUser.id));
//         _isSocketInitialized = true;
//       } else {
//         print('❌ Socket connection failed');
//         print('🔍 Final debug info: ${SocketService.getDebugInfo()}');
//         // You might want to show an error dialog or retry
//         _showConnectionError();
//       }
//     } catch (e) {
//       print('❌ Error initializing socket: $e');
//       print('🔍 Error debug info: ${SocketService.getDebugInfo()}');
//       _showConnectionError();
//     }
//   }

//   void _showConnectionError() {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Connection failed. Tap to retry.'),
//           backgroundColor: Colors.red,
//           action: SnackBarAction(
//             label: 'Retry',
//             textColor: Colors.white,
//             onPressed: _initializeSocketAndChat,
//           ),
//           duration: Duration(seconds: 5),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _chatBloc.close();
//     super.dispose();
//   }

//   Future<void> _sendMessage() async {
//     final content = _messageController.text.trim();
//     print("📨 _sendMessage called! Content: '$content'");

//     if (content.isNotEmpty) {
//       // Check connection before sending
//       final isConnected = await SocketService.checkConnection();
      
//       if (isConnected) {
//         print("✅ Sending message event to ChatBloc...");
//         _chatBloc.add(ChatMessageSent(content: content));
//         _messageController.clear();
//         _scrollToBottom();
//       } else {
//         print("❌ Cannot send message: Not connected");
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text('Not connected to server. Reconnecting...'),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         }
//         // Try to reconnect
//         _initializeSocketAndChat();
//       }
//     } else {
//       print("⚠️ Message is empty, not sending.");
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _chatBloc,
//       child: Scaffold(
//         appBar: AppBar(
//           title: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(widget.otherUser.email),
//               BlocBuilder<ChatBloc, ChatState>(
//                 builder: (context, state) {
//                   // Show connection status based on actual socket state
//                   final isConnected = SocketService.isConnected;
//                   return Text(
//                     isConnected ? 'Online' : 'Connecting...',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: isConnected ? Colors.green : Colors.orange,
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//           backgroundColor: Colors.blue,
//           foregroundColor: Colors.white,
//           actions: [
//             // Add refresh button to manually check connection
//             IconButton(
//               icon: Icon(Icons.refresh),
//               onPressed: _initializeSocketAndChat,
//               tooltip: 'Reconnect',
//             ),
//           ],
//         ),
//         body: BlocListener<ChatBloc, ChatState>(
//           listener: (context, state) {
//             if (state.errorMessage != null) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(state.errorMessage!),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//             }
//             // Auto-scroll when new message is added
//             if (state.messages.isNotEmpty) {
//               _scrollToBottom();
//             }
//           },
//           child: Column(
//             children: [
//               // Connection Status Banner
//               BlocBuilder<ChatBloc, ChatState>(
//                 builder: (context, state) {
//                   if (!SocketService.isConnected && _isSocketInitialized) {
//                     return Container(
//                       width: double.infinity,
//                       padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                       color: Colors.orange.shade100,
//                       child: Row(
//                         children: [
//                           Icon(Icons.warning, color: Colors.orange, size: 16),
//                           SizedBox(width: 8),
//                           Text(
//                             'Connection lost. Messages may not be delivered.',
//                             style: TextStyle(
//                               color: Colors.orange.shade800,
//                               fontSize: 12,
//                             ),
//                           ),
//                           Spacer(),
//                           TextButton(
//                             onPressed: _initializeSocketAndChat,
//                             child: Text('Reconnect', style: TextStyle(fontSize: 12)),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//                   return SizedBox.shrink();
//                 },
//               ),

//               // Messages List
//               Expanded(
//                 child: BlocBuilder<ChatBloc, ChatState>(
//                   builder: (context, state) {
//                     if (state.isLoadingHistory) {
//                       return const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             CircularProgressIndicator(),
//                             SizedBox(height: 16),
//                             Text('Loading chat history...')
//                           ],
//                         ),
//                       );
//                     }

//                     if (state.messages.isEmpty) {
//                       return const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.chat_bubble_outline,
//                               size: 64,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'No messages yet. Start the conversation!',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }

//                     return ListView.builder(
//                       controller: _scrollController,
//                       padding: const EdgeInsets.all(16),
//                       itemCount: state.messages.length,
//                       itemBuilder: (context, index) {
//                         final message = state.messages[index];
//                         return _buildMessageBubble(message);
//                       },
//                     );
//                   },
//                 ),
//               ),

//               // Message Input
//               _buildMessageInput(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageBubble(Message message) {
//     return BlocBuilder<AuthBloc, AuthState>(
//       builder: (context, authState) {
//         final isMe = message.senderId == authState.user?.id;
        
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 4),
//           child: Row(
//             mainAxisAlignment:
//                 isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               if (!isMe) ...[
//                 CircleAvatar(
//                   radius: 16,
//                   backgroundColor: Colors.grey,
//                   child: Text(
//                     widget.otherUser.email.substring(0, 1).toUpperCase(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//               ],
//               Flexible(
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: isMe ? Colors.blue : Colors.grey[300],
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         message.content,
//                         style: TextStyle(
//                           color: isMe ? Colors.white : Colors.black87,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _formatTime(message.timestamp),
//                         style: TextStyle(
//                           color: isMe ? Colors.white70 : Colors.black54,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               if (isMe) ...[
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 16,
//                   backgroundColor: Colors.blue,
//                   child: Text(
//                     authState.user?.email?.substring(0, 1).toUpperCase() ?? 'U',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             offset: const Offset(0, -2),
//             blurRadius: 4,
//             color: Colors.black.withOpacity(0.1),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 20,
//                   vertical: 10,
//                 ),
//               ),
//               maxLines: null,
//               textInputAction: TextInputAction.send,
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           FloatingActionButton(
//             mini: true,
//             onPressed: _sendMessage,
//             backgroundColor: SocketService.isConnected ? Colors.blue : Colors.orange,
//             child: const Icon(
//               Icons.send,
//               color: Colors.white,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final today = DateTime(now.year, now.month, now.day);
//     final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

//     if (messageDate == today) {
//       // Today - show time only
//       return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//     } else {
//       // Other days - show date and time
//       return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//     }
//   }
// }



import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/chat/chat_bloc.dart';
import '../../blocs/chat/chat_event.dart';
import '../../blocs/chat/chat_state.dart';
import '../../models/user_model.dart';
import '../../models/message_model.dart';
import '../../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final User otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;
  bool _isSocketInitialized = false;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc();
    _initializeSocketAndChat();
  }

  Future<void> _initializeSocketAndChat() async {
    try {
      print('🔄 Ensuring socket connection...');
      print('🔍 Debug info: ${SocketService.getDebugInfo()}');

      await SocketService.ensureConnected();
      await Future.delayed(const Duration(milliseconds: 800));

      if (SocketService.isConnected) {
        print('✅ Socket connected, starting chat with ${widget.otherUser.id}');
        _chatBloc.add(ChatStarted(otherUserId: widget.otherUser.id));
        _isSocketInitialized = true;
      } else {
        print('❌ Socket connection failed');
        print('🔍 Final debug info: ${SocketService.getDebugInfo()}');
        _showConnectionError();
      }
    } catch (e) {
      print('❌ Error initializing socket: $e');
      print('🔍 Error debug info: ${SocketService.getDebugInfo()}');
      _showConnectionError();
    }
  }

  void _showConnectionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection failed. Tap to retry.'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _initializeSocketAndChat,
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    print("📨 _sendMessage called! Content: '$content'");

    if (content.isNotEmpty) {
      final isConnected = await SocketService.checkConnection();

      if (isConnected) {
        print("✅ Sending message event to ChatBloc...");
        _chatBloc.add(ChatMessageSent(content: content));
        _messageController.clear();
        _scrollToBottom();
      } else {
        print("❌ Cannot send message: Not connected");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not connected to server. Reconnecting...'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _initializeSocketAndChat();
      }
    } else {
      print("⚠️ Message is empty, not sending.");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUser.email),
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  final isConnected = SocketService.isConnected;
                  return Text(
                    isConnected ? 'Online' : 'Connecting...',
                    style: TextStyle(
                      fontSize: 12,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  );
                },
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initializeSocketAndChat,
              tooltip: 'Reconnect',
            ),
          ],
        ),
        body: BlocListener<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state.messages.isNotEmpty) {
              _scrollToBottom();
            }
          },
          child: Column(
            children: [
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (!SocketService.isConnected && _isSocketInitialized) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Colors.orange.shade100,
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Connection lost. Messages may not be delivered.',
                            style: TextStyle(
                              color: Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _initializeSocketAndChat,
                            child: const Text('Reconnect', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Messages List
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, authState) {
                    final myUserId = authState.user?.id;

                    return BlocBuilder<ChatBloc, ChatState>(
                      builder: (context, state) {
                        if (state.isLoadingHistory) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading chat history...')
                              ],
                            ),
                          );
                        }

                        if (state.messages.isEmpty) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No messages yet. Start the conversation!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            return _buildMessageBubble(message, myUserId);
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Message Input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, String? myUserId) {
    final isMe = myUserId != null && message.senderId == myUserId;
    
    print(message);
    print(myUserId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey,
              child: Text(
                widget.otherUser.email.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Text(
                myUserId != null
                    ? myUserId.substring(0, 1).toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            mini: true,
            onPressed: _sendMessage,
            backgroundColor: SocketService.isConnected ? Colors.blue : Colors.orange,
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
