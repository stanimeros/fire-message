import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/main_screen.dart';
import 'screens/paywall_screen.dart';
import 'widgets/custom_app_theme.dart';

const String _entitlementId = 'premium';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
  }
  
  try {
    final apiKey = Platform.isIOS 
        ? dotenv.env['RC_IOS_API_KEY'] ?? ''
        : dotenv.env['RC_ANDROID_API_KEY'] ?? '';
    
    if (apiKey.isEmpty) {
      debugPrint('Warning: RevenueCat API key not found in .env file');
    } else {
      await Purchases.configure(PurchasesConfiguration(apiKey));
    }
  } catch (e) {
    debugPrint('Failed to initialize Purchases: $e');
  }
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fire Message',
      theme: CustomAppTheme.darkTheme,
      home: const PaywallGate(),
    );
  }
}

/// Gate widget that checks premium status and shows paywall or main screen
class PaywallGate extends StatefulWidget {
  const PaywallGate({super.key});

  @override
  State<PaywallGate> createState() => _PaywallGateState();
}

class _PaywallGateState extends State<PaywallGate> {
  bool _isLoading = true;
  bool _isPremium = false;
  StreamController<bool>? _premiumStatusController;
  StreamSubscription<bool>? _premiumStatusSubscription;

  @override
  void initState() {
    super.initState();
    _setupListener();
  }

  void _setupListener() {
    // Initialize stream controller
    _premiumStatusController = StreamController<bool>.broadcast();
    
    // Set up customer info update listener
    Purchases.addCustomerInfoUpdateListener((customerInfo) {
      final isPremium = customerInfo.entitlements.active[_entitlementId] != null;
      _premiumStatusController?.add(isPremium);
    });

    // Get initial premium status
    _checkPremiumStatus();

    // Listen to premium status stream for real-time updates
    _premiumStatusSubscription = _premiumStatusController!.stream.listen(
      (isPremium) {
        if (mounted) {
          setState(() {
            _isPremium = isPremium;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint('Error in premium status stream: $error');
        if (mounted) {
          setState(() {
            _isPremium = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium = customerInfo.entitlements.active[_entitlementId] != null;
      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
        _premiumStatusController?.add(isPremium);
      }
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
          _isLoading = false;
        });
        _premiumStatusController?.add(false);
      }
    }
  }

  @override
  void dispose() {
    _premiumStatusSubscription?.cancel();
    _premiumStatusController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Show paywall if not premium, otherwise show main screen
    return _isPremium ? const MainScreen() : const PaywallScreen();
  }
}
