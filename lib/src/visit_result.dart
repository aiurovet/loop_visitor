// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

/// Enumeration used by VisitHandler and VisitHandlerSync as return type
/// informing the caller of action to undertake while that loops through
/// entites like each line in a stream or a file list element
///
enum VisitResult {
  /// Accept the result of processing and continue the loop
  ///
  take,

  /// Accept the result of processing and continue the loop
  ///
  takeAndStop,

  /// Ignore the result of processing and stop the loop
  ///
  skip,

  /// Ignore the result of processing and stop the loop
  ///
  skipAndStop;

  /// Flag indicating the result should be taken
  ///
  bool get isTake => ((this == take) || (this == takeAndStop));

  /// Flag indicating the result should be skipped
  ///
  bool get isSkip => ((this == skip) || (this == skipAndStop));

  /// Flag indicating immediate stop is required
  ///
  bool get isStop => ((this == takeAndStop) || (this == skipAndStop));
}
