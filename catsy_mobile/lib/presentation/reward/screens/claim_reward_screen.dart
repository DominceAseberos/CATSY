import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../domain/models/reward_result.dart';
import '../../../../data/local/providers.dart';
import '../../auth/providers/auth_provider.dart';

// ── State machine ─────────────────────────────────────────────────────────────

enum _ClaimState {
  initial,
  loading,
  noInternet,
  invalidCode,
  alreadyClaimed,
  success,
}

class _ClaimScreenState {
  final _ClaimState state;
  final RewardSuccess? successData;
  const _ClaimScreenState._(this.state, [this.successData]);
  factory _ClaimScreenState.initial() =>
      const _ClaimScreenState._(_ClaimState.initial);
  factory _ClaimScreenState.loading() =>
      const _ClaimScreenState._(_ClaimState.loading);
  factory _ClaimScreenState.noInternet() =>
      const _ClaimScreenState._(_ClaimState.noInternet);
  factory _ClaimScreenState.invalidCode() =>
      const _ClaimScreenState._(_ClaimState.invalidCode);
  factory _ClaimScreenState.alreadyClaimed() =>
      const _ClaimScreenState._(_ClaimState.alreadyClaimed);
  factory _ClaimScreenState.success(RewardSuccess data) =>
      _ClaimScreenState._(_ClaimState.success, data);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ClaimRewardScreen extends ConsumerStatefulWidget {
  const ClaimRewardScreen({super.key});

  @override
  ConsumerState<ClaimRewardScreen> createState() => _ClaimRewardScreenState();
}

class _ClaimRewardScreenState extends ConsumerState<ClaimRewardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  _ClaimScreenState _claimState = _ClaimScreenState.initial();
  bool _scannerActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0 && !_scannerActive) {
        _scannerController.start();
        _scannerActive = true;
      } else if (_tabController.index == 1 && _scannerActive) {
        _scannerController.stop();
        _scannerActive = false;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────────────

  Future<void> _processCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() => _claimState = _ClaimScreenState.loading());

    // Retrieve staff ID from auth session
    final authState = ref.read(authNotifierProvider);
    final staffId = authState.staff?.id ?? 'unknown-staff';

    final result = await ref
        .read(rewardRepositoryProvider)
        .validateAndClaimReward(trimmed, staffId);

    if (!mounted) return;

    setState(() {
      switch (result) {
        case RewardSuccess():
          _claimState = _ClaimScreenState.success(result);
        case RewardAlreadyClaimed():
          _claimState = _ClaimScreenState.alreadyClaimed();
        case RewardInvalidCode():
          _claimState = _ClaimScreenState.invalidCode();
        case RewardNoInternet():
          _claimState = _ClaimScreenState.noInternet();
      }
    });
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (_claimState.state == _ClaimState.loading) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null) {
      _scannerController.stop();
      _scannerActive = false;
      _processCode(code);
    }
  }

  void _reset() {
    setState(() => _claimState = _ClaimScreenState.initial());
    _codeController.clear();
    if (_tabController.index == 0) {
      _scannerController.start();
      _scannerActive = true;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Reward'),
        bottom:
            _claimState.state == _ClaimState.initial ||
                _claimState.state == _ClaimState.loading
            ? TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
                  Tab(icon: Icon(Icons.keyboard), text: 'Enter Code'),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_claimState.state) {
      case _ClaimState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Validating reward…'),
            ],
          ),
        );

      case _ClaimState.noInternet:
        return _buildStatusCard(
          icon: Icons.wifi_off,
          iconColor: AppColors.warning,
          title: 'No Internet Connection',
          subtitle:
              'Please connect to the internet to validate rewards.\nReward codes must be verified online to prevent double-claiming.',
          actionLabel: 'Try Again',
          onAction: _reset,
        );

      case _ClaimState.invalidCode:
        return _buildStatusCard(
          icon: Icons.error_outline,
          iconColor: AppColors.error,
          title: 'Invalid Reward Code',
          subtitle:
              'This code does not match any reward in the system.\nPlease check the code and try again.',
          actionLabel: 'Try Again',
          onAction: _reset,
        );

      case _ClaimState.alreadyClaimed:
        return _buildStatusCard(
          icon: Icons.block,
          iconColor: Colors.orange,
          title: 'Already Claimed',
          subtitle:
              'This reward has already been redeemed.\nEach reward code can only be used once.',
          actionLabel: 'Try Another Code',
          onAction: _reset,
        );

      case _ClaimState.success:
        return _buildSuccessCard(_claimState.successData!);

      case _ClaimState.initial:
        return TabBarView(
          controller: _tabController,
          children: [_buildQrTab(), _buildManualTab()],
        );
    }
  }

  // ── QR scanner tab ────────────────────────────────────────────────────

  Widget _buildQrTab() {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onQrDetect),
        // Viewfinder overlay
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Hint label
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Point camera at the reward QR code',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        // Torch + flip buttons
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.flash_on, color: Colors.white),
                  onPressed: () => _scannerController.toggleTorch(),
                ),
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white),
                  onPressed: () => _scannerController.switchCamera(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Manual code entry tab ─────────────────────────────────────────────

  Widget _buildManualTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.card_giftcard, size: 64, color: Colors.purple),
          const SizedBox(height: 24),
          Text(
            'Enter the reward code printed on the\ncustomer\'s receipt or card.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Reward Code',
              hintText: 'e.g. REWARD-ABC123',
              prefixIcon: Icon(Icons.confirmation_number_outlined),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _processCode(_codeController.text),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _processCode(_codeController.text),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Validate & Claim'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
          const Spacer(),
          // "Requires internet" label
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_lock, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Requires Internet — codes are validated online to prevent double-claiming.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── Reusable status card ──────────────────────────────────────────────

  Widget _buildStatusCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success card ──────────────────────────────────────────────────────

  Widget _buildSuccessCard(RewardSuccess data) {
    final reward = data.reward;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 72,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reward Claimed! 🎉',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: AppColors.success.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 36,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reward.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (reward.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        reward.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Loyalty stamps reset to 0.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _reset,
              child: const Text('Claim Another Reward'),
            ),
          ],
        ),
      ),
    );
  }
}
