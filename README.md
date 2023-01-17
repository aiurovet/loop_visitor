A way to loop through entities calling a user-defined handler on every iteration and process returned result

## Features

- Allows to process data without accumulation (e.g. process files in directory or lines in a large text file).

- Allows to react on various situations inside the caller (loop) upon getting the return value (see VisitResult).

- Allows to use either synchronous (blocking) or asynchronous (non-blocking) iteration handlers in asynchronous
  loops (useful in FileSystem-related operations when both synchronous and asynchronous versions are required).

## Usage

The same can be found in the `example/loop_visitor_example.dart`

```dart
import 'dart:async';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:loop_visitor/loop_visitor.dart';

/// Application-specific data class
///
class DirEntryInfo {
  /// Number of files to limit to
  ///
  static const int limit = 9;

  /// Directory entry
  ///
  FileSystemEntity? entity;

  /// Type of entry.\
  /// Yes, `entity is File` would work too,
  /// but the purpose is to show something more complicated
  ///
  var type = FileSystemEntityType.notFound;
}

/// Filter (non-blocking)
///
VisitResult filterFiles(VisitParams<DirEntryInfo> params) {
  final myEntity = params.current;
  final entity = myEntity?.entity;
  final type = myEntity?.type;

  if ((entity == null) || (type != FileSystemEntityType.file)) {
    return VisitResult.skip;
  }

  final takenNo = params.takenNo + 1;
  print('$takenNo: ${entity.path}');

  final pileup = params.extra as List<String>;

  if (params.currentNo <= 1) {
    pileup.clear();
  }

  pileup.add(entity.path);

  return (takenNo >= DirEntryInfo.limit
      ? VisitResult.takeAndStop
      : VisitResult.take);
}

/// Looping through directory entries (non-blocking)
///
Future<int> getTopFiles(FileSystem fs, String dirName, List<String> pileup,
    VisitHandler<DirEntryInfo>? handler) async {
  var myEntity = DirEntryInfo();
  var result = VisitResult.take;
  var params = VisitParams<DirEntryInfo>(
      current: myEntity,
      extra: pileup,
      isSyncCall: (handler is VisitHandlerSync));

  var dirList = fs.directory(dirName).list();

  await for (final entity in dirList) {
    ++params.currentNo;

    myEntity.entity = entity;
    myEntity.type =
        (params.isSyncCall ? entity.statSync() : await entity.stat()).type;

    if (handler != null) {
      if (params.isSyncCall) {
        result = handler(params) as VisitResult;
      } else {
        result = await handler(params);
      }
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params.takenNo;
    }

    if ((result == VisitResult.takeAndStop) ||
        (result == VisitResult.skipAndStop)) {
      break;
    }
  }

  return params.takenNo;
}

/// Looping through directory entries (blocking)
///
int getTopFilesSync(FileSystem fs, String dirName, List<String> pileup,
    VisitHandlerSync<DirEntryInfo>? handler) {
  var myEntity = DirEntryInfo();
  var result = VisitResult.take;
  var params = VisitParams<DirEntryInfo>(
      current: myEntity, extra: pileup, isSyncCall: true);

  var dirList = fs.directory(dirName).listSync();

  for (final entity in dirList) {
    ++params.currentNo;

    myEntity.entity = entity;
    myEntity.type = entity.statSync().type;

    if (handler != null) {
      result = handler(params);
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params.takenNo;
    }

    if ((result == VisitResult.takeAndStop) ||
        (result == VisitResult.skipAndStop)) {
      break;
    }
  }

  return params.takenNo;
}

/// Entry point
///
Future<void> main(List<String> args) async {
  final fs = LocalFileSystem();

  final isSync = args.contains('-s');
  final argsEx = [...args.where((x) => !x.startsWith('-'))];

  if (argsEx.isEmpty) {
    argsEx.add(fs.currentDirectory.path);
  }

  var count = 0;
  var pileup = <String>[];

  for (final arg in argsEx) {
    print('''
--- Directory: "$arg"
''');

    if (isSync) {
      count = getTopFilesSync(fs, arg, pileup, filterFiles);
    } else {
      count = await getTopFiles(fs, arg, pileup, filterFiles);
    }

    print('''
Total: $count file${count == 1 ? '' : 's'}, the pileup contains ${pileup.length} path(s):

$pileup
''');
  }
}
```
