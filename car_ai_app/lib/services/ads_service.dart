import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  static const String _removeAdsId = 'car_ai_remove_ads';
  static const int _freeScans = 2;
  
  InterstitialAd? _interstitialAd;
  bool _isPremium = false;
  int _scanCount = 0;
  String? _adUnitId;
  
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _adUnitId = await _getAdUnitId();
    await _loadInterstitialAd();
    await _loadPurchaseStatus();
    await _loadScanCount();
  }

  Future<void> _loadInterstitialAd() async {
    if (_adUnitId == null) return;
    
    await InterstitialAd.load(
      adUnitId: _adUnitId!,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Failed to load interstitial ad: $error');
        },
      ),
    );
  }

  Future<String> _getAdUnitId() async {
    try {
      const platform = MethodChannel('com.example.car_ai_app/ads');
      final String adUnitId = await platform.invokeMethod('getInterstitialAdUnitId');
      return adUnitId;
    } on PlatformException {
      // Fallback to test ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712';
    }
  }

  Future<void> _loadPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
  }

  Future<void> _loadScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    _scanCount = prefs.getInt('scan_count') ?? 0;
  }

  Future<void> incrementScanCount() async {
    _scanCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scan_count', _scanCount);
  }

  bool shouldShowAd() {
    return !_isPremium && _scanCount >= _freeScans;
  }

  Future<void> showAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      await _loadInterstitialAd();
    }
  }

  Future<bool> purchaseRemoveAds() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) return false;

    final ProductDetailsResponse response = await InAppPurchase.instance
        .queryProductDetails({_removeAdsId});

    if (response.notFoundIDs.isNotEmpty) return false;

    final ProductDetails product = response.productDetails.first;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    // Lắng nghe kết quả giao dịch
    final purchaseCompleter = Completer<bool>();
    late StreamSubscription<List<PurchaseDetails>> subscription;
    subscription = InAppPurchase.instance.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.productID == _removeAdsId) {
          if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
            await setPremiumStatus(true);
            await InAppPurchase.instance.completePurchase(purchase);
            purchaseCompleter.complete(true);
            await subscription.cancel();
          } else if (purchase.status == PurchaseStatus.error || purchase.status == PurchaseStatus.canceled) {
            purchaseCompleter.complete(false);
            await subscription.cancel();
          }
        }
      }
    });

    try {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      return await purchaseCompleter.future;
    } catch (e) {
      print('Error purchasing: $e');
      await subscription.cancel();
      return false;
    }
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', isPremium);
  }

  bool get isPremium => _isPremium;
  int get scanCount => _scanCount;
  int get remainingFreeScans => _freeScans - _scanCount;
} 