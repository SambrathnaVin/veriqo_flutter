import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_theme.dart';
import '../../widgets/widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  MobileScannerController? _ctrl;
  bool _scanning = false;
  String? _result;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController();
    _scanning = true;
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && _scanning) {
      setState(() {
        _scanning = false;
        _result = code;
      });
      _ctrl?.stop();
    }
  }

  void _reset() {
    setState(() {
      _scanning = true;
      _result = null;
    });
    _ctrl?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Product Scanner'),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _torchOn ? AppColors.warning : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _ctrl?.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _result != null
                ? _ResultView(barcode: _result!, onReset: _reset)
                : Stack(
                    children: [
                      MobileScanner(
                        controller: _ctrl,
                        onDetect: _onDetect,
                      ),
                      // Overlay frame
                      Center(
                        child: Container(
                          width: 240, height: 240,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.accent, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner_rounded,
                                  color: Colors.white54, size: 64),
                              SizedBox(height: 12),
                              Text('Aim at product barcode\nor QR code',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product Origin Scan', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
                )),
                const SizedBox(height: 8),
                const Text(
                  'Scan a product barcode or QR code to verify its origin, manufacturer, and authenticity.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final String barcode;
  final VoidCallback onReset;

  const _ResultView({required this.barcode, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceCard,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 46),
              ),
              const SizedBox(height: 24),
              const Text('Code Detected', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    const Text('Barcode / QR Value', style: TextStyle(
                      fontSize: 12, color: AppColors.textMuted, letterSpacing: 1,
                    )),
                    const SizedBox(height: 8),
                    Text(
                      barcode,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Simulated origin info
              _OriginCard(barcode: barcode),
              const SizedBox(height: 24),
              VButton(
                label: 'Scan Again',
                onPressed: onReset,
                icon: Icons.refresh_rounded,
                outlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OriginCard extends StatelessWidget {
  final String barcode;
  const _OriginCard({required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
              const SizedBox(width: 8),
              const Text('Origin Verification', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.info,
              )),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your Veriqo store to enable real-time origin tracing and product authenticity verification using this barcode.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
