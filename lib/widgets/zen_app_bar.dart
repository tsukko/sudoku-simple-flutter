import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ZenAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  const ZenAppBar({
    super.key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    // Heroで包むことで、画面遷移中もAppBarがそこにあり続けるように見せる
    return Hero(
      tag: 'zen_app_bar',
      child: AppBar(
        title: title,
        actions: actions,
        automaticallyImplyLeading: automaticallyImplyLeading,
        // 個別のScaffoldで色を指定せず、ThemeDataの設定に任せる
        // もしThemeDataの設定が効かない場合のためにここでも指定
        backgroundColor: AppColors.tokiwa,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
