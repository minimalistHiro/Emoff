import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.titleText,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
  });

  final String? titleText;
  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;

  static const _background = Color(0xFF0D0D0D);
  static const _cyan = Color(0xFF00D4FF);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: _background,
      elevation: 0,
      centerTitle: true,
      leading: leading ??
          (showBackButton && canPop
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: _cyan),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null),
      title: title ??
          (titleText != null
              ? Text(
                  titleText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null),
      actions: actions,
    );
  }
}
