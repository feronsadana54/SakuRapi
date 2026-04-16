import 'package:equatable/equatable.dart';
import '../enums/auth_mode.dart';

class UserEntity extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final AuthMode authMode;

  const UserEntity({
    required this.id,
    required this.displayName,
    this.email,
    required this.authMode,
  });

  bool get isGuest => authMode == AuthMode.guest;

  @override
  List<Object?> get props => [id, displayName, email, authMode];
}
