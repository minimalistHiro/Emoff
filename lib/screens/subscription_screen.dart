import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/revenue_cat_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/custom_dialog_helper.dart';
import '../widgets/custom_loading_indicator.dart';
import 'legal_document_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const _backgroundColor = Color(0xFF0D0D0D);
  static const _cardColor = Color(0xFF1A1A1A);
  static const _elevateColor = Color(0xFF242424);
  static const _cyan = Color(0xFF00D4FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA0A0A0);
  static const _textDisabled = Color(0xFF555555);
  static const _success = Color(0xFF00E676);
  static const _error = Color(0xFFFF4D4D);

  String _currentPlan = 'free';
  String? _nextBillingDate;
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // Firestoreからプラン情報取得
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        _currentPlan = data['plan'] as String? ?? 'free';
        final expiresAt = data['planExpiresAt'] as Timestamp?;
        if (expiresAt != null) {
          final date = expiresAt.toDate();
          _nextBillingDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      }
    }

    // RevenueCatのcustomerInfoでも確認（Firestoreより最新の可能性）
    final customerInfo = await RevenueCatService.getCustomerInfo();
    if (customerInfo != null) {
      final entitlement =
          customerInfo.entitlements.all[RevenueCatService.proEntitlementId];
      if (entitlement?.isActive == true) {
        _currentPlan = 'pro';
        if (entitlement?.expirationDate != null) {
          final date = DateTime.parse(entitlement!.expirationDate!);
          _nextBillingDate =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      }
    }

    // Offerings取得
    _offerings = await RevenueCatService.getOfferings();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: const CustomAppBar(titleText: 'Subscription'),
      body: _isLoading
          ? const Center(child: CustomLoadingIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroSection(),
                  if (_currentPlan != 'free') _buildCurrentPlanBanner(),
                  _buildFreePlanCard(),
                  const SizedBox(height: 16),
                  _buildProPlanCard(),
                  const SizedBox(height: 16),
                  _buildBusinessPlanCard(),
                  _buildNotesSection(),
                ],
              ),
            ),
    );
  }

  // === ヒーローセクション ===
  Widget _buildHeroSection() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CHOOSE YOUR CLARITY',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Plans',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              fontFamily: 'Manrope',
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upgrade to unlock the full potential of objective communication.',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // === 現在プランバナー（有料ユーザーのみ） ===
  Widget _buildCurrentPlanBanner() {
    final planName =
        _currentPlan == 'pro' ? 'Personal Pro' : 'Business';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT PLAN',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _openSubscriptionManagement,
                  child: const Text(
                    'Manage Subscription',
                    style: TextStyle(
                      color: _cyan,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (_nextBillingDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Next billing: $_nextBillingDate',
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === Free プランカード ===
  Widget _buildFreePlanCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _elevateColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Free',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\u00a50',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  'forever',
                  style: TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: _elevateColor),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.check, '1日30通までメッセージ変換', true),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.check, '1対1チャット', true),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.close, 'グループチャット', false),
            const SizedBox(height: 12),
            _buildFeatureRow(Icons.close, '変換トーン選択', false),
            if (_currentPlan == 'free') ...[
              const SizedBox(height: 24),
              const CustomButton(
                text: 'Current Plan',
                variant: CustomButtonVariant.secondary,
                onPressed: null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // === Personal Pro プランカード ===
  Widget _buildProPlanCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cyan, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Pro',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\u00a5300',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '/ month',
                      style: TextStyle(color: _textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: _elevateColor),
                const SizedBox(height: 16),
                _buildFeatureRow(Icons.check, '無制限メッセージ変換', true,
                    isHighlight: true),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check, '1対1チャット', true,
                    isHighlight: true),
                const SizedBox(height: 12),
                _buildFeatureRow(Icons.check, 'グループチャット', true,
                    isHighlight: true),
                const SizedBox(height: 12),
                _buildFeatureRow(
                    Icons.check, '変換トーン選択（ビジネス敬語/カジュアル等）', true,
                    isHighlight: true),
                const SizedBox(height: 24),
                _buildProButton(),
              ],
            ),
          ),
          // RECOMMENDED バッジ
          Positioned(
            top: 0,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _cyan,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Color(0xFF0D0D0D),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProButton() {
    if (_currentPlan == 'pro') {
      return const CustomButton(
        text: 'Current Plan',
        variant: CustomButtonVariant.secondary,
        onPressed: null,
      );
    }
    if (_currentPlan == 'business') {
      return const SizedBox.shrink();
    }
    // Freeユーザー向け
    return CustomButton(
      text: 'Upgrade to Pro',
      isLoading: _isPurchasing,
      onPressed: _isPurchasing ? null : _onPurchasePro,
    );
  }

  // === Business プランカード ===
  Widget _buildBusinessPlanCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: 0.6,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _elevateColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Business',
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '\u00a5600',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Manrope',
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '/ user / month',
                        style: TextStyle(color: _textDisabled, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _elevateColor),
                  const SizedBox(height: 16),
                  _buildFeatureRow(
                      Icons.check, 'Personal Pro の全機能', false,
                      isBusiness: true),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.check, 'チーム管理', false,
                      isBusiness: true),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.check, '利用統計', false,
                      isBusiness: true),
                  const SizedBox(height: 12),
                  _buildFeatureRow(Icons.check, '優先サポート', false,
                      isBusiness: true),
                ],
              ),
            ),
          ),
          // COMING SOON バッジ
          Positioned(
            top: 0,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _elevateColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 機能リスト行 ===
  Widget _buildFeatureRow(
    IconData icon,
    String text,
    bool enabled, {
    bool isHighlight = false,
    bool isBusiness = false,
  }) {
    final Color iconColor;
    final Color textColor;
    final TextDecoration decoration;

    if (isBusiness) {
      iconColor = _textDisabled;
      textColor = _textDisabled;
      decoration = TextDecoration.none;
    } else if (isHighlight) {
      iconColor = _cyan;
      textColor = _textPrimary;
      decoration = TextDecoration.none;
    } else if (enabled) {
      iconColor = _textSecondary;
      textColor = _textPrimary;
      decoration = TextDecoration.none;
    } else {
      iconColor = _textDisabled;
      textColor = _textDisabled;
      decoration = TextDecoration.lineThrough;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              decoration: decoration,
              decorationColor: _textDisabled,
            ),
          ),
        ),
      ],
    );
  }

  // === 注釈セクション ===
  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
      child: Column(
        children: [
          const Text(
            'サブスクリプションは自動更新されます。次の請求日の24時間前までにキャンセルできます。',
            style: TextStyle(color: _textDisabled, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'お支払いはApple ID / Google Playアカウントに請求されます。',
            style: TextStyle(color: _textDisabled, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => _navigateToLegalDocument('利用規約',
                    'assets/terms_of_service.md'),
                child: const Text(
                  '利用規約',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: _cyan,
                  ),
                ),
              ),
              const Text(
                ' ・ ',
                style: TextStyle(color: _textDisabled, fontSize: 12),
              ),
              GestureDetector(
                onTap: () => _navigateToLegalDocument(
                    'Privacy Policy', 'assets/privacy_policy.md'),
                child: const Text(
                  'プライバシーポリシー',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: _cyan,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _onRestorePurchases,
            child: const Text(
              'Restore Purchases',
              style: TextStyle(
                color: _cyan,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === アクション ===

  Future<void> _onPurchasePro() async {
    setState(() => _isPurchasing = true);

    try {
      // RevenueCatからOfferingsを取得してProパッケージを特定
      Package? proPackage;
      if (_offerings?.current != null) {
        proPackage = _offerings!.current!.availablePackages.firstWhere(
          (p) =>
              p.storeProduct.identifier ==
              RevenueCatService.proMonthlyProductId,
          orElse: () => _offerings!.current!.monthly!,
        );
      }

      if (proPackage == null) {
        if (mounted) {
          showCustomDialog(
            context,
            title: '購入できませんでした',
            message: 'プラン情報の取得に失敗しました。しばらく時間をおいてから再度お試しください。',
          );
        }
        return;
      }

      final result = await RevenueCatService.purchase(proPackage);
      final customerInfo = result.customerInfo;

      // 購入成功判定
      if (customerInfo
              .entitlements.all[RevenueCatService.proEntitlementId]?.isActive ==
          true) {
        // Firestoreのplanフィールドを更新
        await _updateFirestorePlan('pro', customerInfo);

        if (mounted) {
          setState(() => _currentPlan = 'pro');
          _showPurchaseSuccessDialog();
        }
      }
    } on PlatformException catch (e) {
      // ユーザーキャンセルの場合は何もしない
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return;
      }
      if (mounted) {
        _showPurchaseErrorDialog(e.message ?? 'エラーが発生しました。');
      }
    } catch (e) {
      if (mounted) {
        _showPurchaseErrorDialog('エラーが発生しました。しばらく時間をおいてから再度お試しください。');
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _onRestorePurchases() async {
    setState(() => _isLoading = true);

    try {
      final customerInfo = await RevenueCatService.restorePurchases();

      if (customerInfo
              .entitlements.all[RevenueCatService.proEntitlementId]?.isActive ==
          true) {
        await _updateFirestorePlan('pro', customerInfo);

        if (mounted) {
          setState(() {
            _currentPlan = 'pro';
            _isLoading = false;
          });
          showCustomDialog(
            context,
            title: '復元完了',
            message: 'Personal Proプランが復元されました。',
          );
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          showCustomDialog(
            context,
            title: '復元結果',
            message: '復元可能なサブスクリプションが見つかりませんでした。',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCustomDialog(
          context,
          title: 'エラー',
          message: '復元に失敗しました。しばらく時間をおいてから再度お試しください。',
        );
      }
    }
  }

  Future<void> _updateFirestorePlan(
      String plan, CustomerInfo customerInfo) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final updateData = <String, dynamic>{'plan': plan};

    final entitlement =
        customerInfo.entitlements.all[RevenueCatService.proEntitlementId];
    if (entitlement?.expirationDate != null) {
      final expiresAt = DateTime.parse(entitlement!.expirationDate!);
      updateData['planExpiresAt'] = Timestamp.fromDate(expiresAt);
      _nextBillingDate =
          '${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')}';
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updateData);
  }

  void _showPurchaseSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: _success),
            SizedBox(height: 16),
            Text(
              'アップグレード完了',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Personal Proプランへようこそ！全機能がアンロックされました。',
              style: TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: 'OK',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showPurchaseErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (ctx) => CustomDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 48, color: _error),
            const SizedBox(height: 16),
            const Text(
              '購入できませんでした',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(color: _textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          CustomButton(
            text: '閉じる',
            variant: CustomButtonVariant.secondary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _openSubscriptionManagement() async {
    // OSのサブスクリプション管理画面を開く
    final Uri url;
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      url = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      url = Uri.parse('https://play.google.com/store/account/subscriptions');
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _navigateToLegalDocument(String title, String assetPath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LegalDocumentScreen(title: title, assetPath: assetPath),
      ),
    );
  }
}
