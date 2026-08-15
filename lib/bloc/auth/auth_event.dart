import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// SplashPage add() event này khi app khởi động để biết điều hướng
// thẳng vào HomePage hay LoginPage.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
