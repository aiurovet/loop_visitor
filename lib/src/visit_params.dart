// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

/// Parameters for callback functions used in loops
///
class VisitParams<T> {
  /// Current entity to be processed
  ///
  T? current;

  /// Sequential number increasing before each handler call
  ///
  var currentNo = 0;

  /// Extra parameter\
  /// For instance, a cumulative list of processed entities
  ///
  dynamic extra;

  /// Flag indicating that this is the first iteration (call)
  ///
  bool get isFirst => (currentNo == 1);

  /// Flag indicating that the handler was called synchronously
  ///
  var isSyncCall = false;

  /// Number of entities taken (not skipped) already.\
  /// Normally, this should exclude the current one, though not required
  ///
  var takenNo = 0;

  /// Constructor
  ///
  VisitParams({this.current, this.extra, this.isSyncCall = false});
}
