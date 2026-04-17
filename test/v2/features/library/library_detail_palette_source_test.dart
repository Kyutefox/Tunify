import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/domain/library_detail_palette_source.dart';

void main() {
  group('libraryDetailPaletteSourceUrl', () {
    const artistItem = LibraryItem(
      id: 'a1',
      title: 'Artist',
      subtitle: 'sub',
      kind: LibraryItemKind.artist,
      imageUrl: 'https://example.com/item-avatar.jpg',
    );

    LibraryDetailsModel minimalDetails({
      required List<LibraryDetailsTrack> tracks,
      String? heroImageUrl,
    }) {
      return LibraryDetailsModel(
        type: LibraryDetailsType.artist,
        item: artistItem,
        searchHint: '',
        title: 'Title',
        subtitlePrimary: 'Primary',
        tracks: tracks,
        heroImageUrl: heroImageUrl,
      );
    }

    test('prefers item.imageUrl over heroImageUrl', () {
      final details = minimalDetails(
        tracks: const [],
        heroImageUrl: 'https://example.com/hero-only.jpg',
      );
      expect(
        libraryDetailPaletteSourceUrl(item: artistItem, details: details),
        artistItem.imageUrl,
      );
    });

    test('uses first non-empty track thumb when item and hero have no image', () {
      const itemNoImage = LibraryItem(
        id: 'a2',
        title: 'Artist',
        subtitle: 'sub',
        kind: LibraryItemKind.artist,
      );
      final details = LibraryDetailsModel(
        type: LibraryDetailsType.artist,
        item: itemNoImage,
        searchHint: '',
        title: 'Title',
        subtitlePrimary: 'Primary',
        tracks: const [
          LibraryDetailsTrack(
            title: 'Track',
            subtitle: 'Sub',
            thumbUrl: 'https://example.com/track-thumb.jpg',
          ),
        ],
      );
      expect(
        libraryDetailPaletteSourceUrl(item: itemNoImage, details: details),
        'https://example.com/track-thumb.jpg',
      );
    });

    test('returns null when item uses system artwork', () {
      const liked = LibraryItem(
        id: 'liked',
        title: 'Liked',
        subtitle: 's',
        kind: LibraryItemKind.playlist,
        systemArtwork: SystemArtworkType.likedSongs,
      );
      final details = LibraryDetailsModel(
        type: LibraryDetailsType.staticPlaylist,
        item: liked,
        searchHint: '',
        title: 'Liked',
        subtitlePrimary: '1 song',
        tracks: const [],
      );
      expect(
        libraryDetailPaletteSourceUrl(item: liked, details: details),
        isNull,
      );
    });
  });
}
