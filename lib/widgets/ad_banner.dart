import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads/ad_service.dart';

class AdBanner extends StatefulWidget {
  final AdSize size;
  final bool showBackground;

  const AdBanner({
    super.key,
    this.size = AdSize.banner,
    this.showBackground = true,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService.instance.createBannerAd(
      size: widget.size,
      onAdLoaded: (ad) {
        setState(() {
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        _bannerAd = null;
        // Reintentar después de un delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _loadBannerAd();
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: widget.showBackground
          ? BoxDecoration(
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey[300]!),
            )
          : null,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
