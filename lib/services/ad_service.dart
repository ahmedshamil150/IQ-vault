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

    if (Platform.isIOS) {
      if (kDebugMode) {
        return 'ca-app-pub-3940256099942544/1712485313';
      } else {
        // TODO: Replace with your actual iOS production ad unit ID
        return 'ca-app-pub-3779556578074335/1712485313';
      }
    }

    return '';
  }

  void loadRewardedAd({Function? onAdLoaded, Function? onAdFailed}) {
    if (rewardedAdUnitId.isEmpty) {
      if (onAdFailed != null) onAdFailed();
      return;
    }

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          if (onAdLoaded != null) onAdLoaded();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          _rewardedAd = null;
          if (onAdFailed != null) onAdFailed();
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
          _rewardedAd = null;
          onAdDismissed();
          // Preload next ad
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          _rewardedAd = null;
          onAdDismissed();
          // Try to reload ad
          loadRewardedAd();
        },
      );

      _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
    } else {
      // If no ad loaded, try to load one first
      loadRewardedAd(onAdLoaded: () {
        showRewardedAd(
          onUserEarnedReward: onUserEarnedReward,
          onAdDismissed: onAdDismissed,
        );
      }, onAdFailed: () {
        onAdDismissed();
      });
    }
  }

  bool get isAdLoaded => _isRewardedAdLoaded;

  void dispose() {
    _rewardedAd?.dispose();
  }
}
