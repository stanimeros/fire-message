import 'dart:io';

import 'package:fire_message/screens/main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_app_theme.dart';

const String _entitlementId = 'premium';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _isLoading = false;
  bool _isRestoring = false;
  Offerings? _offerings;
  Package? _selectedPackage;
  Map<String, IntroEligibility> _introEligibility = {};
  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offerings = await Purchases.getOfferings();
      
      Package? selectedPackage;
      if (offerings.current != null && 
          offerings.current!.availablePackages.isNotEmpty) {
        selectedPackage = offerings.current!.availablePackages.first;
      }

      final productIds = offerings.current?.availablePackages
              .map((p) => p.storeProduct.identifier)
              .toList() ??
          [];
      final eligibility = productIds.isEmpty
          ? <String, IntroEligibility>{}
          : await Purchases.checkTrialOrIntroductoryPriceEligibility(productIds);
      
      setState(() {
        _offerings = offerings;
        _selectedPackage = selectedPackage;
        _introEligibility = eligibility;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        debugPrint('Failed to load subscription options: $e');
      }
    }
  }

  Future<void> _purchasePackage() async {
    if (_selectedPackage == null) {
      showAppSnackBar(context, 'Please select a subscription plan', type: SnackType.error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await Purchases.purchase(PurchaseParams.package(_selectedPackage!));
      final customerInfo = result.customerInfo;
      final success = customerInfo.entitlements.active[_entitlementId] != null;
      
      if (success) {
        if (mounted) {
          // Premium unlocked, the app will automatically navigate away
          showAppSnackBar(context, 'Welcome to Premium! 🎉', type: SnackType.success);
        }
      }
    } on PurchasesError catch (e) {
      if (e.code != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          showAppSnackBar(context, 'Purchase failed: $e', type: SnackType.error);
        }
      } else {
        if (mounted) {
          showAppSnackBar(context, 'Purchase was cancelled', type: SnackType.error);
        }
      }
    } catch (e) {
      debugPrint('Purchase failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final customerInfo = await Purchases.restorePurchases();
      final success = customerInfo.entitlements.active[_entitlementId] != null;
      
      if (mounted) {
        if (success) {
          showAppSnackBar(context, 'Purchases restored successfully! 🎉', type: SnackType.success);
        } else {
          showAppSnackBar(context, 'No purchases found to restore', type: SnackType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to restore purchases: $e', type: SnackType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  String _getPackageDisplayName(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      default:
        return 'Unknown';
    }
  }

  String _getBillingText(PackageType packageType) {
    switch (packageType) {
      case PackageType.monthly:
        return 'Billed monthly';
      case PackageType.annual:
        return 'Billed yearly';
      default:
        return '';
    }
  }

  /// Whether [package] has an intro offer this user can redeem. iOS reports
  /// eligibility per product; Play only lists offers the user is eligible for.
  bool _isIntroEligible(Package package) {
    if (package.storeProduct.introductoryPrice == null) return false;
    if (!Platform.isIOS) return true;
    return _introEligibility[package.storeProduct.identifier]?.status ==
        IntroEligibilityStatus.introEligibilityStatusEligible;
  }

  bool _hasFreeTrial(Package package) =>
      _isIntroEligible(package) && package.storeProduct.introductoryPrice!.price == 0;

  /// e.g. "7-day free trial", or "Intro offer" for a paid intro price.
  String _getTrialText(Package package) {
    final intro = package.storeProduct.introductoryPrice!;
    if (intro.price != 0) return 'Intro offer';
    if (intro.periodUnit == PeriodUnit.unknown) return 'Free trial';
    final unit = intro.periodUnit.name;
    return '${intro.periodNumberOfUnits}-$unit free trial';
  }

  String _getButtonText() {
    if (_selectedPackage != null && _hasFreeTrial(_selectedPackage!)) {
      return 'Start your free trial';
    }
    return 'Subscribe Now';
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        showAppSnackBar(context, 'Could not open $url', type: SnackType.error);
      }
    }
  }

  Widget _buildTermsAndPrivacyText(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted);
    final link = base?.copyWith(color: AppColors.primary);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By subscribing, you agree to our '),
          TextSpan(
            text: 'Terms of Use',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchURL('https://stanimeros.com/privacy-policy'),
          ),
          const TextSpan(text: '. Subscription will auto-renew unless cancelled.'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: _isLoading && _offerings == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: const BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: AppRadius.large,
                        ),
                        child: const HeroIcon(
                          HeroIcons.bolt,
                          style: HeroIconStyle.solid,
                          color: AppColors.onStatus,
                          size: AppSizes.iconXl * 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Unlock Full Access',
                      style: textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Get unlimited access to all premium features',
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildFeatureItem(
                      icon: HeroIcons.sparkles,
                      title: 'Unlimited Notifications',
                      description: 'Send as many notifications as you need',
                    ),
                    const SizedBox(height: AppSpacing.listGap),
                    _buildFeatureItem(
                      icon: HeroIcons.hashtag,
                      title: 'Unlimited Topics & Conditions',
                      description: 'Create and manage unlimited targeting options',
                    ),
                    const SizedBox(height: AppSpacing.listGap),
                    _buildFeatureItem(
                      icon: HeroIcons.devicePhoneMobile,
                      title: 'Manage All Devices',
                      description: 'Track and send to unlimited devices',
                    ),
                    const SizedBox(height: AppSpacing.listGap),
                    _buildFeatureItem(
                      icon: HeroIcons.clock,
                      title: 'Full History & Tools',
                      description: 'View history, duplicate, and resend notifications',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    // Subscription packages
                    if (_offerings?.current != null &&
                        _offerings!.current!.availablePackages.isNotEmpty)
                      ..._offerings!.current!.availablePackages.map((package) {
                        final isSelected = _selectedPackage?.identifier == package.identifier;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _buildPackageCard(
                            package: package,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedPackage = package;
                              });
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: AppSpacing.xs),
                    // Purchase/Skip button
                    ElevatedButton(
                      onPressed: _isLoading ? null : kReleaseMode ? _purchasePackage : () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const MainScreen())),
                      child: _isLoading
                          ? const SizedBox(
                              height: AppSizes.iconMd,
                              width: AppSizes.iconMd,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(_getButtonText()),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Restore purchases button
                    TextButton(
                      onPressed: _isRestoring ? null : _restorePurchases,
                      child: _isRestoring
                          ? const SizedBox(
                              height: AppSizes.iconMd,
                              width: AppSizes.iconMd,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Restore Purchases'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTermsAndPrivacyText(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required HeroIcons icon,
    required String title,
    required String description,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.primary),
                borderRadius: AppRadius.medium,
              ),
              child: HeroIcon(icon, color: AppColors.primary, size: AppSizes.iconLg),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(description, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard({
    required Package package,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isIntroEligible = _isIntroEligible(package);

    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.large,
      child: Container(
        padding: AppSpacing.card,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tint(AppColors.primary) : AppColors.surface,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : AppSizes.borderWidth,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.iconLg,
              height: AppSizes.iconLg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const HeroIcon(
                      HeroIcons.check,
                      style: HeroIconStyle.solid,
                      size: AppSizes.iconSm,
                      color: AppColors.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getPackageDisplayName(package.packageType), style: textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_getBillingText(package.packageType), style: textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  package.storeProduct.priceString,
                  style: textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
                if (isIntroEligible) ...[
                  const SizedBox(height: AppSpacing.xs),
                  StatusBadge(label: _getTrialText(package), color: AppColors.primary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
