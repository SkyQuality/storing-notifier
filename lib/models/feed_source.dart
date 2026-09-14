/// Manier waarop een feed op een storing gecontroleerd wordt.
enum FeedMode {
  /// Standaard: kijk naar losse <item>-elementen (nieuw item = storing,
  /// item krijgt "opgelost" in titel/tekst = opgelost).
  item,

  /// Uitzondering (bv. Koopoverheid/DRP): de feed zelf bevat geen los item
  /// per storing, maar de kanaal-omschrijving zegt letterlijk of er "geen
  /// storingen" zijn. We volgen die ene statuszin.
  channelStatus,
}

class FeedSource {
  final String id;
  final String name;
  final String url;
  final FeedMode mode;

  /// Alleen gebruikt bij [FeedMode.channelStatus]: de zin die aangeeft dat
  /// er GEEN storing is. Verdwijnt deze zin uit de kanaal-omschrijving, dan
  /// gaan we ervan uit dat er een storing is.
  final String noIncidentPhrase;

  const FeedSource({
    required this.id,
    required this.name,
    required this.url,
    required this.mode,
    this.noIncidentPhrase = '',
  });
}

/// De 5 storingsbronnen die samen met Terry zijn uitgezocht.
/// Zie het gesprek/README voor de reden achter elke keuze.
const List<FeedSource> defaultFeeds = [
  FeedSource(
    id: 'iplo',
    name: 'IPLO - Storingen DSO',
    url:
        'https://iplo.nl/digitaal-stelsel/storingen-onderhoud-release-informatie/storingen/?rss=true',
    mode: FeedMode.item,
  ),
  FeedSource(
    id: 'kvk',
    name: 'KVK - Status',
    url:
        'https://rssgenerator.mooo.com/feeds/?p=aaHR0cHM6Ly9zdGF0dXMua3ZrLm5sLw==',
    mode: FeedMode.item,
  ),
  FeedSource(
    id: 'logius',
    name: 'Logius - Storingen',
    url: 'https://www.logius.nl/rss-feeds/storingen/rss.xml',
    mode: FeedMode.item,
  ),
  FeedSource(
    id: 'rvig',
    name: 'RVIG - Systeemmeldingen',
    url: 'https://www.rvig.nl/systeemmeldingen.xml',
    mode: FeedMode.item,
  ),
  FeedSource(
    id: 'koopoverheid',
    name: 'Koopoverheid - DRP status',
    url: 'https://cdn.mysitemapgenerator.com/shareapi/rss/01092696806',
    mode: FeedMode.channelStatus,
    noIncidentPhrase: 'geen storingen',
  ),
];
