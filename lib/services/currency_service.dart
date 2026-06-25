import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CurrencyService {
  static const String _currencyKey = 'user_currency';
  static const int reward1Star = 10;
  static const int reward2Stars = 25;
  static const int reward3Stars = 50;
  static const int rewardedAdReward = 25;
  static const int hintCost = 40;
  static const int calculatorCost = 15;
  static const int levelUnlockCost = 150;
  static const int initialCurrency = 150;
  static const int testerBonus = 1000;

  final Box _box = Hive.box('iqVaultBox');

  ValueListenable<Box> get listenable => _box.listenable(keys: [_currencyKey]);

  int get currency => _box.get(_currencyKey, defaultValue: initialCurrency);

  Future<void> addCurrency(int amount) async {
    final current = currency;
    await _box.put(_currencyKey, current + amount);
  }

  Future<bool> spendCurrency(int amount) async {
    final current = currency;
    if (current >= amount) {
      await _box.put(_currencyKey, current - amount);
      return true;
    }
    return false;
  }

  Future<void> addReward() async {
    await addCurrency(rewardedAdReward);
  }

  int getRewardForStars(int stars) {
    if (stars >= 3) return reward3Stars;
    if (stars == 2) return reward2Stars;
    if (stars == 1) return reward1Star;
    return 0;
  }
}
