import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class ParsedItem {
  final String id;
  final String title;
  final String description;
  final String link;

  ParsedItem({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
  });
}

class ParsedFeed {
  final String channelDescription;
  final List<ParsedItem> items;

  ParsedFeed({required this.channelDescription, required this.items});
}

class RssService {
  /// Haalt een RSS-feed op en parsed 'm naar iets bruikbaars.
  /// Gooit een Exception bij netwerk- of parse-fouten; de aanroeper
  /// (CheckRunner) vangt dit per feed op zodat 1 kapotte feed de rest niet
  /// blokkeert.
  static Future<ParsedFeed> fetchAndParse(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Android; Storing Notifier app; +persoonlijk gebruik)',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode} bij ophalen van $url');
    }

    final document = XmlDocument.parse(response.body);

    // De kanaal-omschrijving staat normaliter vóór de <item>-elementen, dus
    // de eerste <description> in het document is de kanaal-omschrijving.
    final descriptions = document.findAllElements('description');
    final channelDescription =
        descriptions.isNotEmpty ? descriptions.first.innerText.trim() : '';

    final items = <ParsedItem>[];
    for (final itemEl in document.findAllElements('item')) {
      final title = _text(itemEl, 'title');
      final description = _text(itemEl, 'description');
      final link = _text(itemEl, 'link');
      final guid = _text(itemEl, 'guid');
      final id = guid.isNotEmpty ? guid : (link.isNotEmpty ? link : title);
      items.add(
        ParsedItem(id: id, title: title, description: description, link: link),
      );
    }

    return ParsedFeed(channelDescription: channelDescription, items: items);
  }

  static String _text(XmlElement item, String tag) {
    final matches = item.findElements(tag);
    return matches.isNotEmpty ? matches.first.innerText.trim() : '';
  }
}
