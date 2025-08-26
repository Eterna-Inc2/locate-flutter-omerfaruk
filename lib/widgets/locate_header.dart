import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocateHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const LocateHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    const Color lightBg = Color(0xFFF5F7FA);
    const Color darkText = Color(0xFF1F2937);
    const Color divider = Color(0xFFE5E7EB);

    Widget? leadingWidget;
    double leadingWidth = 92; // daha sıkı

    if (showBackButton) {
      leadingWidget = IconButton(
        icon: const Icon(Icons.arrow_back_ios, size: 20),
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
      leadingWidth = 56;
    } else {
      leadingWidget = Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/locateLogo1.png',
              width: 16,
              height: 16,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.public, size: 16, color: darkText),
            ),
            const SizedBox(width: 6),
            Image.asset(
              'assets/images/locateLogo0.png',
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'Locate',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: darkText,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      );
      leadingWidth = 112;
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      automaticallyImplyLeading: true,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leading: leadingWidget,
      leadingWidth: leadingWidth,
      titleSpacing: 0,
      toolbarHeight: kToolbarHeight,
      centerTitle: true,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : darkText,
          letterSpacing: 0.2,
        ),
      ),
      actions: actions,
      backgroundColor: isDark ? const Color(0xFF44444E) : lightBg,
      foregroundColor: isDark ? Colors.white : darkText,
      elevation: 0.5,
      shadowColor: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
      shape: null,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(0.5),
        child: Divider(height: 0.5, thickness: 0.5, color: divider),
      ),
    );
  }
}
