import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:catsy_pos/core/error/failures.dart';
import 'package:catsy_pos/domain/entities/customer.dart';
import 'package:catsy_pos/domain/entities/loyalty_stamp.dart';
import 'package:catsy_pos/domain/repositories/customer_repository.dart';
import 'package:catsy_pos/data/local/database/daos/customer_dao.dart';
import 'package:catsy_pos/data/local/database/app_database.dart';

/// Phase 1 — LOCAL ONLY. Uses CustomerDao.
class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerDao _customerDao;

  CustomerRepositoryImpl({required CustomerDao customerDao})
    : _customerDao = customerDao;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final row = await _customerDao.getCustomerById(id);
      if (row == null) {
        return const Left(CacheFailure(message: 'Customer not found'));
      }
      return Right(_mapToCustomer(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get customer: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer?>> getCustomerByQr(String qrCode) async {
    try {
      final row = await _customerDao.getCustomerByQRCode(qrCode);
      if (row == null) return const Right(null);
      return Right(_mapToCustomer(row));
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get customer by QR: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Customer>>> searchCustomers(String query) async {
    try {
      final rows = await _customerDao.searchCustomers(query);
      return Right(rows.map(_mapToCustomer).toList());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to search customers: $e'));
    }
  }

  @override
  Future<Either<Failure, LoyaltyStamp>> addStamp(LoyaltyStamp stamp) async {
    try {
      final id = stamp.id.isEmpty ? _uuid.v4() : stamp.id;
      await _customerDao.insertStampLog(
        LoyaltyStampsTableCompanion(
          id: Value(id),
          customerId: Value(stamp.customerId),
          orderId: Value(stamp.orderId),
          staffId: Value(stamp.staffId),
          stampsAdded: Value(stamp.stampsAdded),
          createdAt: Value(stamp.createdAt),
        ),
      );

      // Update total stamps on customer
      final customer = await _customerDao.getCustomerById(stamp.customerId);
      if (customer != null) {
        final newTotal = customer.totalStamps + stamp.stampsAdded;
        await _customerDao.updateStamps(stamp.customerId, newTotal);
      }

      return Right(
        LoyaltyStamp(
          id: id,
          customerId: stamp.customerId,
          orderId: stamp.orderId,
          staffId: stamp.staffId,
          stampsAdded: stamp.stampsAdded,
          createdAt: stamp.createdAt,
        ),
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to add stamp: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getStampCount(String customerId) async {
    try {
      final row = await _customerDao.getCustomerById(customerId);
      return Right(row?.totalStamps ?? 0);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get stamp count: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncCustomers() async {
    // Phase 1: No-op
    return const Right(null);
  }

  Customer _mapToCustomer(CustomersTableData r) => Customer(
    id: r.id,
    name: r.name,
    email: r.email,
    phone: r.phone,
    qrCode: r.qrCode,
    totalStamps: r.totalStamps,
    rewardsRedeemed: r.rewardsRedeemed,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );
}
