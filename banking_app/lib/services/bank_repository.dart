import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/bank_data.dart';

/// Where the app reads and writes its data.
///
/// The UI only talks to this interface, so moving from on-device storage to a
/// real banking backend means adding one new implementation (for example an
/// `ApiBankRepository` calling your REST API) without touching any screen.
abstract class BankRepository {
  Future<BankData?> load();
  Future<void> save(BankData data);
  Future<void> clear();
}

/// Stores data on the device. `shared_preferences` works on Android, iOS,
/// web, Windows, macOS and Linux, so this needs no platform-specific code.
class LocalBankRepository implements BankRepository {
  static const _key = 'bank_data_v1';

  @override
  Future<BankData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return BankData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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
