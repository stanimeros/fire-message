import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_app_theme.dart';
import 'notification_detail_screen.dart';
import '../utils/tools.dart';

class HistoryScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;

  const HistoryScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with AutomaticKeepAliveClientMixin {
  final _notificationStorage = NotificationStorageService();
  List<NotificationModel> _notifications = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadNotifications);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _notificationStorage.getNotifications();
    setState(() {
      _notifications = notifications;
    });
  }

  Future<bool> _deleteNotification(NotificationModel notification) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content: const Text('Are you sure you want to delete this notification?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onStatus,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _notificationStorage.deleteNotification(notification.id);
      _loadNotifications();
      if (mounted) {
        showAppSnackBar(context, 'Notification deleted');
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_notifications.isEmpty) {
      return const EmptyState(
        icon: HeroIcons.inbox,
        title: 'No notifications yet',
        subtitle: 'Sent notifications will show up here',
      );
    }
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Dismissible(
          key: Key(notification.id),
          direction: DismissDirection.endToStart,
          background: const DismissDeleteBackground(),
          confirmDismiss: (direction) async {
            final deleted = await _deleteNotification(notification);
            if (deleted) {
              widget.onDataChanged?.call();
            }
            return deleted;
          },
          child: Card(
            child: ListTile(
              leading: AppAvatar(imageData: notification.app.imageData, name: notification.app.name),
              title: Text(notification.nickname),
              subtitle: Text(formatDate(notification.createdAt)),
              trailing: StatusIcon(success: notification.sent),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailScreen(
                      notification: notification,
                      onDataChanged: () {
                        _loadNotifications();
                        widget.onDataChanged?.call();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
