import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

/// Base UseCase class to be extended by all use cases
/// 
/// [Type] - The return type of the use case
/// [Params] - The parameters required by the use case
abstract class UseCase<Type, Params> {
  const UseCase();

  /// Execute the use case with given parameters
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case with no parameters
abstract class NoParamsUseCase<Type> {
  const NoParamsUseCase();

  /// Execute the use case without parameters
  Future<Either<Failure, Type>> call();
}

/// Stream-based use case for real-time data
abstract class StreamUseCase<Type, Params> {
  const StreamUseCase();

  /// Execute the stream use case
  Stream<Either<Failure, Type>> call(Params params);
}

/// No parameters class
class NoParams {
  const NoParams();
}