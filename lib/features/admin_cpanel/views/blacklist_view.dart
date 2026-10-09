import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/phone_validator.dart';
import '../controllers/admin_blacklist_controller.dart';

class BlacklistView extends ConsumerStatefulWidget {
  const BlacklistView({super.key});

  @override
  ConsumerState<BlacklistView> createState() => _BlacklistViewState();
}

class _BlacklistViewState extends ConsumerState<BlacklistView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminBlacklistControllerProvider);
    final ctrl = ref.read(adminBlacklistControllerProvider.notifier);
    final entries = state.filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: ctrl.setSearch,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Buscar por teléfono...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ctrl.setSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: state.isLoading && state.entries.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary),
                  )
                : entries.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: ctrl.load,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _EntryTile(
                            entry: entries[i],
                            onDelete: () => _confirmDelete(
                              entries[i].id,
                              entries[i].phone,
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Agregar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final phoneCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Agregar a lista negra'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(13),
                  PhoneValidator.inputFormatter,
                ],
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: '0981 123 456',
                ),
                validator: (v) {
                  if (!PhoneValidator.isValid(v ?? '')) {
                    return 'Teléfono inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  hintText: 'Ej: rechazó 2 paquetes en puerta',
                ),
                validator: (v) =>
                    (v == null || v.trim().length < 5)
                        ? 'Motivo requerido'
                        : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(dialogCtx).pop(true);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final success = await ref
        .read(adminBlacklistControllerProvider.notifier)
        .addEntry(
          phone: PhoneValidator.toWhatsappFormat(phoneCtrl.text),
          reason: reasonCtrl.text.trim(),
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Cliente agregado a la lista negra'
            : ref.read(adminBlacklistControllerProvider).error ??
                'No se pudo agregar'),
        backgroundColor:
            success ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDelete(String id, String phone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitar de la lista'),
        content: Text(
          '¿Confirmás quitar el teléfono ${PhoneValidator.formatForDisplay(phone)} '
          'de la lista negra?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Quitar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final result = await ref
        .read(adminBlacklistControllerProvider.notifier)
        .deleteEntry(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result ? 'Teléfono quitado' : 'No se pudo quitar'),
          backgroundColor:
              result ? AppColors.success : AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});
  final dynamic entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PhoneValidator.formatForDisplay(entry.phone),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entry.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (entry.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      DateHelpers.relative(entry.createdAt),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppColors.danger),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.block_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Lista vacía',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Los clientes bloqueados no podrán realizar pedidos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}