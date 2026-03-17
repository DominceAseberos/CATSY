import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/staff.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  Future<Either<Failure, Staff>> login(String email, String password);
  Future<Either<Failure, Staff>> loginWithPin(String pin);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, Staff?>> getCurrentStaff();
  Future<bool> isAuthenticated();
}
