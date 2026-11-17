# flutter_7zip

A flutter plugin to decompress 7z files.

Extraction helpers close their archive handles on success and failure. Manual
`SZArchive.open` users must still call `dispose` in a `finally` block. HarmonyOS
applications must bundle `libflutter_7zip.so` from `src/`.

Run `flutter test test/extraction_lifecycle_test.dart` with the native library
on `PATH` (Windows) or `LD_LIBRARY_PATH` (Linux). The test uses the existing
example archive and verifies success, output failures and handle release.

## Getting Started

Add this to your package's pubspec.yaml file:

```yaml
dependencies:
  flutter_7zip: 
    git:
      url: https://github.com/wgh136/flutter_7zip.git
```

## Usage

### Example
```dart
import 'package:flutter_7zip/flutter_7zip.dart';

void extract(String archivePath, String outputPath) {
  var archive = SZArchive.open(archivePath);
  for (var i = 0; i < archive.numFiles; i++) {
    var file = archive.getFile(i);
    var outPath = outputPath + Platform.pathSeparator + file.name;
    if (file.isDirectory) {
      Directory(outPath).createSync(recursive: true);
    } else {
      archive.extractToFile(i, outPath);
    }
  }
  archive.dispose();
}
```

### Utilities
```dart
import 'package:flutter_7zip/flutter_7zip.dart';

void main() {
  // Extract archive to a directory
  SZArchive.extract('path/to/archive.7z', 'path/to/output');
  // Extract archive to a directory with multiple Isolates
  SZArchive.extractIsolates(
    'path/to/archive.7z', 
    'path/to/output', 
    4, // Number of isolates
  );
}
```
