import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';

// Events
abstract class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class UsersLoadRequested extends UsersEvent {}

class UsersRefreshRequested extends UsersEvent {}

// States
enum UsersStatus { initial, loading, loaded, error }

class UsersState extends Equatable {
  final UsersStatus status;
  final List<User> users;
  final String? errorMessage;

  const UsersState({
    this.status = UsersStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  UsersState copyWith({
    UsersStatus? status,
    List<User>? users,
    String? errorMessage,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, errorMessage];
}

// Bloc
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc() : super(const UsersState()) {
    on<UsersLoadRequested>(_onUsersLoadRequested);
    on<UsersRefreshRequested>(_onUsersRefreshRequested);
  }

  Future<void> _onUsersLoadRequested(
    UsersLoadRequested event,
    Emitter<UsersState> emit,
  ) async {
    if (state.status == UsersStatus.initial) {
      emit(state.copyWith(status: UsersStatus.loading));
    }

    try {
      final users = await UserService.getUsers();
      emit(state.copyWith(
        status: UsersStatus.loaded,
        users: users,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUsersRefreshRequested(
    UsersRefreshRequested event,
    Emitter<UsersState> emit,
  ) async {
    emit(state.copyWith(status: UsersStatus.loading));

    try {
      final users = await UserService.getUsers();
      emit(state.copyWith(
        status: UsersStatus.loaded,
        users: users,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UsersStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}