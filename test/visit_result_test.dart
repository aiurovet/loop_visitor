import 'package:file/local.dart';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:test/test.dart';

/// Test class for the asynchronous (non-blocking) mode
///
extension TestStream<T> on Stream<T> {
  /// Test method
  ///
  Future<void> forEachOf({List<T>? pileup, VisitHandler<T>? handler}) async {
    final params = VisitParams<T>(
        pileup: pileup, isSyncCall: handler is VisitHandlerSync<T>);
    var result = VisitResult.take;

    await for (final x in this) {
      ++params.currentNo;
      params.current = x;

      if (handler != null) {
        if (params.isSyncCall) {
          result = handler(params) as VisitResult;
        } else {
          result = await handler(params);
        }
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        break;
      }
    }
  }
}

/// Test class for the synchronous (blocking) mode
///
extension TestList<T> on List<T> {
  /// Test method
  ///
  void forEachOfSync({List<T>? pileup, VisitHandlerSync? handler}) {
    final params = VisitParams(pileup: pileup, isSyncCall: true);
    var result = VisitResult.take;

    any((x) {
      ++params.currentNo;
      params.current = x;

      if (handler != null) {
        result = handler(params);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        return true; // break from the loop
      }

      return false; // continue the loop
    });
  }
}

/// Test entry point
///
void main() {
  List<int>? list;
  Stream<int>? stream;
  final fileSystem = LocalFileSystem();

  setUp(() {
    list = <int>[11, 12, 13];
    stream = Stream.fromIterable(list!);
  });
  group('Async -', () {
    test('Full simple loop', () async {
      var count = 0;

      await stream!.forEachOf(handler: (params) async {
        ++count;
        return VisitResult.take;
      });

      expect(count, 3);
    });
    test('Full simple loop with async handler', () async {
      var count = 0;

      await stream!.forEachOf(handler: (params) async {
        ++count;
        await fileSystem.currentDirectory.exists();
        return VisitResult.take;
      });

      expect(count, 3);
    });
    test('Full pileup loop', () async {
      final pileup = <int>[];

      await stream!.forEachOf(
          pileup: pileup,
          handler: (params) async {
            if (params.currentNo <= 1) {
              pileup.clear();
            }
            pileup.add(params.current!);
            return VisitResult.take;
          });

      expect(pileup.length, 3);
    });
    test('Partial simple loop', () async {
      var count = 0;

      await stream!.forEachOf(handler: (params) async {
        ++count;

        return (count >= 2 ? VisitResult.takeAndStop : VisitResult.take);
      });

      expect(count, 2);
    });
    test('Partial pileup loop', () async {
      var count = 0;
      final pileup = <int>[];

      await stream!.forEachOf(
          pileup: pileup,
          handler: (params) async {
            ++count;
            if (params.currentNo <= 1) {
              pileup.clear();
            }
            pileup.add(params.current!);
            return (count >= 2 ? VisitResult.takeAndStop : VisitResult.take);
          });

      expect(pileup.length, 2);
    });
  });
  group('Sync -', () {
    test('Full simple loop', () {
      var count = 0;

      list!.forEachOfSync(handler: (params) {
        ++count;
        return VisitResult.take;
      });

      expect(count, 3);
    });
    test('Full pileup loop', () {
      final pileup = <int>[];

      list!.forEachOfSync(
          pileup: pileup,
          handler: (params) {
            if (params.currentNo <= 1) {
              pileup.clear();
            }
            pileup.add(params.current);
            return VisitResult.take;
          });

      expect(pileup.length, 3);
    });
    test('Partial simple loop', () {
      var count = 0;

      list!.forEachOfSync(handler: (params) {
        ++count;

        return (count >= 2 ? VisitResult.takeAndStop : VisitResult.take);
      });

      expect(count, 2);
    });
    test('Partial pileup loop', () {
      var count = 0;
      final pileup = <int>[];

      list!.forEachOfSync(
          pileup: pileup,
          handler: (params) {
            ++count;
            if (params.currentNo <= 1) {
              pileup.clear();
            }
            pileup.add(params.current);
            return (count >= 2 ? VisitResult.takeAndStop : VisitResult.take);
          });

      expect(pileup.length, 2);
    });
  });
}
