import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Static mock library items matching the Figma Spotify iOS 2024 Library screen
/// exactly. Order follows the grid-view screenshot (Image 1) top-left → right,
/// row by row.
abstract final class MockLibraryData {
  MockLibraryData._();

  static const List<LibraryItem> items = [
    // ── Row 1 ──────────────────────────────────────────────
    LibraryItem(
      id: 'liked-songs',
      title: 'Liked Songs',
      subtitle: 'Playlist · 16 songs',
      kind: LibraryItemKind.playlist,
      isPinned: true,
      creatorName: 'You',
      systemArtwork: SystemArtworkType.likedSongs,
    ),
    LibraryItem(
      id: 'your-episodes',
      title: 'Your Episodes',
      subtitle: 'Saved & downloaded episodes',
      kind: LibraryItemKind.podcast,
      isPinned: true,
      systemArtwork: SystemArtworkType.yourEpisodes,
    ),
    LibraryItem(
      id: 'arctic-monkeys',
      title: 'Arctic Monkeys',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    // ── Row 2 ──────────────────────────────────────────────
    LibraryItem(
      id: 'oasis',
      title: 'Oasis',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    LibraryItem(
      id: 'brit-pop-100',
      title: 'Brit Pop: 100 best songs',
      subtitle: 'Playlist',
      kind: LibraryItemKind.playlist,
      creatorName: 'Juan Cenal',
    ),
    LibraryItem(
      id: 'david-bowie',
      title: 'David Bowie',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    // ── Row 3 ──────────────────────────────────────────────
    LibraryItem(
      id: 'lebanon-hanover',
      title: 'Lebanon Hanover',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    LibraryItem(
      id: 'the-toll-of-games',
      title: 'The Toll of Games',
      subtitle: 'Album · Blur',
      kind: LibraryItemKind.album,
      creatorName: 'Blur',
    ),
    LibraryItem(
      id: 'guess-im-intro-true',
      title: 'Guess I\'m Intro True',
      subtitle: 'Album · Catfish and...',
      kind: LibraryItemKind.album,
      creatorName: 'Catfish and the Bottlemen',
    ),
    // ── Row 4 ──────────────────────────────────────────────
    LibraryItem(
      id: 'massive-attack',
      title: 'Massive Attack',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    LibraryItem(
      id: 'franz-callendar',
      title: 'Franz Callendar',
      subtitle: 'Playlist · Dug Disc...',
      kind: LibraryItemKind.playlist,
      creatorName: 'Dug Disc',
    ),
    LibraryItem(
      id: 'the-cure',
      title: 'The Cure',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    // ── Row 5 ──────────────────────────────────────────────
    LibraryItem(
      id: '3-body-problem',
      title: '3 Body Problem (Soundtrack...)',
      subtitle: 'Podcast',
      kind: LibraryItemKind.podcast,
    ),
    LibraryItem(
      id: 'in-the-meadow',
      title: 'In The Meadow',
      subtitle: 'Victoria Alexander',
      kind: LibraryItemKind.album,
      creatorName: 'Victoria Alexander',
    ),
    LibraryItem(
      id: 'the-cure-artist',
      title: 'The Cure',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    // ── Row 6 ──────────────────────────────────────────────
    LibraryItem(
      id: 'oasis-band',
      title: 'Oasis',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    LibraryItem(
      id: 'oasis-vs-blur',
      title: 'Oasis Vs Blur',
      subtitle: 'Playlist',
      kind: LibraryItemKind.playlist,
      creatorName: 'Tolo Nadal',
    ),
    LibraryItem(
      id: 'his-n-hers',
      title: 'His \'N\' Hers',
      subtitle: 'Album · Pulp',
      kind: LibraryItemKind.album,
      creatorName: 'Pulp',
    ),
    // ── Row 7 ──────────────────────────────────────────────
    LibraryItem(
      id: 'best-for-me',
      title: 'Best for me',
      subtitle: 'Playlist · Damon98',
      kind: LibraryItemKind.playlist,
      creatorName: 'Damon98',
    ),
    LibraryItem(
      id: 'protection',
      title: 'Protection',
      subtitle: 'Album · Massive At...',
      kind: LibraryItemKind.album,
      creatorName: 'Massive Attack',
    ),
    LibraryItem(
      id: 'athletic-nba-show',
      title: 'The Athletic NBA Show',
      subtitle: 'Podcast',
      kind: LibraryItemKind.podcast,
    ),
    // ── Row 8 ──────────────────────────────────────────────
    LibraryItem(
      id: 'nfl-live',
      title: 'NFL Live',
      subtitle: 'Podcast · ESPN',
      kind: LibraryItemKind.podcast,
    ),
    LibraryItem(
      id: 'put-a-blurb-on-it',
      title: 'Put A Blurb On It',
      subtitle: 'Podcast',
      kind: LibraryItemKind.podcast,
    ),
    LibraryItem(
      id: 'rock-school',
      title: 'Rock School',
      subtitle: 'Playlist · Spotify',
      kind: LibraryItemKind.playlist,
      creatorName: 'Spotify',
    ),
    // ── Row 9 ──────────────────────────────────────────────
    LibraryItem(
      id: 'the-last-dinner-party',
      title: 'The Last Dinner Party',
      subtitle: 'Artist',
      kind: LibraryItemKind.artist,
    ),
    LibraryItem(
      id: 'oasis-vs-blur-2',
      title: 'Oasis Vs Blur',
      subtitle: 'Playlist · Damon98',
      kind: LibraryItemKind.playlist,
      creatorName: 'Damon98',
    ),
    LibraryItem(
      id: 'skinee-colbie',
      title: 'Skinee Colbie And The Entire Screen...',
      subtitle: 'Podcast',
      kind: LibraryItemKind.podcast,
    ),
    // ── Row 10 ─────────────────────────────────────────────
    LibraryItem(
      id: 'lunge-routine',
      title: 'Lunge Routine',
      subtitle: 'Album · Superman...',
      kind: LibraryItemKind.album,
      creatorName: 'Supermaniac',
    ),
    LibraryItem(
      id: 'i-plastic-class',
      title: 'I Plastic Class',
      subtitle: 'Album · Supergrass...',
      kind: LibraryItemKind.album,
      creatorName: 'Supergrass',
    ),
    LibraryItem(
      id: 'hymne',
      title: 'Hymne',
      subtitle: 'Album · David Bowie',
      kind: LibraryItemKind.album,
      creatorName: 'David Bowie',
    ),
    // ── Row 11 ─────────────────────────────────────────────
    LibraryItem(
      id: 'the-la',
      title: 'The La\'s',
      subtitle: 'Album · The La\'s',
      kind: LibraryItemKind.album,
      creatorName: 'The La\'s',
    ),
    LibraryItem(
      id: 'viola',
      title: 'VIOLA',
      subtitle: 'Playlist · Denis Hill',
      kind: LibraryItemKind.playlist,
      creatorName: 'Denis Hill',
    ),
    LibraryItem(
      id: 'franz-ferdinand',
      title: 'Franz Ferdinand',
      subtitle: 'Album · Franz Ferdi...',
      kind: LibraryItemKind.album,
      creatorName: 'Franz Ferdinand',
    ),
  ];
}
