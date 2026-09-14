import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/check_runner.dart';
import '../services/notification_service.dart';

/// Draait in de aparte achtergrond-isolate van de foreground service. Moet
/// top-level zijn en de @pragma-annotatie hebben.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(StoringTaskHandler());
}

class StoringTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await NotificationService.init();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // onRepeatEvent zelf is synchroon; we vuren de (async) controle af en
    // laten 'm zelfstandig afronden.
    CheckRunner.runCheck();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Beheert de foreground service die de storingscontrole betrouwbaar op
/// schema houdt. In tegenstelling tot een "stille" achtergrondtaak
/// (WorkManager) is een foreground service niet onderhevig aan Android's
/// App Standby Buckets - de reden dat de vorige aanpak soms urenlang
/// uitgesteld werd. De prijs daarvoor is een permanente, low-priority
/// melding in de meldingenbalk zolang de app actief is.
class ForegroundServiceManager {
  static Future<void> init({
    Duration interval = const Duration(minutes: 20),
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'storing_notifier_service',
        channelName: 'Storing Notifier - actief',
        channelDescription:
            'Houdt de achtergrondcontrole van de storingsfeeds actief',
      ),
      // Deze app is alleen voor Android gebouwd, maar de package vereist
      // dit argument altijd (ook al doet het op Android niets).
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(interval.inMilliseconds),
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.restartService();
      return;
    }
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Storing Notifier actief',
      notificationText: 'Controleert periodiek op storingen',
      callback: startCallback,
    );
  }

  static Future<void> requestPermissions() async {
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
  }
}
