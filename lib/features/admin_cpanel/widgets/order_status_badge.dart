import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../models/order_model.dart';

/// Chip visual del estado de un pedido.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final OrderStatus status;
  final bool compact;

  Color get _color {
    switch (status) {
      case OrderStatus.pendientePago:
        return AppColors.warning;
      case OrderStatus.pagado:
        return AppColors.success;
      case OrderStatus.comprandoProveedor:
        return AppColors.primary;
      case OrderStatus.listoDespacho:
        return AppColors.primaryDark;
      case OrderStatus.despachado:
        return const Color(0xFF7C3AED);
      case OrderStatus.entregado:
        return AppColors.success;
      case OrderStatus.cancelado:
        return AppColors.textMuted;
    }
  }

  IconData get _icon {
    switch (status) {
      case OrderStatus.pendientePago:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.pagado:
        return Icons.check_circle_rounded;
      case OrderStatus.comprandoProveedor:
        return Icons.shopping_cart_outlined;
      case OrderStatus.listoDespacho:
        return Icons.inventory_2_outlined;
      case OrderStatus.despachado:
        return Icons.local_shipping_outlined;
      case OrderStatus.entregado:
        return Icons.verified_rounded;
      case OrderStatus.cancelado:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 11 : 13, color: _color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}