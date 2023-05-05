// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';

import 'package:loop_visitor/loop_visitor.dart';

/// Callback function definition to be used in loops (non-blocking)
///
typedef VisitHandler<T> = Future<VisitResult> Function(VisitParams<T> params);

/// Callback function definition to be used in loops (blocking)
///
typedef VisitHandlerSync<T> = VisitResult Function(VisitParams<T> params);
