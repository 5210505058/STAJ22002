import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

@immutable
class AppUser {
  final String email;
  final String name;
  const AppUser({required this.email, required this.name});

  Map<String, dynamic> toMap() => {'email': email, 'name': name};
  factory AppUser.fromMap(Map<String, dynamic> map) =>
      AppUser(email: map['email'] as String, name: map['name'] as String);
}

final authProvider =
StateNotifierProvider<AuthNotifier, AppUser?>((ref) => AuthNotifier()..loadFromHive());

class AuthNotifier extends StateNotifier<AppUser?> {
  AuthNotifier() : super(null);

  static const usersBoxName = 'users';   // email -> {email,name,password}
  static const sessionBoxName = 'auth';  // { currentUserEmail: ... }

  Box get _users => Hive.box(usersBoxName);
  Box get _session => Hive.box(sessionBoxName);

  void loadFromHive() {
    final email = _session.get('currentUserEmail');
    if (email is String) {
      final raw = _users.get(email);
      if (raw is Map) {
        state = AppUser(email: raw['email'] as String, name: raw['name'] as String);
      }
    }
  }

  String? _validateEmail(String email) {
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.trim().isEmpty) return 'E-posta gerekli';
    if (!r.hasMatch(email)) return 'Geçerli bir e-posta girin';
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final emailErr = _validateEmail(email);
    if (emailErr != null) return emailErr;
    if (name.trim().length < 2) return 'Ad en az 2 karakter olmalı';
    if (password.length < 4) return 'Şifre en az 4 karakter olmalı';

    if (_users.containsKey(email)) {
      return 'Bu e-posta zaten kayıtlı';
    }
    await _users.put(email, {
      'email': email,
      'name': name.trim(),
      'password': password, // Demo. Gerçekte hash kullanın.
    });
    await _session.put('currentUserEmail', email);
    state = AppUser(email: email, name: name.trim());
    return null;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final emailErr = _validateEmail(email);
    if (emailErr != null) return emailErr;
    final raw = _users.get(email);
    if (raw is! Map) return 'Kullanıcı bulunamadı';
    if ((raw['password'] as String) != password) return 'Şifre hatalı';
    await _session.put('currentUserEmail', email);
    state = AppUser(email: raw['email'] as String, name: raw['name'] as String);
    return null;
  }

  Future<void> logout() async {
    await _session.delete('currentUserEmail');
    state = null;
  }
}
