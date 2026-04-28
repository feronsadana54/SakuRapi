import 'package:equatable/equatable.dart';
import '../enums/auth_mode.dart';

class UserEntity extends Equatable {
  final String id;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final AuthMode authMode;

  const UserEntity({
    required this.id,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.authMode,
  });

  bool get isGuest => authMode == AuthMode.guest;
  bool get isEmailLink => authMode == AuthMode.emailLink;
  bool get isAuthenticated => authMode != AuthMode.guest;

  UserEntity copyWith({
    String? id,
    String? displayName,
    String? email,
    String? photoUrl,
    AuthMode? authMode,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authMode: authMode ?? this.authMode,
    );
  }

  @override
  List<Object?> get props => [id, displayName, email, photoUrl, authMode];
}
