import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob "Bottom Banner" ad unit ID. Ad unit IDs (unlike API keys) are meant to ship
/// inside client apps -- they're not secrets. Debug builds always use
/// Google's official test unit so development never generates invalid
/// traffic on the real account.
const _releaseBannerAdUnitId = 'ca-app-pub-9662900390336819/1111039679';
const _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const _bannerAdUnitId =
    kReleaseMode ? _releaseBannerAdUnitId : _testBannerAdUnitId;

/// A single anchored banner ad, meant to sit at the bottom of a non-workout
/// screen (as the Scaffold's `bottomNavigationBar`). Never used on the live
/// coaching screen, where a mid-workout tap could hit it by accident.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() => _bannerAd = ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) => ad.dispose(),
      ),
    ).load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        height: ad.size.height.toDouble(),
        color: Theme.of(context).colorScheme.surface,
        alignment: Alignment.center,
        child: AdWidget(ad: ad),
      ),
    );
  }
}
