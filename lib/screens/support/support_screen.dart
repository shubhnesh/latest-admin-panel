import 'package:flutter/material.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';

/// Contact Technical Support — matches the provided design.
class SupportScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SupportScreen({
    super.key,
    this.onBack,
  });

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Order Issues';
  bool _sending = false;

  static const _categories = [
    ('Order Issues', Icons.receipt_long_outlined),
    ('Payment Failure', Icons.payment_outlined),
    ('App Errors', Icons.bug_report_outlined),
    ('Store Closure', Icons.storefront_outlined),
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   const SnackBar(content: Text('Please fill subject and message')),
      // );
      return;
    }
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);
    _subjectController.clear();
    _messageController.clear();
    // ScaffoldMessenger.of(context).showSnackBar(
    //   const SnackBar(content: Text('Ticket submitted successfully')),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isNarrow = !Responsive.isDesktop(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: 'Contact Technical Support',
            showBackButton: true,
            onBack: widget.onBack,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = isNarrow
                    ? ListView(
                        padding:
                            Responsive.pagePadding(context, top: context.h(10)),
                        children: [
                          SizedBox(height: context.h(20)),
                          _buildCategorySection(context, colors),
                          SizedBox(height: context.h(20)),
                          _buildFormSection(context, colors),
                          SizedBox(height: context.h(24)),
                          _buildDirectChannels(context, colors),
                        ],
                      )
                    : Padding(
                        padding: Responsive.pagePadding(context),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: context.h(20)),
                                    _buildCategorySection(context, colors),
                                    SizedBox(height: context.h(20)),
                                    _buildFormSection(context, colors),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: context.w(24)),
                            SizedBox(
                              width: context.w(300),
                              child: _buildDirectChannels(context, colors),
                            ),
                          ],
                        ),
                      );

                return content;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions? Our Support team is here. Create tickets or reply to existing problems.',
          style: AppTextStyles.bodySecondary(context),
        ),
      ],
    );
  }

  Widget _buildCategorySection(BuildContext context, AppColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category_outlined,
              size: context.h(18),
              color: AppColors.primary,
            ),
            SizedBox(width: context.w(8)),
            Text(
              'Issue Category',
              style: AppTextStyles.section(context),
            ),
          ],
        ),
        SizedBox(height: context.h(12)),
        Wrap(
          spacing: context.w(10),
          runSpacing: context.h(10),
          children: _categories.map((c) {
            final selected = _selectedCategory == c.$1;
            return Material(
              color: selected
                  ? AppColors.primary.withOpacity(0.15)
                  : colors.surface,
              borderRadius: BorderRadius.circular(context.h(10)),
              child: InkWell(
                onTap: () => setState(() => _selectedCategory = c.$1),
                borderRadius: BorderRadius.circular(context.h(10)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(14),
                    vertical: context.h(12),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.h(10)),
                    border: Border.all(
                      color: selected ? AppColors.primary : colors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.$2,
                        size: context.h(18),
                        color:
                            selected ? AppColors.primary : colors.textSecondary,
                      ),
                      SizedBox(width: context.w(8)),
                      Text(
                        c.$1,
                        style: selected
                            ? AppTextStyles.label(context)
                                .copyWith(color: colors.primary)
                            : AppTextStyles.label(context)
                                .copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormSection(BuildContext context, AppColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: context.h(18),
                color: AppColors.primary,
              ),
              SizedBox(width: context.w(8)),
              Text(
                'Describe the Issue',
                style: AppTextStyles.section(context),
              ),
            ],
          ),
          SizedBox(height: context.h(16)),
          RdxTextField(
            controller: _subjectController,
            maxLength: 40,
            label: 'Subject',
            hint: 'Brief summary of the issue',
          ),
          SizedBox(height: context.h(16)),
          RdxTextField(
            controller: _messageController,
            maxLength: 300,
            label: 'Describe the issue',
            hint: 'Provide as much detail as possible…',
            maxLines: 6,
          ),
          SizedBox(height: context.h(16)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: context.h(28)),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(context.h(10)),
              border: Border.all(
                color: colors.border,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: context.h(32), color: colors.textMuted),
                SizedBox(height: context.h(8)),
                Text('Drag & drop screenshots or logs',
                    style: AppTextStyles.bodySecondary(context)),
                SizedBox(height: context.h(4)),
                Text('PNG, JPG, PDF up to 10 MB',
                    style: AppTextStyles.body(context)),
              ],
            ),
          ),
          SizedBox(height: context.h(20)),
          Align(
            alignment: Alignment.centerRight,
            child: RdxActionButton(
              label: _sending ? 'Submitting' : 'Submit Ticket',
              onPressed: _sending ? null : _submit,
              isPrimary: true,
              isLoading: _sending,
              leadingIcon: Icons.send_rounded,
              iconSize: context.h(17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectChannels(BuildContext context, AppColorScheme colors) {
    return Container(
      padding: EdgeInsets.all(context.h(20)),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.h(12)),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Direct Channels',
            style: AppTextStyles.section(context),
          ),
          SizedBox(height: context.h(16)),
          _channelRow(
            context,
            colors,
            icon: Icons.email_outlined,
            title: 'Email Support 1',
            subtitle: 'kashyapshubhnesh@gmail.com',
          ),
          SizedBox(height: context.h(16)),
          _channelRow(
            context,
            colors,
            icon: Icons.email_outlined,
            title: 'Email Support 2',
            subtitle: 'siddhantbisht440@gmail.com',
          ),
          SizedBox(height: context.h(14)),
          _channelRow(
            context,
            colors,
            icon: Icons.phone_outlined,
            title: 'Phone Hotline 1',
            subtitle: '+91 9528714534',
          ),
          SizedBox(height: context.h(14)),
          _channelRow(
            context,
            colors,
            icon: Icons.phone_outlined,
            title: 'Phone Hotline 2',
            subtitle: '+91 8791158024',
          ),
          // SizedBox(height: context.h(14)),
          // _channelRow(
          //   context,
          //   colors,
          //   icon: Icons.chat_bubble_outline,
          //   title: 'Live Chat',
          //   subtitle: 'Available 9 AM – 9 PM IST',
          // ),
          SizedBox(height: context.h(20)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(context.h(14)),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(context.h(10)),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: context.h(18), color: AppColors.primary),
                    SizedBox(width: context.w(8)),
                    Text('Average Response',
                        style: AppTextStyles.bodySecondary(context)
                            .copyWith(color: colors.textPrimary)),
                  ],
                ),
                SizedBox(height: context.h(6)),
                Text('Under 2 hours on business days',
                    style: AppTextStyles.bodySecondary(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _channelRow(
    BuildContext context,
    AppColorScheme colors, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: context.w(40),
          height: context.h(40),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(context.h(10)),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: context.h(20),
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: context.w(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.primary),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
