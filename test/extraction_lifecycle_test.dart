import 'dart:io';

import 'package:flutter_7zip/flutter_7zip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporary;
  late File input;

  setUp(() {
    temporary = Directory.systemTemp.createTempSync('7zip_lifecycle_');
    input = File('example/test.7z').copySync('${temporary.path}/input.7z');
  });

  tearDown(() {
    temporary.deleteSync(recursive: true);
  });

  void expectReleased() {
    if (Platform.isLinux) {
      final handles = Directory('/proc/self/fd').listSync().whereType<Link>();
      expect(handles.where((link) {
        try {
          return link.targetSync() == input.path;
        } on FileSystemException {
          return false;
        }
      }), isEmpty);
    }
    // Windows refuses deletion while the native archive handle remains open.
    input.deleteSync();
    expect(input.existsSync(), isFalse);
  }

  test('parallel extraction releases its discovery and worker handles',
      () async {
    final output = Directory('${temporary.path}/output');
    await SZArchive.extractIsolates(input.path, output.path, 4);
    expect(output.listSync(recursive: true).whereType<File>(), isNotEmpty);
    expectReleased();
  });

  for (final parallel in [false, true]) {
    test('${parallel ? 'parallel' : 'sequential'} extraction closes on failure',
        () async {
      final blocked = File('${temporary.path}/blocked')
        ..writeAsStringSync('file');
      await expectLater(
        Future<void>.sync(() => parallel
            ? SZArchive.extractIsolates(input.path, blocked.path, 4)
            : SZArchive.extract(input.path, blocked.path)),
        throwsA(isA<FileSystemException>()),
      );
      expectReleased();
    });
  }

  test('invalid worker count fails before opening the archive', () async {
    for (final workers in [0, -1]) {
      await expectLater(
        SZArchive.extractIsolates(input.path, temporary.path, workers),
        throwsArgumentError,
      );
    }
    expectReleased();
  });
}
