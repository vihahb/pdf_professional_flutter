import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumProvider with ChangeNotifier {
  bool _isPremium = false;
  static const String _premiumKey = 'is_premium_user';

  bool get isPremium => _isPremium;

  PremiumProvider() {
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_premiumKey) ?? false;
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    notifyListeners();
  }

  Future<void> purchasePremium() async {
    // In a real app, this would integrate with in_app_purchase package
    // For now, we'll simulate the purchase
    await setPremium(true);
  }

  Future<void> restorePurchase() async {
    // In a real app, this would check with the store
    final prefs = await SharedPreferences.getInstance();
    final isPremium = prefs.getBool(_premiumKey) ?? false;
    _isPremium = isPremium;
    notifyListeners();
  }
}
