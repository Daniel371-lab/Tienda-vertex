import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/vertex_logo.dart';
import '../controllers/auth_controller.dart';

/// Estructura base del cPanel: AppBar + Drawer lateral + contenido.
class AdminShellView extends ConsumerWidget {
  const AdminShellView({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final title = _titleForRoute(location);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Ver tienda',
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.storefront_outlined),
          ),
        ],
      ),
      drawer: _AdminDrawer(currentLocation: location),
      body: child,
    );
  }

  String _titleForRoute(String location) {
    if (location == '/admin' || location == '/admin/') return 'Panel';
    if (location.startsWith('/admin/productos')) return 'Productos';
    if (location.startsWith('/admin/categorias')) return 'Categorías';
    if (location.startsWith('/admin/pedidos')) return 'Pedidos';
    if (location.startsWith('/admin/cupones')) return 'Cupones';
    if (location.startsWith('/admin/blacklist')) return 'Lista negra';
    if (location.startsWith('/admin/ajustes')) return 'Ajustes';
    return 'Panel';
  }
}

class _AdminDrawer extends ConsumerWidget {
  const _AdminDrawer({required this.currentLocation});
  final String currentLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Row(
                children: [
                  const VertexLogo(markSize: 28, wordmarkSize: 15),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Panel',
                    route: '/admin',
                    current: currentLocation,
                    exactMatch: true,
                  ),
                  _DrawerItem(
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    route: '/admin/productos',
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.category_outlined,
                    label: 'Categorías',
                    route: '/admin/categorias',
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Pedidos',
                    route: '/admin/pedidos',
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.local_offer_outlined,
                    label: 'Cupones',
                    route: '/admin/cupones',
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.block_outlined,
                    label: 'Lista negra',
                    route: '/admin/blacklist',
                    current: currentLocation,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    label: 'Ajustes',
                    route: '/admin/ajustes',
                    current: currentLocation,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: AppColors.danger, size: 20),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.of(context).pop();
                await ref.read(loginControllerProvider.notifier).signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.current,
    this.exactMatch = false,
  });

  final IconData icon;
  final String label;
  final String route;
  final String current;
  final bool exactMatch;

  bool get _isSelected {
    if (exactMatch) return current == route || current == '$route/';
    return current.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _isSelected ? AppColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        leading: Icon(
          icon,
          size: 20,
          color: _isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: _isSelected ? FontWeight.w700 : FontWeight.w500,
            color: _isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (current != route) context.go(route);
        },
      ),
    );
  }
}