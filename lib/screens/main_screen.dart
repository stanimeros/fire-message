import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../widgets/custom_app_bar.dart';
import 'apps_screen.dart';
import 'create_notification_screen.dart';
import 'history_screen.dart';
import 'help_screen.dart';
import '../models/notification_model.dart';

class MainScreen extends StatefulWidget {
  /// Optional debug-only parameters used by `ScreenshotRouter`.
  final int initialIndex;
  final NotificationModel? demoNotification;
  final bool demoOpenTargetSelector;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
    this.demoNotification,
    this.demoOpenTargetSelector = false,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex = widget.initialIndex;
  int? _previousIndex;

  VoidCallback? _refreshAppsScreen;
  VoidCallback? _refreshCreateNotificationScreen;
  VoidCallback? _refreshHistoryScreen;

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Apps';
      case 1:
        return 'Create Notification';
      case 2:
        return 'History';
      default:
        return 'Fire Message';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showLeading: false,
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.questionMarkCircle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpScreen(),
                ),
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AppsScreen(
            onRefreshCallback: (callback) => _refreshAppsScreen = callback,
            onDataChanged: _refreshAllScreens,
          ),
          CreateNotificationScreen(
            initialNotification: widget.demoNotification,
            openTargetSelectorOnStart: widget.demoOpenTargetSelector,
            onRefreshCallback: (callback) => _refreshCreateNotificationScreen = callback,
            onDataChanged: _refreshAllScreens,
          ),
          HistoryScreen(
            onRefreshCallback: (callback) => _refreshHistoryScreen = callback,
            onDataChanged: _refreshAllScreens,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // Refresh the screen when switching to it
          if (_previousIndex != index) {
            _refreshScreen(index);
          }
          setState(() {
            _previousIndex = _currentIndex;
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.plusCircle),
            label: 'Apps',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.bell),
            label: 'Create',
          ),
          BottomNavigationBarItem(
            icon: HeroIcon(HeroIcons.clock),
            label: 'History',
          ),
        ],
      ),
    );
  }

  void _refreshScreen(int index) {
    switch (index) {
      case 0:
        _refreshAppsScreen?.call();
        break;
      case 1:
        _refreshCreateNotificationScreen?.call();
        break;
      case 2:
        _refreshHistoryScreen?.call();
        break;
    }
  }

  // Public method to refresh screens when data changes
  void _refreshAllScreens() {
    _refreshAppsScreen?.call();
    _refreshCreateNotificationScreen?.call();
    _refreshHistoryScreen?.call();
  }
}

