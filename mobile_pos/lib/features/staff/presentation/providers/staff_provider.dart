import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/staff_remote_datasource.dart';
import '../../data/repositories/staff_repository_impl.dart';
import '../../domain/repositories/staff_repository.dart';
import '../../domain/entities/employee.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';

/// Staff remote data source provider
final staffRemoteDataSourceProvider = Provider<StaffRemoteDataSource>((ref) {
  final dio = ref.watch(httpClientInstanceProvider);
  return StaffRemoteDataSourceImpl(dio);
});

/// Staff repository provider
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final remoteDataSource = ref.watch(staffRemoteDataSourceProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return StaffRepositoryImpl(remoteDataSource, networkInfo);
});

/// Employees list provider
final employeesProvider = FutureProvider<List<Employee>>((ref) async {
  final repository = ref.watch(staffRepositoryProvider);
  final result = await repository.getEmployees();
  
  return result.fold(
    (failure) => throw failure,
    (employees) => employees,
  );
});

/// Staff management state notifier
class StaffNotifier extends StateNotifier<StaffState> {
  final StaffRepository _repository;

  StaffNotifier(this._repository) : super(const StaffState.initial());

  Future<void> addEmployee(Employee employee, Function(Map<String, dynamic>) onSuccess) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.createEmployee(employee);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (data) {
        state = state.copyWith(isLoading: false, error: null);
        onSuccess(data);
      },
    );
  }

  Future<void> deactivateEmployee(String id) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.deactivateEmployee(id);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) => state = state.copyWith(isLoading: false, error: null),
    );
  }

  Future<void> updateEmployee(Employee employee, Function() onSuccess) async {
    state = state.copyWith(isLoading: true);
    final result = await _repository.updateEmployee(employee);
    
    result.fold(
      (failure) => state = state.copyWith(isLoading: false, error: failure.message),
      (_) {
        state = state.copyWith(isLoading: false, error: null);
        onSuccess();
      },
    );
  }
}

class StaffState {
  final bool isLoading;
  final String? error;

  const StaffState({required this.isLoading, this.error});
  const StaffState.initial() : isLoading = false, error = null;

  StaffState copyWith({bool? isLoading, String? error}) {
    return StaffState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final staffNotifierProvider = StateNotifierProvider<StaffNotifier, StaffState>((ref) {
  return StaffNotifier(ref.watch(staffRepositoryProvider));
});
