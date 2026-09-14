import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_source.dart';

/// Alle lokale opslag (SharedPreferences) op één plek. Geen server, geen
/// login - alles staat gewoon op het toestel zelf.
class StorageService {
  static const _kEnabledPrefix = 'enabled_';
  static const _kItemStatePrefix = 'itemstate_';
  static const _kChannelStatePrefix = 'channelstate_';
  static const _kNotifyResolved = 'notify_resolved';
  static const _kLastChecked = 'last_checked';

  static Future<List<FeedSource>> getEnabledFeeds() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <FeedSource>[];
    for (final f in defaultFeeds) {
      final enabled = prefs.getBool('$_kEnabledPrefix${f.id}') ?? true;
      if (enabled) result.add(f);
    }
    return result;
  }

  static Future<bool> isFeedEnabled(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_kEnabledPrefix$id') ?? true;
  }

  static Future<void> setFeedEnabled(String id, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_kEnabledPrefix$id', enabled);
  }

  static Future<bool> getNotifyResolved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotifyResolved) ?? true; // standaard AAN
  }

  static Future<void> setNotifyResolved(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifyResolved, value);
  }

  /// Per item-feed: map van item-id -> {title, resolved}.
  static Future<Map<String, Map<String, dynamic>>> getItemState(
    String feedId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kItemStatePrefix$feedId');
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  }

  static Future<void> setItemState(
    String feedId,
    Map<String, Map<String, dynamic>> state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kItemStatePrefix$feedId', jsonEncode(state));
  }

  /// Voor channelStatus-feeds: {description, hasIncident}. Null = nog nooit
  /// gecontroleerd (eerste run wordt gebruikt als nulmeting).
  static Future<Map<String, dynamic>?> getChannelState(String feedId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_kChannelStatePrefix$feedId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> setChannelState(
    String feedId,
    Map<String, dynamic> state,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kChannelStatePrefix$feedId', jsonEncode(state));
  }

  static Future<void> setLastChecked(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastChecked, time.millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastChecked() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_kLastChecked);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
