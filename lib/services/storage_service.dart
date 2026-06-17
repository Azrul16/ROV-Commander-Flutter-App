import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';

class StorageService {
  static const baseUrlKey = ApiConstants.baseUrlStorageKey;

  Future<String?> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(baseUrlKey);
  }

  Future<void> saveBaseUrl(String baseUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(baseUrlKey, baseUrl);
  }

  Future<void> clearBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(baseUrlKey);
  }
}
