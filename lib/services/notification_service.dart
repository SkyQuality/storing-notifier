import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

/// Wrapper rond flutter_local_notifications. Wordt zowel vanuit de UI
/// (main isolate) als vanuit de achtergrondtaak (aparte isolate) aangeroepen
/// - vandaar dat init() idempotent is en overal opnieuw aangeroepen mag
/// worden.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  static void _onTap(NotificationResponse response) async {
    final url = response.payload;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> requestPermission() async {
    await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
  }

  static Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    const androidDetails = AndroidNotificationDetails(
      'storingen_kanaal',
      'Storingsmeldingen',
      channelDescription: 'Meldingen bij nieuwe of opgeloste storingen',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    // Unieke id per melding zodat meldingen elkaar niet overschrijven.
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _plugin.show(id, title, body, details, payload: payload);
  }
}
