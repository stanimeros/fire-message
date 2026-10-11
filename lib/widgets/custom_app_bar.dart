import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'custom_app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final Widget? leading;
  final bool showLeading;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    this.leading,
    this.showLeading = true,
    required this.title,
    this.actions,
  });

  Widget? defaultLeading(BuildContext context) {
    if (!showLeading) return null;
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    if (canPop) {
      return IconButton(
        icon: const HeroIcon(HeroIcons.chevronLeft),
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext context) {
        final Widget? leading = this.leading ?? defaultLeading(context);

        return AppBar(
          title: title,
          automaticallyImplyLeading: false,
          leading: leading,
          actions: actions,
          actionsPadding: const EdgeInsets.only(right: AppSpacing.sm),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 