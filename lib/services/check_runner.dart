import '../models/feed_source.dart';
import 'notification_service.dart';
import 'rss_service.dart';
import 'storage_service.dart';

/// De kernlogica: haalt alle ingeschakelde feeds op, vergelijkt met de
/// vorige staat, en stuurt meldingen waar nodig. Wordt zowel door de
/// achtergrondtaak (elke 15-30 min) als door de "Controleer nu"-knop in de
/// UI aangeroepen.
class CheckRunner {
  // Woorden die aangeven dat een storing is opgelost. Grotendeels op basis
  // van hoe IPLO en KVK dit in de praktijk verwoorden ("Opgelost: ...",
  // "[Opgelost]").
  static const List<String> _resolvedKeywords = ['opgelost', 'hersteld'];

  static bool _looksResolved(String text) {
    final lower = text.toLowerCase();
    return _resolvedKeywords.any((k) => lower.contains(k));
  }

  static Future<void> runCheck() async {
    final feeds = await StorageService.getEnabledFeeds();
    final notifyResolved = await StorageService.getNotifyResolved();

    for (final feed in feeds) {
      try {
        final parsed = await RssService.fetchAndParse(feed.url);
        if (feed.mode == FeedMode.item) {
          await _checkItemFeed(feed, parsed, notifyResolved);
        } else {
          await _checkChannelStatusFeed(feed, parsed, notifyResolved);
        }
      } catch (_) {
        // Eén kapotte/tijdelijk onbereikbare feed mag de rest niet
        // blokkeren. Volgende ronde wordt gewoon opnieuw geprobeerd.
        continue;
      }
    }

    await StorageService.setLastChecked(DateTime.now());
  }

  static Future<void> _checkItemFeed(
    FeedSource feed,
    ParsedFeed parsed,
    bool notifyResolved,
  ) async {
    final oldState = await StorageService.getItemState(feed.id);
    // Eerste keer dat deze feed gecontroleerd wordt: alleen een nulmeting
    // opslaan, niet meteen voor alle bestaande (mogelijk allang opgeloste)
    // items een melding sturen.
    final isFirstRun = oldState.isEmpty;
    final newState = <String, Map<String, dynamic>>{};

    for (final item in parsed.items) {
      final resolvedNow =
          _looksResolved(item.title) || _looksResolved(item.description);
      newState[item.id] = {'title': item.title, 'resolved': resolvedNow};

      if (isFirstRun) continue;

      final old = oldState[item.id];
      if (old == null) {
        // Nieuw item sinds de vorige controle.
        if (resolvedNow) {
          if (notifyResolved) {
            await NotificationService.show(
              title: '${feed.name}: opgelost',
              body: item.title,
              payload: item.link,
            );
          }
        } else {
          await NotificationService.show(
            title: '${feed.name}: storing',
            body: item.title,
            payload: item.link,
          );
        }
      } else {
        final wasResolved = old['resolved'] == true;
        if (!wasResolved && resolvedNow) {
          if (notifyResolved) {
            await NotificationService.show(
              title: '${feed.name}: opgelost',
              body: item.title,
              payload: item.link,
            );
          }
        } else if (wasResolved && !resolvedNow) {
          // Zeldzaam: een als "opgelost" gemarkeerd item wordt weer actief.
          await NotificationService.show(
            title: '${feed.name}: storing (heropend)',
            body: item.title,
            payload: item.link,
          );
        }
      }
    }

    await StorageService.setItemState(feed.id, newState);
  }

  static Future<void> _checkChannelStatusFeed(
    FeedSource feed,
    ParsedFeed parsed,
    bool notifyResolved,
  ) async {
    final old = await StorageService.getChannelState(feed.id);
    final desc = parsed.channelDescription;
    final hasIncidentNow = desc.isNotEmpty &&
        !desc.toLowerCase().contains(feed.noIncidentPhrase.toLowerCase());

    if (old == null) {
      // Nulmeting, geen melding bij de allereerste controle.
      await StorageService.setChannelState(
        feed.id,
        {'description': desc, 'hasIncident': hasIncidentNow},
      );
      return;
    }

    final wasIncident = old['hasIncident'] == true;
    if (!wasIncident && hasIncidentNow) {
      await NotificationService.show(
        title: '${feed.name}: storing',
        body: desc,
        payload: feed.url,
      );
    } else if (wasIncident && !hasIncidentNow) {
      if (notifyResolved) {
        await NotificationService.show(
          title: '${feed.name}: opgelost',
          body: desc,
          payload: feed.url,
        );
      }
    }

    await StorageService.setChannelState(
      feed.id,
      {'description': desc, 'hasIncident': hasIncidentNow},
    );
  }
}
