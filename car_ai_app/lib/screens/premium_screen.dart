import 'package:flutter/material.dart';
import '../services/ad_service.dart';

class PremiumScreen extends StatefulWidget {
  final String langCode;
  final VoidCallback onContinue;

  const PremiumScreen({
    Key? key,
    required this.langCode,
    required this.onContinue,
  }) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final AdService _adService = AdService();
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bool adShown = await _adService.showInterstitialAd();
      if (adShown) {
        widget.onContinue();
      } else {
        // Nếu không hiển thị được quảng cáo, vẫn cho phép tiếp tục
        widget.onContinue();
      }
    } catch (e) {
      print('Error showing ad: $e');
      // Nếu có lỗi, vẫn cho phép tiếp tục
      widget.onContinue();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              widget.langCode == 'vi' ? 'Phiên bản Premium' : 'Premium Version',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              widget.langCode == 'vi'
                  ? 'Nâng cấp lên phiên bản Premium để:\n• Không giới hạn số lần phân tích\n• Không quảng cáo\n• Hỗ trợ ưu tiên'
                  : 'Upgrade to Premium to:\n• Unlimited analysis\n• No ads\n• Priority support',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    widget.langCode == 'vi' ? 'Đóng' : 'Close',
                  ),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.langCode == 'vi'
                              ? 'Tiếp tục xem quảng cáo'
                              : 'Continue with ads',
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 