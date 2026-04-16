import 'package:tunify/v2/core/utils/result.dart';
import 'package:tunify/v2/features/search/domain/entities/search_models.dart';

abstract class SearchRepository {
  Future<Result<SearchTypingData>> typingPreview({
    required String query,
  });

  Future<Result<SearchResultsData>> search({
    required String query,
    required SearchFilter filter,
    String? continuation,
  });
}
