import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tunify/v2/features/auth/presentation/providers/auth_providers.dart';
import 'package:tunify/v2/features/library/data/library_collection_gateway.dart';

typedef LibraryCollectionApiKey = ({String target, String browseId});

final libraryCollectionGatewayProvider = Provider<LibraryCollectionGateway>((ref) {
  return LibraryCollectionGateway(api: ref.watch(tunifyApiClientProvider));
});

/// Whether the collection is saved (album/playlist) or followed (artist).
final libraryCollectionSavedProvider =
    FutureProvider.autoDispose.family<bool, LibraryCollectionApiKey>((ref, key) async {
  final gateway = ref.watch(libraryCollectionGatewayProvider);
  return gateway.fetchInLibrary(target: key.target, browseId: key.browseId);
});
