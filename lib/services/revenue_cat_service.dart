import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _iosApiKey = 'appl_XXXXXXXXXXXXXXXXXXXXXXXX';
  static const _androidApiKey = 'goog_XXXXXXXXXXXXXXXXXXXXXXXX';

  static const proEntitlementId = 'pro';
  static const proMonthlyProductId = 'emoff_pro_monthly';

  static Future<void> init(String uid) async {
    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
    final configuration = PurchasesConfiguration(apiKey)..appUserID = uid;
    await Purchases.configure(configuration);
  }

  static Future<String> getCurrentPlan() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      if (customerInfo.entitlements.all[proEntitlementId]?.isActive == true) {
        return 'pro';
      }
      return 'free';
    } catch (_) {
      return 'free';
    }
  }

  static Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  static Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  static Future<PurchaseResult> purchase(Package package) async {
    return await Purchases.purchase(PurchaseParams.package(package));
  }

  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  static Future<void> showManageSubscriptions() async {
    // RevenueCat SDK v9ではshowManageSubscriptionsが非対応の場合がある
    // URLスキームで直接OSの管理画面を開く
    // iOS: https://apps.apple.com/account/subscriptions
    // Android: https://play.google.com/store/account/subscriptions
  }
}
