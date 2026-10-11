import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_app_theme.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://firebase.google.com/docs/cloud-messaging/send/v1-api'));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: const Text('Help'),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.informationCircle, size: AppSizes.iconMd),
                    SizedBox(width: AppSpacing.sm),
                    Text('App Guide'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.bookOpen, size: AppSizes.iconMd),
                    SizedBox(width: AppSpacing.sm),
                    Text('FCM Docs'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: _tabController,
              children: [
                _buildAppGuide(),
                _buildDocumentation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppGuide() {
    return ListView(
      padding: AppSpacing.screen,
      children: [
        _buildGuideCard(
          icon: HeroIcons.key,
          title: 'API Access Requirements',
          body:
              'To use this app, you need to enable the following APIs in your Google Cloud project:\n\n'
        '1. Gemini API\n'
        '   • Required for text refinement features\n'
        '2. Firebase API\n'
        '   • Required for sending notifications\n'
        '3. Service Account Permissions\n'
        '   • Your service account must have the "Firebase Cloud Messaging API Admin" role',
        ),
        const SizedBox(height: AppSpacing.listGap),
        _buildGuideCard(
          icon: HeroIcons.plusCircle,
          title: 'Apps',
          body:
              'Tap + to create an app. Enter name, package name, and upload Firebase service account JSON. Swipe left to delete.',
        ),
        const SizedBox(height: AppSpacing.listGap),
        _buildGuideCard(
          icon: HeroIcons.hashtag,
          title: 'Devices & Conditions',
          body:
              'Open an app to manage:\n'
        '• Devices: Add device tokens\n'
        '• Topics: Create topic groups\n'
        '• Conditions: Combine topics/conditions with AND/OR\n'
        'Tap + in each tab to add. Swipe left to delete. Tap edit icon to modify.',
        ),
        const SizedBox(height: AppSpacing.listGap),
        _buildGuideCard(
          icon: HeroIcons.bell,
          title: 'Notifications',
          body:
              '1. Select app\n'
        '2. Enter nickname\n'
        '3. Enter title and body\n'
        '4. Select target (device, topic, or condition)\n'
        '5. Add image URL or custom data (optional)\n'
        '6. Slide to send',
        ),
        const SizedBox(height: AppSpacing.listGap),
        _buildGuideCard(
          icon: HeroIcons.clock,
          title: 'History',
          body:
              'View all sent notifications with nickname and timestamp. Tap to see details, duplicate, or resend. Swipe left to delete.',
        ),
        const SizedBox(height: AppSpacing.listGap),
        _buildGuideCard(
          icon: HeroIcons.shieldCheck,
          title: 'Security',
          body:
              'Service account JSON files are encrypted and stored securely on your device.',
        ),
      ],
    );
  }

  Widget _buildGuideCard({required HeroIcons icon, required String title, required String body}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                HeroIcon(icon, size: AppSizes.iconLg, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(title, style: textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentation() {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
}
