import 'package:meta/meta.dart';

@immutable
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Extension methods for easier usage
extension ResultExtensions<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final data) => data,
        Failure() => null,
      };

  AppError? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final error) => error,
      };

  // Map the success value
  Result<U> map<U>(U Function(T) mapper) => switch (this) {
        Success(data: final data) => Success(mapper(data)),
        Failure(error: final error) => Failure(error),
      };

  // FlatMap for chaining operations
  Result<U> flatMap<U>(Result<U> Function(T) mapper) => switch (this) {
        Success(data: final data) => mapper(data),
        Failure(error: final error) => Failure(error),
      };

  // Handle both success and failure cases
  U fold<U>(U Function(T) onSuccess, U Function(AppError) onFailure) =>
      switch (this) {
        Success(data: final data) => onSuccess(data),
        Failure(error: final error) => onFailure(error),
      };
}

// Comprehensive error types
@immutable
sealed class AppError {
  final String message;
  final int? code;
  final Object? originalError;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });
}

final class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
  });
}

final class ApiError extends AppError {
  final int statusCode;

  const ApiError({
    required super.message,
    required this.statusCode,
    super.originalError,
  });
}

final class CacheError extends AppError {
  const CacheError({
    required super.message,
    super.originalError,
  });
}

final class ConfigurationError extends AppError {
  const ConfigurationError({
    required super.message,
    super.originalError,
  });
}

final class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError({
    required super.message,
    required this.fieldErrors,
    super.originalError,
  });
}

final class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.originalError,
  });
}
