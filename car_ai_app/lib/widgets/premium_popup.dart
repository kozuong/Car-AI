import 'package:flutter/material.dart';
import '../services/ads_service.dart';

class PremiumPopup extends StatelessWidget {
  final String langCode;
  final VoidCallback onContinueWithAds;
  final VoidCallback onPurchase;

  const PremiumPopup({
    super.key,
    required this.langCode,
    required this.onContinueWithAds,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.star,
                size: 48,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isVi ? 'Nâng cấp lên Premium' : 'Upgrade to Premium',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isVi 
                ? 'Tận hưởng trải nghiệm không quảng cáo vĩnh viễn chỉ với \$2'
                : 'Enjoy ad-free experience forever for just \$2',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildFeatureRow(
              icon: Icons.block,
              text: isVi ? 'Không quảng cáo' : 'No Ads',
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.all_inclusive,
              text: isVi ? 'Vĩnh viễn' : 'Forever',
            ),
            const SizedBox(height: 12),
            _buildFeatureRow(
              icon: Icons.support_agent,
              text: isVi ? 'Hỗ trợ ưu tiên' : 'Priority Support',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isVi ? 'Mua ngay \$2' : 'Buy Now \$2',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onContinueWithAds,
              child: Text(
                isVi ? 'Tiếp tục với quảng cáo' : 'Continue with Ads',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
} 