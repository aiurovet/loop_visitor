// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';

import 'package:loop_visitor/loop_visitor.dart';

/// Callback function definition to be used in loops (non-blocking)
///
typedef VisitHandler<T> = FutureOr<VisitResult> Function(VisitParams<T> params);

/// Callback function definition to be used in loops (blocking)
/// can be used in both non-blocking and blocking loops.\
/// The latter is recommended when no synchronous call is made
/// inside it (e.g. just printing the current content), but the
/// calling loop is asynchronous
///
typedef VisitHandlerSync<T> = VisitResult Function(VisitParams<T> params);
