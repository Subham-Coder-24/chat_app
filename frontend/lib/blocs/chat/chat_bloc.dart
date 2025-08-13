import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/socket_service.dart';
import '../../models/message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(const ChatState()) {
    on<ChatStarted>(_onChatStarted);
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatMessageReceived>(_onChatMessageReceived);
    on<ChatHistoryLoaded>(_onChatHistoryLoaded);
    on<ChatConnectionStatusChanged>(_onChatConnectionStatusChanged);
    on<ChatErrorOccurred>(_onChatErrorOccurred);

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    SocketService.onMessageReceived = (message) {
      // Only add message if it's for the current chat
      if (message.senderId == state.otherUserId || message.receiverId == state.otherUserId) {
        add(ChatMessageReceived(message: message));
      }
    };

    SocketService.onMessageSent = (message) {
      add(ChatMessageReceived(message: message));
    };

    SocketService.onChatHistory = (messages) {
      add(ChatHistoryLoaded(messages: messages));
    };

    SocketService.onConnectionStatusChanged = (isConnected) {
      add(ChatConnectionStatusChanged(isConnected: isConnected));
    };

    SocketService.onError = (error) {
      add(ChatErrorOccurred(error: error));
    };
  }

  Future<void> _onChatStarted(ChatStarted event, Emitter<ChatState> emit) async {
    emit(state.copyWith(
      status: ChatStatus.loading,
      otherUserId: event.otherUserId,
      isLoadingHistory: true,
    ));

    try {
      // Connect to socket if not already connected
      if (!SocketService.isConnected) {
        await SocketService.connect();
      }

      // Get chat history
      SocketService.getChatHistory(event.otherUserId);
    } catch (e) {
      emit(state.copyWith(
        status: ChatStatus.error,
        errorMessage: 'Failed to start chat: $e',
        isLoadingHistory: false,
      ));
    }
  }

  void _onChatMessageSent(ChatMessageSent event, Emitter<ChatState> emit) {
    if (state.otherUserId != null && SocketService.isConnected) {
      SocketService.sendMessage(
        receiverId: state.otherUserId!,
        content: event.content,
      );
    } else {
      emit(state.copyWith(
        errorMessage: 'Cannot send message: Not connected or no recipient selected',
      ));
    }
  }

  void _onChatMessageReceived(ChatMessageReceived event, Emitter<ChatState> emit) {
    final updatedMessages = List<Message>.from(state.messages)..add(event.message);
    emit(state.copyWith(
      messages: updatedMessages,
      status: ChatStatus.loaded,
    ));
  }

  void _onChatHistoryLoaded(ChatHistoryLoaded event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      messages: event.messages,
      status: ChatStatus.loaded,
      isLoadingHistory: false,
    ));
  }

  void _onChatConnectionStatusChanged(
    ChatConnectionStatusChanged event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isConnected: event.isConnected));
  }

  void _onChatErrorOccurred(ChatErrorOccurred event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      status: ChatStatus.error,
      errorMessage: event.error,
    ));
  }

  @override
  Future<void> close() {
    SocketService.clearCallbacks();
    return super.close();
  }
}