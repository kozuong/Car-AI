import 'package:flutter/material.dart';

class PremiumPage extends StatelessWidget {
  final String langCode;
  final VoidCallback onContinueWithAds;
  final VoidCallback onPurchasePremium;

  const PremiumPage({
    Key? key,
    required this.langCode,
    required this.onContinueWithAds,
    required this.onPurchasePremium,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isVi = langCode == 'vi';
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.star,
                      size: 80,
                      color: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isVi ? 'Nâng cấp lên Premium' : 'Upgrade to Premium',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isVi 
                        ? 'Bạn đã sử dụng hết lượt quét miễn phí. Nâng cấp lên Premium để:\n\n• Quét không giới hạn\n• Không quảng cáo\n• Tính năng nâng cao'
                        : 'You have used all free scans. Upgrade to Premium for:\n\n• Unlimited scans\n• No ads\n• Advanced features',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: onPurchasePremium,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isVi ? 'Nâng cấp ngay' : 'Upgrade Now',
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: onContinueWithAds,
                child: Text(
                  isVi ? 'Tiếp tục với quảng cáo' : 'Continue with ads',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 