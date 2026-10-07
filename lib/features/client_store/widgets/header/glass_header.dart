import 'dart:ui';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/vertex_logo.dart';
import 'cart_icon_badge.dart';

class GlassHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlassHeader({
    super.key,
    required this.cartCount,
    required this.onMenuTap,
    required this.onLogoTap,
    required this.onCartTap,
    this.onSearchTap,
    this.showSearch = false,
  });

  final int cartCount;
  final VoidCallback onMenuTap;
  final VoidCallback onLogoTap;
  final VoidCallback onCartTap;
  final VoidCallback? onSearchTap;
  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.scaffold.withOpacity(0.80),
            border: const Border(
              bottom: BorderSide(color: AppColors.border, width: 0.6),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _HeaderIconButton(
                      icon: Icons.menu_rounded,
                      tooltip: 'Abrir menú',
                      onTap: onMenuTap,
                    ),
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: onLogoTap,
                          behavior: HitTestBehavior.opaque,
                          child: const VertexLogo(),
                        ),
                      ),
                    ),
                    if (showSearch && onSearchTap != null)
                      _HeaderIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'Buscar productos',
                        onTap: onSearchTap!,
                      ),
                    CartIconBadge(count: cartCount, onTap: onCartTap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 24, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}