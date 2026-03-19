import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/main.dart';
import 'package:tunify/shared/services/audio/audio_player_service.dart';

void main() {
  testWidgets('App starts and shows Tunify header',
      (WidgetTester tester) async {
    await tester.pumpWidget(TunifyApp(audioPlayerService: AudioPlayerService()));
    expect(find.text('Tunify'), findsOneWidget);
    expect(find.text('Search songs, artists, and more'), findsOneWidget);
  });
}
