import 'package:flutter/foundation.dart';

/// A robust Result type for handling success and failure states gracefully,
/// preventing the need to silently return null on errors.
abstract class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get data => isSuccess ? (this as Success<T>).value : null;
  String? get message => isFailure ? (this as Failure<T>).error : null;
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final String error;
  final Exception? exception;
  
  Failure(this.error, [this.exception]) {
    if (kDebugMode && exception != null) {
      print('Result Failure: $error -> $exception');
    }
  }
}
