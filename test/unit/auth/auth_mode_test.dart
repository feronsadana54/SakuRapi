import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/user_entity.dart';
import 'package:finance_tracker/domain/enums/auth_mode.dart';

void main() {
  group('AuthMode enum', () {
    test('has guest and google values', () {
      expect(AuthMode.values, contains(AuthMode.guest));
      expect(AuthMode.values, contains(AuthMode.google));
      expect(AuthMode.values.length, 2);
    });
  });

  group('UserEntity.isGuest', () {
    test('returns true for guest auth mode', () {
      const user = UserEntity(
        id: 'guest-uuid-123',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.isGuest, isTrue);
    });

    test('returns false for google auth mode', () {
      const user = UserEntity(
        id: 'google-uid-456',
        displayName: 'Budi Santoso',
        email: 'budi@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.isGuest, isFalse);
    });

    test('guest user has no email', () {
      const user = UserEntity(
        id: 'guest-uuid-123',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.email, isNull);
    });

    test('google user has email', () {
      const user = UserEntity(
        id: 'google-uid-456',
        displayName: 'Budi Santoso',
        email: 'budi@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.email, 'budi@gmail.com');
    });
  });

  group('UserEntity value equality (Equatable)', () {
    test('two guest users with same data are equal', () {
      const u1 = UserEntity(
        id: 'guest-uuid-1',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      const u2 = UserEntity(
        id: 'guest-uuid-1',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(u1, equals(u2));
    });

    test('two users with different IDs are not equal', () {
      const u1 = UserEntity(
        id: 'guest-uuid-1',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      const u2 = UserEntity(
        id: 'guest-uuid-2',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(u1, isNot(equals(u2)));
    });

    test('guest and google users with same id are not equal', () {
      const u1 = UserEntity(
        id: 'uid-999',
        displayName: 'User',
        authMode: AuthMode.guest,
      );
      const u2 = UserEntity(
        id: 'uid-999',
        displayName: 'User',
        email: 'user@gmail.com',
        authMode: AuthMode.google,
      );
      expect(u1, isNot(equals(u2)));
    });

    test('props list contains all identity fields', () {
      const user = UserEntity(
        id: 'uid-1',
        displayName: 'Test User',
        email: 'test@email.com',
        authMode: AuthMode.google,
      );
      expect(user.props, [
        'uid-1',
        'Test User',
        'test@email.com',
        AuthMode.google,
      ]);
    });
  });
}
