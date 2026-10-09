import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/phone_validator.dart';
import '../../../models/settings_model.dart';
import '../../../services/firebase/firebase_providers.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _formKey = GlobalKey<FormState>();

  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _shippingCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _geminiCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _obscureGemini = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _shippingCtrl.dispose();
    _holderCtrl.dispose();
    _bankCtrl.dispose();
    _accountCtrl.dispose();
    _geminiCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await ref.read(firestoreServiceProvider).fetchSettings();
      _whatsappCtrl.text = s.whatsappNumber;
      _emailCtrl.text = s.contactEmail;
      _addressCtrl.text = s.address;
      _shippingCtrl.text = s.shippingInfo;
      _holderCtrl.text = s.paymentHolderName;
      _bankCtrl.text = s.paymentBank;
      _accountCtrl.text = s.paymentAccount;
      _geminiCtrl.text = s.geminiApiKey;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle(
              icon: Icons.contact_phone_outlined,
              title: 'Contacto',
            ),
            _label(context, 'WhatsApp de atención'),
            TextFormField(
              controller: _whatsappCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '595981123456',
                prefixIcon: Icon(Icons.chat_outlined, size: 20),
                helperText: 'Formato internacional, sin + ni espacios',
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _label(context, 'Correo electrónico'),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'contacto@tiendavertex.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Ubicación'),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(
                hintText: 'Luque · Asunción, Paraguay',
                prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Info de envío (pie de página)'),
            TextFormField(
              controller: _shippingCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Envíos a todo Paraguay.',
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              icon: Icons.account_balance_outlined,
              title: 'Datos para transferencia',
            ),
            _label(context, 'Titular'),
            TextFormField(
              controller: _holderCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Nombre del titular',
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            _label(context, 'Banco / billetera'),
            TextFormField(
              controller: _bankCtrl,
              decoration: const InputDecoration(
                hintText: 'ueno bank',
                prefixIcon:
                    Icon(Icons.account_balance_outlined, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            _label(context, 'Número de cuenta o CBU'),
            TextFormField(
              controller: _accountCtrl,
              decoration: const InputDecoration(
                hintText: '0981 123 456',
                prefixIcon: Icon(Icons.numbers_rounded, size: 20),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 28),
            _SectionTitle(
              icon: Icons.auto_awesome_rounded,
              title: 'Inteligencia artificial',
            ),
            _label(context, 'Gemini API Key'),
            TextFormField(
              controller: _geminiCtrl,
              obscureText: _obscureGemini,
              decoration: InputDecoration(
                hintText: 'AQ.Ab8RN6...',
                prefixIcon: const Icon(Icons.key_outlined, size: 20),
                helperText:
                    'Se usa para el importador de productos por captura.',
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureGemini = !_obscureGemini),
                  icon: Icon(
                    _obscureGemini
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  TextStyle? _labelStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(text, style: _labelStyle(context)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(firestoreInstanceProvider);
      final updated = StoreSettings(
        whatsappNumber: PhoneValidator.toWhatsappFormat(_whatsappCtrl.text),
        contactEmail: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        currencySymbol: '₲',
        shippingInfo: _shippingCtrl.text.trim(),
        paymentHolderName: _holderCtrl.text.trim(),
        paymentBank: _bankCtrl.text.trim(),
        paymentAccount: _accountCtrl.text.trim(),
        geminiApiKey: _geminiCtrl.text.trim(),
      );

      await db
          .collection('settings')
          .doc('store')
          .set(updated.toMap(), SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajustes guardados'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}