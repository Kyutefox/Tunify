import 'dart:convert';

import 'package:tunify/v2/features/search/domain/entities/moods_models.dart';

abstract final class MoodsApiMapper {
  const MoodsApiMapper._();

  static List<SearchMoodTile> fromItemsJson(dynamic rawItems) {
    if (rawItems is! List) {
      return const [];
    }

    final result = <SearchMoodTile>[];
    for (final raw in rawItems) {
      if (raw is! Map<String, dynamic>) {
        continue;
      }

      final title = raw['title'];
      final browseId = raw['browse_id'];
      final params = raw['params'];

      if (title is! String || title.isEmpty) {
        continue;
      }
      if (browseId is! String || browseId.isEmpty) {
        continue;
      }

      result.add(
        SearchMoodTile(
          title: title,
          browseId: browseId,
          params: params is String && params.isNotEmpty ? params : null,
        ),
      );
    }

    return result;
  }

  static dynamic decodeMaybeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
}
