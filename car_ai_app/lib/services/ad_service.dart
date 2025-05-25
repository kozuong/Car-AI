import 'dart:io' show Platform;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Test Ad Unit IDs
  static const String _adUnitIdAndroid = 'ca-app-pub-3940256099942544/1033173712'; // Test ID
  static const String _adUnitIdIOS = 'ca-app-pub-3940256099942544/4411468910'; // Test ID
  static const String _scanCountKey = 'scan_count';
  static const int _maxFreeScans = 2; // 2 lần miễn phí

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _hasShownPremium = false;
  bool _isPremium = false;
  Completer<void>? _adCompleter;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  Future<void> _loadInterstitialAd() async {
      await InterstitialAd.load(
        adUnitId: Platform.isAndroid ? _adUnitIdAndroid : _adUnitIdIOS,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
            _interstitialAd = ad;
          _isAdLoaded = true;
          },
        onAdFailedToLoad: (error) {
          _isAdLoaded = false;
          },
        ),
      );
  }

  Future<bool> incrementScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;
    currentCount++;
    await prefs.setInt(_scanCountKey, currentCount);
    return currentCount > _maxFreeScans;
    }
    
  Future<bool> shouldShowPremium() async {
    if (_isPremium) return false; // Nếu đã mua Premium thì không hiện nữa
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_scanCountKey) ?? 0;
    return currentCount == _maxFreeScans + 1; // Hiện Premium page sau khi quét xong lần thứ 2
  }

  Future<void> setPremiumShown() async {
    _hasShownPremium = true;
  }

  Future<void> showAd() async {
    if (_isAdLoaded && _interstitialAd != null) {
      _adCompleter = Completer<void>();
      
      // Thêm listener để đảm bảo người dùng xem hết quảng cáo
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          _adCompleter?.complete(); // Hoàn thành khi người dùng xem hết quảng cáo
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
          _loadInterstitialAd();
          _adCompleter?.completeError(error); // Báo lỗi nếu không hiện được quảng cáo
        },
      );

      // Hiển thị quảng cáo
      await _interstitialAd!.show();
      
      // Đợi cho đến khi người dùng xem hết quảng cáo
      try {
        await _adCompleter?.future;
      } catch (e) {
        // Nếu có lỗi, thử tải và hiển thị quảng cáo mới
        await _loadInterstitialAd();
        if (_isAdLoaded && _interstitialAd != null) {
          await showAd();
        }
      }
    } else {
      // Nếu chưa có quảng cáo, tải mới và thử lại
      await _loadInterstitialAd();
      if (_isAdLoaded && _interstitialAd != null) {
        await showAd();
      }
    }
  }

  Future<bool> purchasePremium() async {
    try {
      // TODO: Implement in-app purchase with Google Pay/Apple Pay
      // For now, just simulate success
      _isPremium = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> resetScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_scanCountKey, 0);
    _hasShownPremium = false;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
} 