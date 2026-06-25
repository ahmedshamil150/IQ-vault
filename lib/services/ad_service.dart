import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Rewarded ad IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3779556578074335/6413793313';
    }

    if (kDebugMode) {
      if (Platform.isIOS) {
        return 'ca-app-pub-3940256099942544/1712485313';
      }
    }

    return '';
  }

  void loadRewardedAd({required Function onAdLoaded, required Function onAdFailed}) {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          onAdFailed();
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(AdWithoutView ad, RewardItem reward) onUserEarnedReward,
    required Function onAdDismissed,
  }) {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          onAdDismissed();
          // Preload next ad
          loadRewardedAd(onAdLoaded: () {}, onAdFailed: () {});
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          onAdDismissed();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
      _rewardedAd = null;
    } else {
      onAdDismissed();
    }
  }

  bool get isAdLoaded => _isRewardedAdLoaded;
}
