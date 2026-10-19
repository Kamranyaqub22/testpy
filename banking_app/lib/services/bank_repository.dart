import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Where the app reads and writes its data.
///
/// Screens never talk to storage directly, so swapping on-device storage for a
/// real banking API means adding one implementation (e.g. `ApiBankRepository`)
/// without touching the UI.
abstract class BankRepository {
  Future<BankData?> load();
  Future<void> save(BankData data);
  Future<void> clear();
}

/// Stores data on the device. `shared_preferences` works on Android, iOS,
/// web, Windows, macOS and Linux, so no platform-specific code is needed.
class LocalBankRepository implements BankRepository {
  static const _key = 'horizon_bank_v2';

  @override
  Future<BankData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return BankData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Unreadable data (e.g. from an older version) starts fresh.
      await prefs.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(BankData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

/// Keeps data in memory only. Used by tests.
class InMemoryBankRepository implements BankRepository {
  String? _raw;

  @override
  Future<BankData?> load() async => _raw == null
      ? null
      : BankData.fromJson(jsonDecode(_raw!) as Map<String, dynamic>);

  @override
  Future<void> save(BankData data) async => _raw = jsonEncode(data.toJson());

  @override
  Future<void> clear() async => _raw = null;
}
