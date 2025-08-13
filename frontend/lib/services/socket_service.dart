import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message_model.dart';
import 'auth_service.dart';

class SocketService {
  static io.Socket? _socket;
  static bool _isConnected = false;
  static bool _isConnecting = false;
  static String? _currentUserToken;
  
  // Update this URL based on your setup:
  // For Android Emulator: 'http://10.0.2.2:3000'
  // For iOS Simulator: 'http://localhost:3000'  
  // For Real Device: 'http://YOUR_COMPUTER_IP:3000'
  static const String serverUrl = 'http://192.168.1.50:3000';
  
  // Callbacks
  static Function(Message)? onMessageReceived;
  static Function(Message)? onMessageSent;
  static Function(List<Message>)? onChatHistory;
  static Function(bool)? onConnectionStatusChanged;
  static Function(String)? onError;

  static bool get isConnected => _isConnected;

  // Method to handle logout - IMPORTANT: Call this when user logs out
  static void handleLogout() {
    print('🚪 Handling logout - disconnecting socket...');
    disconnect();
    _currentUserToken = null;
  }

  // Method to handle login - IMPORTANT: Call this when user logs in
  static Future<void> handleLogin() async {
    print('🔑 Handling login - will connect with new token...');
    // Disconnect any existing connection
    disconnect();
    _currentUserToken = null;
    // New connection will be established when needed
  }

  // Singleton pattern to ensure only one connection with proper auth
  static Future<void> ensureConnected() async {
    try {
      final currentToken = await AuthService.getToken();
      
      if (currentToken == null) {
        print('❌ No auth token found');
        throw Exception('No auth token found');
      }

      // If we have a connection but the token has changed, disconnect first
      if (_isConnected && _socket != null && _currentUserToken != currentToken) {
        print('🔄 Token changed, reconnecting with new user credentials...');
        disconnect();
        await Future.delayed(Duration(milliseconds: 500)); // Wait for cleanup
      }

      if (_isConnected && _socket != null && _currentUserToken == currentToken) {
        print('✅ Socket already connected with correct token');
        return;
      }
      
      if (_isConnecting) {
        print('🔄 Connection in progress, waiting...');
        // Wait for connection to complete
        int attempts = 0;
        while (_isConnecting && attempts < 100) { // Increased timeout
          await Future.delayed(Duration(milliseconds: 100));
          attempts++;
        }
        
        if (!_isConnected) {
          print('⏰ Connection timeout, retrying...');
          _isConnecting = false;
          return await connect();
        }
        return;
      }
      
      await connect();
    } catch (e) {
      print('❌ Error in ensureConnected: $e');
      _isConnecting = false;
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
      rethrow;
    }
  }

  static Future<void> connect() async {
    if (_isConnecting) return;
    
    _isConnecting = true;
    
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        _isConnecting = false;
        throw Exception('No auth token found');
      }

      // Store current token
      _currentUserToken = token;

      // Disconnect existing socket if any
      if (_socket != null) {
        print('🔌 Disconnecting existing socket...');
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
        await Future.delayed(Duration(milliseconds: 500)); // Wait for cleanup
      }

      print('🔌 Connecting to socket with new token...');
      print('🔗 Server URL: $serverUrl');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // Disable auto connect to have more control
            .enableReconnection()
            .setReconnectionAttempts(3)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(3000)
            .setRandomizationFactor(0.5)
            .setTimeout(8000) // Connection timeout
            .setAuth({
              'token': token,
            })
            .build(),
      );

      _setupSocketListeners();
      
      // Manually connect and wait for result with timeout
      _socket!.connect();
      
      // Wait for connection with timeout
      bool connected = false;
      int attempts = 0;
      const maxAttempts = 80; // 8 seconds total (80 * 100ms)
      
      while (!connected && attempts < maxAttempts && _isConnecting) {
        await Future.delayed(Duration(milliseconds: 100));
        connected = _socket?.connected ?? false;
        attempts++;
        
        if (attempts % 10 == 0) {
          print('🔄 Connection attempt ${attempts / 10}/8 - Connected: $connected');
        }
      }
      
      if (!connected) {
        print('⏰ Connection timeout after ${attempts * 100}ms');
        _isConnecting = false;
        _isConnected = false;
        _socket?.disconnect();
        _socket?.dispose();
        _socket = null;
        throw Exception('Connection timeout');
      }
      
    } catch (e) {
      print('❌ Socket connection error: $e');
      _isConnecting = false;
      _isConnected = false;
      _currentUserToken = null;
      
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }
      
      onError?.call('Failed to connect: $e');
      onConnectionStatusChanged?.call(false);
      rethrow;
    }
  }

  static void _setupSocketListeners() {
    _socket?.on('connect', (_) {
      print('✅ Socket connected successfully with token: ${_currentUserToken?.substring(0, 10)}...');
      _isConnected = true;
      _isConnecting = false;
      onConnectionStatusChanged?.call(true);
    });

    _socket?.on('disconnect', (reason) {
      print('❌ Socket disconnected: $reason');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
    });

    _socket?.on('connect_error', (error) {
      print('❌ Socket connection error: $error');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
      onError?.call('Connection error: $error');
    });

    _socket?.on('connect_timeout', (_) {
      print('⏰ Socket connection timeout');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
      onError?.call('Connection timeout');
    });

    _socket?.on('reconnect', (attemptNumber) {
      print('🔄 Socket reconnected after $attemptNumber attempts');
      _isConnected = true;
      _isConnecting = false;
      onConnectionStatusChanged?.call(true);
    });

    _socket?.on('reconnect_error', (error) {
      print('❌ Socket reconnection error: $error');
      _isConnected = false;
      onConnectionStatusChanged?.call(false);
    });

    _socket?.on('reconnect_failed', (_) {
      print('❌ Socket reconnection failed completely');
      _isConnected = false;
      _isConnecting = false;
      onConnectionStatusChanged?.call(false);
      onError?.call('Reconnection failed. Please try again.');
    });

    // Auth-specific listeners
    _socket?.on('auth_error', (error) {
      print('❌ Authentication error: $error');
      _isConnected = false;
      _isConnecting = false;
      _currentUserToken = null;
      onConnectionStatusChanged?.call(false);
      onError?.call('Authentication failed. Please login again.');
    });

    _socket?.on('unauthorized', (error) {
      print('❌ Unauthorized error: $error');
      _isConnected = false;
      _isConnecting = false;
      _currentUserToken = null;
      onConnectionStatusChanged?.call(false);
      onError?.call('Unauthorized access. Please login again.');
    });

    _socket?.on('receive_message', (data) {
      try {
        print('📨 Received message: $data');
        final message = Message(
          id: data['_id'] ?? '',
          senderId: data['senderId']['_id'] ?? data['senderId'],
          receiverId: data['receiverId'],
          content: data['content'],
          timestamp: DateTime.parse(data['timestamp']),
        );
        onMessageReceived?.call(message);
      } catch (e) {
        print('❌ Error parsing received message: $e');
      }
    });

    _socket?.on('message_sent', (data) {
      try {
        print('✅ Message sent confirmation: $data');
        final message = Message(
          id: data['_id'] ?? '',
          senderId: data['senderId']['_id'] ?? data['senderId'],
          receiverId: data['receiverId'],
          content: data['content'],
          timestamp: DateTime.parse(data['timestamp']),
        );
        onMessageSent?.call(message);
      } catch (e) {
        print('❌ Error parsing sent message: $e');
      }
    });

    _socket?.on('chat_history', (data) {
      try {
        print('📚 Received chat history: ${data.length} messages');
        final List<Message> messages = (data as List).map((messageData) {
          return Message(
            id: messageData['_id'] ?? '',
            senderId: messageData['senderId']['_id'] ?? messageData['senderId'],
            receiverId: messageData['receiverId']['_id'] ?? messageData['receiverId'],
            content: messageData['content'],
            timestamp: DateTime.parse(messageData['timestamp']),
          );
        }).toList();
        onChatHistory?.call(messages);
      } catch (e) {
        print('❌ Error parsing chat history: $e');
      }
    });

    _socket?.on('error', (error) {
      print('❌ Socket error: $error');
      onError?.call(error.toString());
    });
  }

  static void sendMessage({
    required String receiverId,
    required String content,
  }) async {
    // Check if we need to reconnect with new auth
    final currentToken = await AuthService.getToken();
    if (currentToken != _currentUserToken) {
      print('🔄 Token mismatch detected, reconnecting...');
      await ensureConnected();
    }

    if (_socket != null && _isConnected) {
      print('📤 Sending message to $receiverId: $content');
      _socket!.emit('send_message', {
        'receiverId': receiverId,
        'content': content,
      });
    } else {
      print('❌ Cannot send message: Socket not connected (isConnected: $_isConnected)');
      onError?.call('Not connected to server');
    }
  }

  static void getChatHistory(String otherUserId) async {
    // Check if we need to reconnect with new auth
    final currentToken = await AuthService.getToken();
    if (currentToken != _currentUserToken) {
      print('🔄 Token mismatch detected, reconnecting...');
      await ensureConnected();
    }

    if (_socket != null && _isConnected) {
      print('📚 Requesting chat history for user: $otherUserId');
      _socket!.emit('get_chat_history', {
        'otherUserId': otherUserId,
      });
    } else {
      print('❌ Cannot get chat history: Socket not connected (isConnected: $_isConnected)');
      onError?.call('Not connected to server');
    }
  }

  // Method to check connection and reconnect if needed
  static Future<bool> checkConnection() async {
    try {
      final currentToken = await AuthService.getToken();
      
      // If token changed or not connected, reconnect
      if (currentToken != _currentUserToken || !_isConnected || _socket == null) {
        print('🔄 Connection check failed, attempting to reconnect...');
        await ensureConnected();
      }
      
      return _isConnected;
    } catch (e) {
      print('❌ Connection check error: $e');
      return false;
    }
  }

  static void disconnect() {
    print('🔌 Disconnecting socket...');
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _isConnecting = false;
    onConnectionStatusChanged?.call(false);
  }

  static void clearCallbacks() {
    onMessageReceived = null;
    onMessageSent = null;
    onChatHistory = null;
    onConnectionStatusChanged = null;
    onError = null;
  }

  // Debug method to check current state
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'hasSocket': _socket != null,
      'currentToken': _currentUserToken?.substring(0, 10),
      'socketConnected': _socket?.connected ?? false,
    };
  }
}