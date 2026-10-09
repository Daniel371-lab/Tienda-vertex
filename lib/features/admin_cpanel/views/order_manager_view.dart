import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../controllers/admin_orders_controller.dart';

class OrderManagerView extends ConsumerStatefulWidget {
  const OrderManagerView({super.key});

  @override
  ConsumerState<OrderManagerView> createState() => _OrderManagerViewState();
}

class _OrderManagerViewState extends ConsumerState<OrderManagerView> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminOrdersControllerProvider);

    return Container(
      color: Colors.green,
      child: Column(
        children: [
          Container(
            color: Colors.yellow,
            padding: const EdgeInsets.all(20),
            child: Text(
              'TEST · orders: ${state.orders.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.red,
              child: Center(
                child: Text(
                  'ESTO ES UN TEST\n\nPedidos cargados: ${state.orders.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}