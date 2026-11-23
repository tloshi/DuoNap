import 'duonap_result.dart';

/// DTOs live only in the data layer and map to and from one domain model.
abstract interface class DuoNapBaseDto<T> {
  T toDomain();

  Map<String, dynamic> toJson();
}

/// Minimal contract every repository in the project follows.
abstract interface class DuoNapBaseRepository<T> {
  Future<DuoNapResult<List<T>>> loadSince(DateTime from);

  Future<DuoNapResult<void>> save(T item);
}
