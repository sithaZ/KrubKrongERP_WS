import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/staff_entity.dart';

/// Staff repository interface
abstract class StaffRepository {
  Future<Either<Failure, List<StaffMember>>> getStaffMembers();
  Future<Either<Failure, StaffMember>> getStaffById(String id);
  Future<Either<Failure, StaffMember>> createStaffMember(StaffMember staff);
  Future<Either<Failure, StaffMember>> updateStaffMember(StaffMember staff);
  Future<Either<Failure, void>> deleteStaffMember(String id);
}
