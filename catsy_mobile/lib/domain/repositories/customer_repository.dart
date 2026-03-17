import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/customer.dart';
import '../entities/loyalty_stamp.dart';

/// Abstract contract for customer / loyalty operations.
abstract class CustomerRepository {
  Future<Either<Failure, Customer>> getCustomerById(String id);
  Future<Either<Failure, Customer?>> getCustomerByQr(String qrCode);
  Future<Either<Failure, List<Customer>>> searchCustomers(String query);
  Future<Either<Failure, LoyaltyStamp>> addStamp(LoyaltyStamp stamp);
  Future<Either<Failure, int>> getStampCount(String customerId);
  Future<Either<Failure, void>> syncCustomers();
}
