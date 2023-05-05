// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

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
Future<VisitResult> filterFiles(VisitParams<DirEntryInfo> params) async =>
    filterFilesSync(params);

/// Filter (non-blocking)
///
VisitResult filterFilesSync(VisitParams<DirEntryInfo> params) {
  final myEntity = params.current;
  final entity = myEntity?.entity;
  final type = myEntity?.type;

  if ((entity == null) || (type != FileSystemEntityType.file)) {
    return VisitResult.skip;
  }

  final takenNo = params.takenNo + 1;
  print('$takenNo: ${entity.path}');

  final pileup = params.pileup as List<String>?;

  if (params.currentNo <= 1) {
    pileup?.clear();
  }

  pileup?.add(entity.path);

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
      pileup: pileup,
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

    if (result.isTake) {
      ++params.takenNo;
    }

    if (result.isStop) {
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
      current: myEntity, pileup: pileup, isSyncCall: true);

  var dirList = fs.directory(dirName).listSync();

  for (final entity in dirList) {
    ++params.currentNo;

    myEntity.entity = entity;
    myEntity.type = entity.statSync().type;

    if (handler != null) {
      result = handler(params);
    }

    if (result.isTake) {
      ++params.takenNo;
    }

    if (result.isStop) {
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
      count = getTopFilesSync(fs, arg, pileup, filterFilesSync);
    } else {
      count = await getTopFiles(fs, arg, pileup, filterFiles);
    }

    print('''
Total: $count file${count == 1 ? '' : 's'}, the pileup contains ${pileup.length} path(s):

$pileup
''');
  }
}
