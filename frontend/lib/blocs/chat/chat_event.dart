import 'package:equatable/equatable.dart';
import '../../models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class ChatStarted extends ChatEvent {
  final String otherUserId;

  const ChatStarted({required this.otherUserId});

  @override
  List<Object> get props => [otherUserId];
}

class ChatMessageSent extends ChatEvent {
  final String content;

  const ChatMessageSent({required this.content});

  @override
  List<Object> get props => [content];
}

class ChatMessageReceived extends ChatEvent {
  final Message message;

  const ChatMessageReceived({required this.message});

  @override
  List<Object> get props => [message];
}

class ChatHistoryLoaded extends ChatEvent {
  final List<Message> messages;

  const ChatHistoryLoaded({required this.messages});

  @override
  List<Object> get props => [messages];
}

class ChatConnectionStatusChanged extends ChatEvent {
  final bool isConnected;

  const ChatConnectionStatusChanged({required this.isConnected});

  @override
  List<Object> get props => [isConnected];
}

class ChatErrorOccurred extends ChatEvent {
  final String error;

  const ChatErrorOccurred({required this.error});

  @override
  List<Object> get props => [error];
}