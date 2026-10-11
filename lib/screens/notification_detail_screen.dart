import 'package:fire_message/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:action_slider/action_slider.dart';
import '../models/notification_model.dart';
import '../services/notification_storage_service.dart';
import '../services/messaging_service.dart';
import 'create_notification_screen.dart';
import '../widgets/custom_app_theme.dart';
import '../widgets/app_widgets.dart';
import '../utils/tools.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onDataChanged;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
    this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = notification.sent ? AppColors.success : AppColors.error;
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(notification.nickname),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Message'),
            _buildInfoCard(
              context,
              'App',
              notification.app.name,
              icon: HeroIcons.cube,
            ),
            const SizedBox(height: AppSpacing.listGap),
            _buildInfoCard(
              context,
              'Title',
              notification.title,
              icon: HeroIcons.documentText,
            ),
            const SizedBox(height: AppSpacing.listGap),
            _buildInfoCard(
              context,
              'Body',
              notification.body,
              icon: HeroIcons.chatBubbleLeftRight,
            ),
            if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.listGap),
              _buildInfoCard(
                context,
                'Image URL',
                notification.imageUrl!,
                icon: HeroIcons.photo,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('Target'),
            if (notification.topic != null)
              _buildInfoCard(
                context,
                'Topic',
                notification.topic!,
                icon: HeroIcons.hashtag,
              ),
            if (notification.condition != null) ...[
              if (notification.topic != null) const SizedBox(height: AppSpacing.listGap),
              _buildInfoCard(
                context,
                'Condition',
                notification.condition!,
                icon: HeroIcons.funnel,
              ),
            ],
            if (notification.token != null && notification.token!.isNotEmpty) ...[
              if (notification.topic != null || notification.condition != null)
                const SizedBox(height: AppSpacing.listGap),
              _buildInfoCard(
                context,
                'Recipient',
                notification.token!,
                icon: HeroIcons.user,
              ),
            ],
            if (notification.data != null && notification.data!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader('Payload'),
              Card(
                child: Padding(
                  padding: AppSpacing.card,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const HeroIcon(HeroIcons.codeBracket, color: AppColors.textSecondary),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Custom Data', style: textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ...notification.data!.entries.map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key}: ', style: textTheme.labelMedium),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader('Delivery'),
            Card(
              child: Padding(
                padding: AppSpacing.card,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const HeroIcon(HeroIcons.clock, color: AppColors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text('Sent At', style: textTheme.titleSmall)),
                        StatusBadge(
                          label: notification.resultCode ?? 'Unknown',
                          color: statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      formatDate(notification.createdAt),
                      style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusIcon(success: notification.sent, size: AppSizes.iconSm),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs),
                            child: Text(
                              notification.resultMessage ?? 'Unknown error occurred',
                              style: textTheme.bodyMedium?.copyWith(color: statusColor),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _duplicateNotification(context),
                    icon: const HeroIcon(HeroIcons.documentDuplicate),
                    label: const Text('Duplicate'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showResendConfirmation(context),
                    icon: const HeroIcon(HeroIcons.paperAirplane),
                    label: const Text('Resend'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, {required HeroIcons icon}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroIcon(icon, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(value, style: textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _duplicateNotification(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: CustomAppBar(
            title: Text('Duplicate Notification'),
          ),
          body: CreateNotificationScreen(
            initialNotification: notification,
            onDataChanged: onDataChanged,
          ),
        ),
      ),
    );
  }

  void _showResendConfirmation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Resend Notification',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const HeroIcon(HeroIcons.xMark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Are you sure you want to resend this notification?',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ActionSlider.standard(
              width: double.infinity,
              height: 64,
              backgroundColor: AppColors.surface,
              toggleColor: AppColors.primary,
              action: (controller) async {
                controller.loading();
                await _resendNotification(context);
                if (context.mounted) {
                  controller.success();
                  Navigator.pop(context); // Close bottom sheet
                  controller.reset();
                }
              },
              child: Text(
                'Slide to Resend',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resendNotification(BuildContext context) async {
    final messagingService = MessagingService();
    final notificationStorage = NotificationStorageService();

    try {
      final response = await messagingService.sendNotification(
        app: notification.app,
        title: notification.title,
        body: notification.body,
        imageUrl: notification.imageUrl,
        data: notification.data,
        topic: notification.topic,
        condition: notification.condition,
        token: notification.token,
      );

      final success = response['code'] == '200';
      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: success,
        resultCode: response['code'],
        resultMessage: response['message'],
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        showAppSnackBar(
          context,
          response['message'] ?? (success ? 'Notification resent successfully' : 'Failed to resend notification'),
          type: success ? SnackType.success : SnackType.error,
        );
        onDataChanged?.call();
      }
    } catch (e) {      
      final updatedNotification = notification.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        sent: false,
        resultCode: 'ERROR',
        resultMessage: e.toString(),
      );

      await notificationStorage.saveNotification(updatedNotification);

      if (context.mounted) {
        showAppSnackBar(context, updatedNotification.resultMessage ?? 'Error occurred', type: SnackType.error);
        onDataChanged?.call();
      }
    }
  }

}
