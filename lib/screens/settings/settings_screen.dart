import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/screens/settings/operating_hours_editor.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/buttons/rdx_toggle_button.dart';

class SettingsScreen extends ConsumerWidget {
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  const SettingsScreen({
    super.key,
    this.onSupport,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final provider = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        padding: Responsive.pagePadding(context, top: context.h(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('System Settings',
                          style: AppTextStyles.heading(context)),
                      SizedBox(height: context.h(4)),
                      Text(
                          'Manage essential configuration for your restaurant operations.',
                          style: AppTextStyles.bodySecondary(context)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.h(18)),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final identity = _IdentityCard(colors: colors);
                final hours = _SettingsCard(
                  title: 'Operating Hours',
                  icon: Icons.access_time_outlined,
                  colors: colors,
                  child: const OperatingHoursEditor(),
                );
                final delivery = _DeliveryRulesCard(
                  provider: provider,
                  colors: colors,
                );
                final supportAccount = _SupportAccountCard(
                  colors: colors,
                  onSupport: onSupport,
                  onLogout: onLogout,
                );

                if (compact) {
                  return Column(children: [
                    identity,
                    SizedBox(height: context.h(14)),
                    hours,
                    SizedBox(height: context.h(14)),
                    delivery,
                    SizedBox(height: context.h(14)),
                    supportAccount,
                  ]);
                }
                return Column(children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(children: [
                          identity,
                          SizedBox(height: context.h(14)),
                          hours,
                          SizedBox(height: context.h(14)),
                          delivery,
                          SizedBox(height: context.h(14)),
                          supportAccount,
                        ]),
                      ),
                    ],
                  ),
                ]);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportAccountCard extends StatelessWidget {
  final AppColorScheme colors;
  final VoidCallback? onSupport;
  final VoidCallback? onLogout;

  const _SupportAccountCard({
    required this.colors,
    required this.onSupport,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Support & Account',
        icon: Icons.manage_accounts_outlined,
        colors: colors,
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.support_agent_outlined,
                size: 20,
                color: colors.textSecondary,
              ),
              title: Text(
                'Support',
                style: AppTextStyles.section(context)
                    .copyWith(color: colors.textPrimary),
              ),
              subtitle: Text(
                'Get help with your account or restaurant setup.',
                style: AppTextStyles.bodySecondary(context),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: colors.textMuted,
              ),
              onTap: onSupport,
            ),
            Divider(height: context.h(1), color: colors.divider),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.exit_to_app_rounded,
                size: 20,
                color: Color(0xFFE05151),
              ),
              title: const Text(
                'Log out',
                style: TextStyle(
                  color: Color(0xFFE05151),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Sign out of your admin account.',
                style: AppTextStyles.bodySecondary(context),
              ),
              onTap: onLogout,
            ),
          ],
        ),
      );
}

class _IdentityCard extends ConsumerWidget {
  final AppColorScheme colors;
  const _IdentityCard({required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    return _SettingsCard(
      title: 'Restaurant Identity',
      icon: Icons.storefront_outlined,
      colors: colors,
      child: Column(children: [
        _LabeledInput(
            label: 'Restaurant Name',
            value: settings.restaurantName,
            colors: colors),
        SizedBox(height: context.h(10)),
        _LabeledInput(
            label: 'Primary Address', value: settings.address, colors: colors),
        SizedBox(height: context.h(10)),
        Row(children: [
          Expanded(
              child: _LabeledInput(
                  label: 'Support Email',
                  value: settings.email,
                  colors: colors)),
          SizedBox(width: context.w(10)),
          Expanded(
              child: _LabeledInput(
                  label: 'Contact Phone',
                  value: settings.phone,
                  colors: colors))
        ]),
        SizedBox(height: context.h(10)),
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.restaurantProfile),
                icon: Icon(Icons.open_in_new, size: context.h(20)),
                label: Text('Edit Restaurant Profile',
                    style: AppTextStyles.section(context)
                        .copyWith(color: colors.primary)))),
      ]),
    );
  }
}

// class _RulesCard extends ConsumerWidget {
//   final SettingsProvider provider;
//   final AppColorScheme colors;
//   const _RulesCard({required this.provider, required this.colors});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) => _SettingsCard(
//       title: 'Core Operational Rules',
//       icon: Icons.tune,
//       colors: colors,
//       child: Column(children: [
//         _RuleTile(
//             title: 'Auto-Dispatch Orders',
//             subtitle:
//                 'Automatically assign accepted orders to available riders within a 2km radius.',
//             value: provider.autoAcceptOrders,
//             onChanged: provider.toggleAutoAccept,
//             colors: colors),
//         _RuleTile(
//             title: 'Require Manager Approval for Refunds',
//             subtitle:
//                 'Prevent auto-refunds on canceled orders exceeding \$50.00.',
//             value: provider.requireManagerApprovalForRefunds,
//             onChanged: provider.toggleManagerApproval,
//             colors: colors),
//         _RuleTile(
//             title: 'Source Pricing Automation',
//             subtitle: 'Enable dynamic pricing adjustments during peak hours.',
//             value: provider.keepPricingConsistent,
//             onChanged: provider.toggleKeepPricing,
//             colors: colors),
//       ]));
// }

class _SettingsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AppColorScheme colors;
  final Widget child;
  const _SettingsCard(
      {required this.title,
      required this.icon,
      required this.colors,
      required this.child});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        context.w(12),
        context.h(12),
        context.w(12),
        context.h(14),
      ),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(context.h(8)),
          border: Border.all(color: colors.border)),
      child: Column(children: [
        Row(children: [
          Icon(icon, size: context.h(18), color: AppColors.primary),
          SizedBox(width: context.w(8)),
          Text(title,
              style: AppTextStyles.section(context)
                  .copyWith(color: colors.textPrimary)),
        ]),
        SizedBox(height: context.h(10)),
        Divider(height: context.h(1), color: colors.divider),
        SizedBox(height: context.h(10)),
        child
      ]));
}

class _RuleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final AppColorScheme colors;
  const _RuleTile(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged,
      required this.colors});

  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(8)),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: AppTextStyles.bodySecondary(context)
                .copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: context.h(3)),
          Text(
            subtitle,
            style: AppTextStyles.body(context)
                .copyWith(color: colors.textSecondary),
          )
        ])),
        RdxToggleButton(
          value: value,
          onChanged: onChanged,
        ),
      ]));
}

class _LabeledInput extends StatelessWidget {
  final String label;
  final String value;
  final AppColorScheme colors;
  const _LabeledInput(
      {required this.label, required this.value, required this.colors});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _FieldLabel(label, colors),
        SizedBox(height: context.h(6)),
        _SettingsInput(value: value, colors: colors)
      ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final AppColorScheme colors;
  const _FieldLabel(this.label, this.colors);
  @override
  Widget build(BuildContext context) => Text(label,
      style: AppTextStyles.bodySecondary(context)
          .copyWith(color: colors.textSecondary));
}

class _SettingsInput extends StatelessWidget {
  final String value;
  final AppColorScheme colors;
  const _SettingsInput({required this.value, required this.colors});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: context.w(10),
          vertical: context.h(9),
        ),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(context.h(5)),
          border: Border.all(color: colors.border),
        ),
        child: Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body(context)
                .copyWith(color: colors.textSecondary)),
      );
}

class _DeliveryRulesCard extends StatelessWidget {
  final SettingsProvider provider;
  final AppColorScheme colors;

  const _DeliveryRulesCard({required this.provider, required this.colors});

  @override
  Widget build(BuildContext context) => _SettingsCard(
        title: 'Delivery Rules',
        icon: Icons.delivery_dining_outlined,
        colors: colors,
        child: Column(
          children: [
            _RuleTile(
              title: 'Late Night Delivery (₹5)',
              subtitle:
                  'Automatically applies after the configured weekday or weekend closing time.',
              value: provider.lateNightDelivery,
              onChanged: provider.toggleLateNightDelivery,
              colors: colors,
            ),
          ],
        ),
      );
}
