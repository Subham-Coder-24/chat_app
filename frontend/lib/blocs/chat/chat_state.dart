import 'package:equatable/equatable.dart';
import '../../models/message_model.dart';

enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final ChatStatus status;
  final List<Message> messages;
  final String? otherUserId;
  final String? otherUserEmail;
  final bool isConnected;
  final String? errorMessage;
  final bool isLoadingHistory;

  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
    this.otherUserId,
    this.otherUserEmail,
    this.isConnected = false,
    this.errorMessage,
    this.isLoadingHistory = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    List<Message>? messages,
    String? otherUserId,
    String? otherUserEmail,
    bool? isConnected,
    String? errorMessage,
    bool? isLoadingHistory,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserEmail: otherUserEmail ?? this.otherUserEmail,
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  @override
  List<Object?> get props => [
        status,
        messages,
        otherUserId,
        otherUserEmail,
        isConnected,
        errorMessage,
        isLoadingHistory,
      ];
}