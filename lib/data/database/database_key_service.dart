import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DatabaseKeyService {
  static const String _keyName = 'mrm_database_key';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<String> getOrCreateKey() async {
    final existingKey = await _storage.read(key: _keyName);

    if (existingKey != null && existingKey.isNotEmpty) {
      return existingKey;
    }

    final key = _generateKey();

    await _storage.write(key: _keyName, value: key);

    return key;
  }

  static Future<void> deleteKey() async {
    await _storage.delete(key: _keyName);
  }

  static String _generateKey() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';

    final random = Random.secure();

    return List.generate(
      64,
          (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}