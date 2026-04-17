import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/v2/core/constants/app_colors.dart';
import 'package:tunify/v2/features/library/domain/entities/library_details.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/constants/library_details_gradient.dart';

void main() {
  group('libraryDetailBackgroundGradientColors', () {
    const item = LibraryItem(
      id: 'p',
      title: 'Playlist',
      subtitle: 'sub',
      kind: LibraryItemKind.playlist,
    );

    test('returns three stops when mid is null', () {
      final details = LibraryDetailsModel(
        type: LibraryDetailsType.playlist,
        item: item,
        searchHint: '',
        title: 'T',
        subtitlePrimary: 'a',
        tracks: const [],
        gradientTop: const Color(0xFF112233),
        backgroundGradientMid: null,
      );
      final colors = libraryDetailBackgroundGradientColors(details);
      expect(colors, hasLength(3));
      expect(colors.first, details.gradientTop);
      expect(colors.last, AppColors.nearBlack);
    });

    test('returns four stops when mid is set', () {
      final details = LibraryDetailsModel(
        type: LibraryDetailsType.playlist,
        item: item,
        searchHint: '',
        title: 'T',
        subtitlePrimary: 'a',
        tracks: const [],
        gradientTop: const Color(0xFF112233),
        backgroundGradientMid: const Color(0xFF445566),
      );
      final colors = libraryDetailBackgroundGradientColors(details);
      expect(colors, hasLength(4));
      expect(colors[1], details.backgroundGradientMid);
    });
  });
}
