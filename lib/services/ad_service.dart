import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'ad_session_service.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  bool _isInitialized = false;
  
  // Test Ad Unit IDs - Reemplazar con IDs reales en producción
  static String get _bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111' // Android Test
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test
  
  static String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712' // Android Test
      : 'ca-app-pub-3940256099942544/4411468910'; // iOS Test
  
  static String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917' // Android Test
      : 'ca-app-pub-3940256099942544/1712485313'; // iOS Test

  Future<void> initialize() async {
    if (_isInitialized) return;

    await MobileAds.instance.initialize();
    _isInitialized = true;
  }

  BannerAd createBannerAd({
    required AdSize size,
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    )..load();
  }

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  static const int _maxInterstitialLoadAttempts = 3;

  Future<void> loadInterstitialAd({
    required void Function() onAdDismissed,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
    }

    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              // El error de mostrar el anuncio es diferente al error de cargar
              // No llamamos onAdFailedToLoad aquí porque es un AdError, no un LoadAdError
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          
          if (_interstitialLoadAttempts < _maxInterstitialLoadAttempts) {
            // Reintentar después de un delay
            Future.delayed(const Duration(seconds: 2), () {
              loadInterstitialAd(
                onAdDismissed: onAdDismissed,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            });
          } else if (onAdFailedToLoad != null) {
            onAdFailedToLoad(error);
          }
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      // Registrar que se mostró un intersticial
      AdSessionService.instance.incrementInterstitialsShown();
    }
  }

  /// Muestra un intersticial de forma inteligente (solo si cumple las condiciones)
  /// Retorna true si se mostró, false si no se debe mostrar
  Future<bool> showInterstitialIfAppropriate({
    required void Function() onAdDismissed,
  }) async {
    // Verificar límites diarios
    final interstitialsToday = await AdSessionService.instance.getInterstitialsShownToday();
    if (interstitialsToday >= 3) {
      return false; // Ya se mostraron 3 intersticiales hoy
    }

    // Cargar anuncio si no está cargado
    if (_interstitialAd == null) {
      await loadInterstitialAd(
        onAdDismissed: () {
          onAdDismissed();
        },
      );
    }

    // Mostrar si está listo
    if (_interstitialAd != null) {
      showInterstitialAd();
      return true;
    }

    return false;
  }

  RewardedAd? _rewardedAd;
  int _rewardedLoadAttempts = 0;
  static const int _maxRewardedLoadAttempts = 3;

  Future<void> loadRewardedAd({
    required void Function(RewardItem) onRewarded,
    void Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (_rewardedAd != null) {
      _rewardedAd!.dispose();
      _rewardedAd = null;
    }

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0;
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              // El error de mostrar el anuncio es diferente al error de cargar
              // No llamamos onAdFailedToLoad aquí porque es un AdError, no un LoadAdError
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedLoadAttempts++;
          _rewardedAd = null;
          
          if (_rewardedLoadAttempts < _maxRewardedLoadAttempts) {
            Future.delayed(const Duration(seconds: 2), () {
              loadRewardedAd(
                onRewarded: onRewarded,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            });
          } else if (onAdFailedToLoad != null) {
            onAdFailedToLoad(error);
          }
        },
      ),
    );
  }

  void showRewardedAd({
    required void Function(RewardItem) onRewarded,
    void Function()? onAdFailedToShow,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded(reward);
        },
      );
    } else {
      if (onAdFailedToShow != null) {
        onAdFailedToShow();
      }
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}

