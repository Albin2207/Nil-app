import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  /// Get search history
  static Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Add search query to history
  static Future<void> addToHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_key) ?? [];

      // Remove if already exists (to move it to top)
      history.remove(query);

      // Add to beginning
      history.insert(0, query);

      // Keep only last 10
      if (history.length > _maxHistory) {
        history = history.sublist(0, _maxHistory);
      }

      await prefs.setStringList(_key, history);
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove specific query from history
  static Future<void> removeFromHistory(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(_key) ?? [];
      history.remove(query);
      await prefs.setStringList(_key, history);
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear all search history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // Silently fail
    }
  }
}

