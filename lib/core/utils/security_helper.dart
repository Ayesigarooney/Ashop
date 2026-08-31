import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityHelper {
  static const _storage = FlutterSecureStorage();
  static const _hiveKeyKey = 'hive_encryption_key';

  // PIN credential keys (stored in secure storage, NOT on disk)
  static const _pinSaltKey = 'sec_pin_salt';
  static const _pinHashKey = 'sec_pin_hash';

  /// Hash a PIN with a random salt using SHA-256
  static String hashPinWithSalt(String pin, String salt) {
    final bytes = utf8.encode(pin + salt);
    return sha256.convert(bytes).toString();
  }

  /// Generate a cryptographically random salt (base64)
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Verify a PIN against its salted hash
  static bool verifyPin(String pin, String salt, String hash) {
    return hashPinWithSalt(pin, salt) == hash;
  }

  // ─── PIN credential storage (hardware-backed secure storage) ───

  /// Store a salted SHA-256 PIN hash in secure storage
  static Future<void> savePinCredentials(String pin) async {
    final salt = generateSalt();
    final hash = hashPinWithSalt(pin, salt);
    await _storage.write(key: _pinSaltKey, value: salt);
    await _storage.write(key: _pinHashKey, value: hash);
  }

  /// Verify a PIN against the hash stored in secure storage
  static Future<bool> verifyStoredPin(String pin) async {
    final salt = await _storage.read(key: _pinSaltKey);
    final hash = await _storage.read(key: _pinHashKey);
    if (salt == null || hash == null) return false;
    return verifyPin(pin, salt, hash);
  }

  /// Whether a secured PIN is currently configured
  static Future<bool> hasStoredPin() async {
    return await _storage.read(key: _pinHashKey) != null;
  }

  /// Remove stored PIN credentials
  static Future<void> clearStoredPin() async {
    await _storage.delete(key: _pinSaltKey);
    await _storage.delete(key: _pinHashKey);
  }

  /// Get or generate a Hive encryption key stored in secure storage
  static Future<List<int>> getHiveEncryptionKey() async {
    final existing = await _storage.read(key: _hiveKeyKey);
    if (existing != null) return base64.decode(existing);
    final key = _generateEncryptionKey();
    await _storage.write(key: _hiveKeyKey, value: base64.encode(key));
    return key;
  }

  /// Delete Hive encryption key (for factory reset)
  static Future<void> clearHiveEncryptionKey() async {
    await _storage.delete(key: _hiveKeyKey);
  }

  static List<int> _generateEncryptionKey() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256));
  }
}