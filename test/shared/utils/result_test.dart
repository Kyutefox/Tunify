import 'package:flutter_test/flutter_test.dart';
import 'package:tunify/core/utils/result.dart';

void main() {
  group('Result', () {
    test('Ok exposes value and isOk', () {
      const r = Ok<int, String>(42);
      expect(r.isOk, isTrue);
      expect(r.isErr, isFalse);
      expect(r.okOrNull, 42);
      expect(r.errOrNull, isNull);
      expect(r.when(ok: (v) => v * 2, err: (_) => 0), 84);
    });

    test('Err exposes error and isErr', () {
      const r = Err<int, String>('fail');
      expect(r.isOk, isFalse);
      expect(r.isErr, isTrue);
      expect(r.okOrNull, isNull);
      expect(r.errOrNull, 'fail');
      expect(r.when(ok: (_) => 0, err: (e) => e.length), 4);
    });

    test('guard returns Ok on success', () async {
      final r = await Result.guard(() async => 1);
      expect(r.isOk, isTrue);
      expect(r.okOrNull, 1);
    });

    test('guard returns Err on exception', () async {
      final r = await Result.guard<int>(() async => throw Exception('oops'));
      expect(r.isErr, isTrue);
      expect(r.errOrNull, contains('oops'));
    });
  });
}
