import 'package:flutter/material.dart';
import 'package:tunify/v2/features/library/domain/entities/library_item.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_details_screen.dart';
import 'package:tunify/v2/features/library/presentation/screens/library_folder_screen.dart';

void openLibraryItemFromList(BuildContext context, LibraryItem item) {
  if (item.kind == LibraryItemKind.folder) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LibraryFolderScreen(
          folderId: item.id,
          folderName: item.title,
        ),
      ),
    );
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => LibraryDetailsScreen(item: item),
    ),
  );
}
