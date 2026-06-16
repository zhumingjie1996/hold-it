import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PurchaseState { idle, purchasing, success, failed, cancelled }

enum RestoreState { idle, restoring, success, noPurchases, notSignedIn, networkError, failed }

class StoreManager extends ChangeNotifier {
  bool _isVip = false;
  bool _isLoading = true;
  PurchaseState _purchaseState = PurchaseState.idle;
  RestoreState _restoreState = RestoreState.idle;
  String _displayPrice = '';

  bool get isVip => _isVip;
  bool get isLoading => _isLoading;
  PurchaseState get purchaseState => _purchaseState;
  RestoreState get restoreState => _restoreState;
  String get displayPrice => _displayPrice;

  static const String _isVipCacheKey = 'mj.holdit.isVipCached';
  static const String _vipConfirmedKey = 'mj.holdit.vipConfirmedOnce';

  StoreManager() {
    _loadVipState();
  }

  Future<void> _loadVipState() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_isVipCacheKey) ?? false;
    final confirmed = prefs.getBool(_vipConfirmedKey) ?? false;
    _isVip = cached && confirmed;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> purchase() async {
    _purchaseState = PurchaseState.purchasing;
    notifyListeners();

    // Simulate purchase for demo (replace with real in-app purchase)
    await Future.delayed(const Duration(seconds: 2));
    _purchaseState = PurchaseState.success;
    _isVip = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isVipCacheKey, true);
    await prefs.setBool(_vipConfirmedKey, true);
    
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    _restoreState = RestoreState.restoring;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_isVipCacheKey) ?? false;
    
    if (cached) {
      _isVip = true;
      _restoreState = RestoreState.success;
    } else {
      _restoreState = RestoreState.noPurchases;
    }
    notifyListeners();
  }

  void resetRestoreState() {
    _restoreState = RestoreState.idle;
    notifyListeners();
  }

  void resetPurchaseState() {
    _purchaseState = PurchaseState.idle;
    notifyListeners();
  }
}
