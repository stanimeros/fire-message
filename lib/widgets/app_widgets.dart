import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'custom_app_theme.dart';

/// Shared building blocks. All styling comes from custom_app_theme.dart.

enum SnackType { info, success, error }

void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final color = switch (type) {
    SnackType.success => AppColors.success,
    SnackType.error => AppColors.error,
    SnackType.info => null,
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: color == null ? null : const TextStyle(color: AppColors.onStatus),
      ),
      backgroundColor: color,
      duration: duration,
    ),
  );
}

/// Centered icon + title + optional subtitle for empty lists.
class EmptyState extends StatelessWidget {
  final HeroIcons icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.tint(AppColors.primary),
                shape: BoxShape.circle,
              ),
              child: HeroIcon(icon, size: AppSizes.iconXl * 0.6, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Round tinted icon showing sent / failed state.
class StatusIcon extends StatelessWidget {
  final bool success;
  final double size;

  const StatusIcon({super.key, required this.success, this.size = AppSizes.iconMd});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(color: AppColors.tint(color), shape: BoxShape.circle),
      child: HeroIcon(
        success ? HeroIcons.check : HeroIcons.xMark,
        style: HeroIconStyle.solid,
        color: color,
        size: size,
      ),
    );
  }
}

/// Small pill label, e.g. "Sent" / "Failed" / "Pro".
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
        color: AppColors.tint(color),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

/// App logo from base64 data, falling back to the first letter of the name.
class AppAvatar extends StatelessWidget {
  final String? imageData;
  final String name;
  final double size;

  const AppAvatar({super.key, required this.imageData, required this.name, this.size = AppSizes.avatar});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.primary),
        borderRadius: AppRadius.medium,
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary),
      ),
    );

    if (imageData == null || imageData!.isEmpty) return fallback;
    try {
      return ClipRRect(
        borderRadius: AppRadius.medium,
        child: Image.memory(
          base64Decode(imageData!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    } catch (_) {
      return fallback;
    }
  }
}

/// Red swipe-to-delete background for Dismissible list items.
class DismissDeleteBackground extends StatelessWidget {
  const DismissDeleteBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.xl),
      decoration: const BoxDecoration(color: AppColors.error, borderRadius: AppRadius.large),
      child: const HeroIcon(HeroIcons.trash, color: AppColors.onStatus, size: AppSizes.iconMd),
    );
  }
}

/// Uppercase muted label above a group of fields/cards.
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
      ),
    );
  }
}
