import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';

/// Chooses an artwork URL to sample for collection-detail gradients.
///
/// Keeps palette logic out of Riverpod providers (Clean Architecture / RULES.md).
String? libraryDetailPaletteSourceUrl({
  required LibraryItem item,
  required LibraryDetailsModel details,
}) {
  if (item.systemArtwork != null) {
    return null;
  }
  final image = item.imageUrl?.trim();
  if (image != null && image.isNotEmpty) {
    return image;
  }
  final hero = details.heroImageUrl?.trim();
  if (hero != null && hero.isNotEmpty) {
    return hero;
  }
  for (final t in details.tracks) {
    final thumb = t.thumbUrl?.trim();
    if (thumb != null && thumb.isNotEmpty) {
      return thumb;
    }
  }
  return null;
}
