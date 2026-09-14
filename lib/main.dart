import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'background/foreground_task_setup.dart';
import 'models/feed_source.dart';
import 'services/check_runner.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  runApp(const StoringNotifierApp());
}

class StoringNotifierApp extends StatelessWidget {
  const StoringNotifierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Storing Notifier',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _enabledMap = {};
  bool _notifyResolved = true;
  DateTime? _lastChecked;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await NotificationService.init();
    await ForegroundServiceManager.requestPermissions();
    await ForegroundServiceManager.init();
    await ForegroundServiceManager.start();
    await _loadState();
  }

  Future<void> _loadState() async {
    final map = <String, bool>{};
    for (final f in defaultFeeds) {
      map[f.id] = await StorageService.isFeedEnabled(f.id);
    }
    final notifyResolved = await StorageService.getNotifyResolved();
    final lastChecked = await StorageService.getLastChecked();
    if (!mounted) return;
    setState(() {
      _enabledMap
        ..clear()
        ..addAll(map);
      _notifyResolved = notifyResolved;
      _lastChecked = lastChecked;
    });
  }

  Future<void> _runCheckNow() async {
    setState(() => _checking = true);
    await CheckRunner.runCheck();
    await _loadState();
    if (!mounted) return;
    setState(() => _checking = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Controle voltooid')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storing Notifier')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Melding bij "opgelost"'),
            subtitle: const Text(
              'Ontvang ook een melding zodra een storing is opgelost',
            ),
            value: _notifyResolved,
            onChanged: (v) async {
              await StorageService.setNotifyResolved(v);
              setState(() => _notifyResolved = v);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Feeds', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final feed in defaultFeeds)
            SwitchListTile(
              title: Text(feed.name),
              subtitle: Text(
                feed.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              value: _enabledMap[feed.id] ?? true,
              onChanged: (v) async {
                await StorageService.setFeedEnabled(feed.id, v);
                setState(() => _enabledMap[feed.id] = v);
              },
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastChecked == null
                      ? 'Nog niet eerder gecontroleerd'
                      : 'Laatst gecontroleerd: ${_lastChecked!.toLocal()}',
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _checking ? null : _runCheckNow,
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_checking ? 'Bezig...' : 'Controleer nu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
