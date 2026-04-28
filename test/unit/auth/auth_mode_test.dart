// test/unit/auth/auth_mode_test.dart
//
// Unit tests untuk AuthMode enum dan UserEntity.
//
// Covers:
//   - AuthMode enum berisi guest, google, emailLink
//   - UserEntity.isGuest, isEmailLink, isAuthenticated
//   - UserEntity props (Equatable) mencakup semua field identitas
//   - UserEntity.copyWith membuat salinan dengan field baru
//
// Run: flutter test test/unit/auth/auth_mode_test.dart

import 'package:flutter_test/flutter_test.dart';

import 'package:finance_tracker/domain/entities/user_entity.dart';
import 'package:finance_tracker/domain/enums/auth_mode.dart';

void main() {
  // ── AuthMode enum ───────────────────────────────────────────────────────────

  group('AuthMode enum', () {
    test('berisi nilai guest, google, dan emailLink', () {
      expect(AuthMode.values, contains(AuthMode.guest));
      expect(AuthMode.values, contains(AuthMode.google));
      expect(AuthMode.values, contains(AuthMode.emailLink));
    });

    test('memiliki tepat 3 nilai', () {
      expect(AuthMode.values.length, 3);
    });
  });

  // ── UserEntity.isGuest ──────────────────────────────────────────────────────

  group('UserEntity.isGuest', () {
    test('true untuk mode tamu', () {
      const user = UserEntity(
        id: 'guest-uuid-123',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.isGuest, isTrue);
    });

    test('false untuk mode Google', () {
      const user = UserEntity(
        id: 'google-uid-456',
        displayName: 'Budi Santoso',
        email: 'budi@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.isGuest, isFalse);
    });

    test('false untuk mode Email Link', () {
      const user = UserEntity(
        id: 'emaillink-uid-789',
        displayName: 'ani',
        email: 'ani@email.com',
        authMode: AuthMode.emailLink,
      );
      expect(user.isGuest, isFalse);
    });
  });

  // ── UserEntity.isEmailLink ──────────────────────────────────────────────────

  group('UserEntity.isEmailLink', () {
    test('true untuk mode emailLink', () {
      const user = UserEntity(
        id: 'uid-el-001',
        displayName: 'sari',
        email: 'sari@email.com',
        authMode: AuthMode.emailLink,
      );
      expect(user.isEmailLink, isTrue);
    });

    test('false untuk mode guest', () {
      const user = UserEntity(
        id: 'guest-1',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.isEmailLink, isFalse);
    });

    test('false untuk mode google', () {
      const user = UserEntity(
        id: 'google-1',
        displayName: 'Google User',
        email: 'g@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.isEmailLink, isFalse);
    });
  });

  // ── UserEntity.isAuthenticated ──────────────────────────────────────────────

  group('UserEntity.isAuthenticated', () {
    test('false untuk mode tamu', () {
      const user = UserEntity(
        id: 'guest-1',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.isAuthenticated, isFalse);
    });

    test('true untuk mode Google', () {
      const user = UserEntity(
        id: 'g-uid-1',
        displayName: 'Google User',
        email: 'g@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.isAuthenticated, isTrue);
    });

    test('true untuk mode Email Link', () {
      const user = UserEntity(
        id: 'el-uid-1',
        displayName: 'emailuser',
        email: 'u@email.com',
        authMode: AuthMode.emailLink,
      );
      expect(user.isAuthenticated, isTrue);
    });
  });

  // ── Email tamu vs. terautentikasi ───────────────────────────────────────────

  group('UserEntity.email', () {
    test('tamu tidak memiliki email', () {
      const user = UserEntity(
        id: 'guest-uuid-123',
        displayName: 'Tamu',
        authMode: AuthMode.guest,
      );
      expect(user.email, isNull);
    });

    test('Google user memiliki email', () {
      const user = UserEntity(
        id: 'google-uid-456',
        displayName: 'Budi',
        email: 'budi@gmail.com',
        authMode: AuthMode.google,
      );
      expect(user.email, 'budi@gmail.com');
    });

    test('Email Link user memiliki email', () {
      const user = UserEntity(
        id: 'el-uid-789',
        displayName: 'ani',
        email: 'ani@email.com',
        authMode: AuthMode.emailLink,
      );
      expect(user.email, 'ani@email.com');
    });
  });

  // ── UserEntity.props (Equatable) ────────────────────────────────────────────

  group('UserEntity value equality (Equatable)', () {
    test('dua tamu dengan data sama adalah equal', () {
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

    test('dua user dengan ID berbeda tidak equal', () {
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

    test('tamu dan Google user dengan ID sama tidak equal', () {
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

    test('Google dan Email Link user tidak equal meskipun ID sama', () {
      const u1 = UserEntity(
        id: 'uid-888',
        displayName: 'User',
        email: 'u@gmail.com',
        authMode: AuthMode.google,
      );
      const u2 = UserEntity(
        id: 'uid-888',
        displayName: 'User',
        email: 'u@gmail.com',
        authMode: AuthMode.emailLink,
      );
      expect(u1, isNot(equals(u2)));
    });

    test('props mencakup semua field identitas termasuk photoUrl', () {
      const user = UserEntity(
        id: 'uid-1',
        displayName: 'Test User',
        email: 'test@email.com',
        photoUrl: 'https://photo.example.com/avatar.jpg',
        authMode: AuthMode.google,
      );
      expect(user.props, [
        'uid-1',
        'Test User',
        'test@email.com',
        'https://photo.example.com/avatar.jpg',
        AuthMode.google,
      ]);
    });

    test('props dengan photoUrl null tercakup', () {
      const user = UserEntity(
        id: 'uid-2',
        displayName: 'No Photo',
        email: 'nophoto@email.com',
        authMode: AuthMode.emailLink,
      );
      expect(user.props, [
        'uid-2',
        'No Photo',
        'nophoto@email.com',
        null, // photoUrl null
        AuthMode.emailLink,
      ]);
    });
  });

  // ── UserEntity.copyWith ─────────────────────────────────────────────────────

  group('UserEntity.copyWith', () {
    test('mengganti displayName tanpa mengubah field lain', () {
      const original = UserEntity(
        id: 'uid-copy-1',
        displayName: 'Nama Lama',
        email: 'user@email.com',
        authMode: AuthMode.emailLink,
      );
      final updated = original.copyWith(displayName: 'Nama Baru');
      expect(updated.displayName, 'Nama Baru');
      expect(updated.id, original.id);
      expect(updated.email, original.email);
      expect(updated.authMode, original.authMode);
    });

    test('mengganti email tanpa mengubah field lain', () {
      const original = UserEntity(
        id: 'uid-copy-2',
        displayName: 'User',
        email: 'old@email.com',
        authMode: AuthMode.google,
      );
      final updated = original.copyWith(email: 'new@email.com');
      expect(updated.email, 'new@email.com');
      expect(updated.id, original.id);
      expect(updated.displayName, original.displayName);
      expect(updated.authMode, original.authMode);
    });

    test('tanpa argumen menghasilkan objek yang sama (equal)', () {
      const user = UserEntity(
        id: 'uid-no-change',
        displayName: 'Tetap',
        email: 'stay@email.com',
        authMode: AuthMode.google,
      );
      final copy = user.copyWith();
      expect(copy, equals(user));
    });
  });
}
