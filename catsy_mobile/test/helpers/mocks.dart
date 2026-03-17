import 'package:mocktail/mocktail.dart';
import 'package:catsy_pos/core/network/api_client.dart';
import 'package:catsy_pos/core/network/connectivity_service.dart';
import 'package:catsy_pos/data/local/secure_storage/secure_storage_service.dart';
import 'package:catsy_pos/sync/sync_providers.dart';

// ── Mock classes ──────────────────────────────────────────────────────────

class MockApiClient extends Mock implements ApiClient {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockSyncStatusNotifier extends Mock implements SyncStatusNotifier {}
