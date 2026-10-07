import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/constants/app_strings.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/vertex_logo.dart';
import '../../../../services/firebase/firebase_providers.dart';

class StoreFooter extends ConsumerWidget {
  const StoreFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    final columns = [
      const _FooterColumn(
        title: AppStrings.footerContact,
        children: [
          _FooterLink(
            label: AppStrings.footerWhatsapp,
            icon: Icons.chat_bubble_outline_rounded,
            url: 'https://wa.me/595981000000',
          ),
          _FooterLink(
            label: AppStrings.footerEmail,
            icon: Icons.mail_outline_rounded,
            url: 'mailto:contacto@tiendavertex.com',
          ),
          _FooterText(
            label: AppStrings.footerLocation,
            icon: Icons.location_on_outlined,
          ),
        ],
      ),
      const _FooterColumn(
        title: AppStrings.footerAbout,
        children: [
          _FooterText(label: AppStrings.footerAboutText),
          SizedBox(height: 12),
          _FooterText(label: AppStrings.footerGuarantee, bold: true),
        ],
      ),
      _FooterColumn(
        title: AppStrings.footerLinks,
        children: [
          _FooterNavLink(
            label: AppStrings.linkShipping,
            onTap: () => context.go('/terminos'),
          ),
          _FooterNavLink(
            label: AppStrings.linkReturns,
            onTap: () => context.go('/devoluciones'),
          ),
          _FooterNavLink(
            label: AppStrings.linkFaq,
            onTap: () => context.go('/faq'),
          ),
        ],
      ),
    ];

    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 64 : 24,
        vertical: 40,
      ),
      child: Column(
        children: [
          // ── Marca + columnas ────────────────────────────
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      VertexLogo(markSize: 32, wordmarkSize: 18),
                      SizedBox(height: 16),
                      Text(
                        AppStrings.tagline,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                ...columns.expand((c) => [
                      Expanded(flex: 2, child: c),
                      const SizedBox(width: 32),
                    ]),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VertexLogo(markSize: 32, wordmarkSize: 18),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.tagline,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                for (final c in columns) ...[
                  c,
                  const SizedBox(height: 24),
                ],
              ],
            ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),

          // ── Créditos ────────────────────────────────────
          Text(
            AppStrings.footerCredit,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Subwidgets ───────────────────────────────────────────────

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({
    required this.label,
    required this.icon,
    required this.url,
  });

  final String label;
  final IconData icon;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterNavLink extends StatelessWidget {
  const _FooterNavLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText({
    required this.label,
    this.icon,
    this.bold = false,
  });
  final String label;
  final IconData? icon;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: bold
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}