import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../services/monetization_service.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // Ads are not supported on Web in this demo (requires different setup)
    if (!kIsWeb) {
      _loadAd();
    }
  }

  void _loadAd() {
    // Test ID for Android
    // We assume Android for simplicity if not Web. 
    // In a real app we would check Platform.isAndroid but that requires dart:io which breaks web.
    final String adUnitId = 'ca-app-pub-3940256099942544/6300978111'; 

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          print('Ad failed to load: $err');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check Monetization Service
    final monetization = context.watch<MonetizationService>();
    if (!monetization.shouldShowBannerAds) {
        return const SizedBox.shrink(); // Hide Ad
    }

    if (kIsWeb) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50,
        color: Colors.grey[300],
        child: const Text('Ad Banner (Web Placeholder)', style: TextStyle(color: Colors.black54)),
      );
    }
    
    if (_bannerAd != null && _isLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink(); // Hide if not loaded
  }
}
