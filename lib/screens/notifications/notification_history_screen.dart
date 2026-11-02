import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_header.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_table.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/reusable_widgets/loading_indicator.dart';
import '../../widgets/reusable_widgets/rdx_dropdown.dart';

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({
    super.key,
  });

  @override
  ConsumerState<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen> {
  String _statusFilter = 'All Statuses';

  @override
  void initState() {
    super.initState();

    Future.microtask(
      () => ref.read(notificationProvider).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(notificationProvider);
    final colors = AppColors.of(context);

    final filteredNotifications = _filteredNotifications(
      provider.history,
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          const RdxHeader(
            title: 'Notification History',
            showBackButton: true,
          ),
          Expanded(
            child: provider.isLoading && provider.history.isEmpty
                ? const LoadingIndicator()
                : Padding(
                    padding: Responsive.pagePadding(
                      context,
                      top: context.h(14),
                      bottom: context.h(0),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        final isMobile = width < 600;
                        final isTablet = width >= 600 && width < 1000;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFilters(
                              colors,
                              isMobile,
                              isTablet,
                              provider,
                            ),
                            SizedBox(
                              height: isMobile ? context.h(14) : context.h(18),
                            ),
                            Expanded(
                              child: _buildTable(
                                context,
                                colors,
                                filteredNotifications,
                              ),
                            ),
                            // ── Footer ─────────────────────────────────
                            Padding(
                              padding: EdgeInsets.only(
                                top: context.h(8),
                                bottom: context.h(16),
                              ),
                              child: Text(
                                'Showing ${filteredNotifications.length} of ${provider.history.length} notifications',
                                style: AppTextStyles.label(context)
                                    .copyWith(color: colors.textMuted),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERS
  // ============================================================

  Widget _buildFilters(
    AppColorScheme colors,
    bool isMobile,
    bool isTablet,
    NotificationProvider provider,
  ) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _filterButton(
                  colors,
                  'Last 7 Days',
                  Icons.calendar_today_outlined,
                ),
              ),
              SizedBox(width: context.w(8)),
              Expanded(
                child: _statusDropdown(colors),
              ),
            ],
          ),
          SizedBox(height: context.h(9)),
          SizedBox(
            height: context.h(40),
            width: double.infinity,
            child: _refreshButton(
              colors,
              provider,
            ),
          ),
        ],
      );
    }

    if (isTablet) {
      return Wrap(
        spacing: context.w(8),
        runSpacing: context.h(8),
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _filterButton(
            colors,
            'Last 7 Days',
            Icons.calendar_today_outlined,
          ),
          _statusDropdown(colors),
          _refreshButton(
            colors,
            provider,
          ),
        ],
      );
    }

    return Row(
      children: [
        _filterButton(
          colors,
          'Last 7 Days',
          Icons.calendar_today_outlined,
        ),
        SizedBox(width: context.w(8)),
        _statusDropdown(colors),
        const Spacer(),
        _refreshButton(
          colors,
          provider,
        ),
      ],
    );
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  Widget _filterButton(
    AppColorScheme colors,
    String text,
    IconData icon,
  ) {
    return SizedBox(
      height: context.h(40),
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(
          icon,
          size: context.h(15),
          color: colors.textSecondary,
        ),
        label: Text(text,
            style: AppTextStyles.body(context)
                .copyWith(color: colors.textSecondary)),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          backgroundColor: colors.surface,
          side: BorderSide(
            color: colors.border,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.w(12),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.h(7)),
          ),
          minimumSize: Size(0, context.h(40)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS DROPDOWN
  // ============================================================

  Widget _statusDropdown(
    AppColorScheme colors,
  ) {
    return SizedBox(
      width: context.w(160),
      child: RdxDropdown<String>(
        value: _statusFilter,
        isDense: true,
        items: const [
          'All Statuses',
          'Sent',
          'Scheduled',
        ],
        labelBuilder: (v) => v,
        onChanged: (value) {
          if (value == null) return;
          setState(() => _statusFilter = value);
        },
      ),
    );
  }

  // ============================================================
  // REFRESH BUTTON
  // ============================================================

  Widget _refreshButton(
    AppColorScheme colors,
    NotificationProvider provider,
  ) {
    final isLoading = provider.isLoading;

    return RdxActionButton(
      label: 'Refresh',
      onPressed: isLoading
          ? null
          : () async {
              await ref.read(notificationProvider).load();
            },
      isPrimary: true,
      isLoading: isLoading,
      height: context.h(40),
      leadingIcon: Icons.refresh,
      iconSize: context.h(18),
    );
  }

  // ============================================================
  // TABLE (RdxTable — same as Inventory screen)
  // ============================================================

  Widget _buildTable(
    BuildContext context,
    AppColorScheme colors,
    List<NotificationModel> notifications,
  ) {
    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications found.',
          style: AppTextStyles.bodySecondary(context),
        ),
      );
    }

    return RdxTable(
      showFooter: false,
      columns: [
        RdxTableColumn(title: 'STATUS', minWidth: context.w(130), flex: 1),
        RdxTableColumn(title: 'NOTIFICATION TITLE', minWidth: context.w(300), flex: 4),
        RdxTableColumn(title: 'DATE / TIME', minWidth: context.w(150), flex: 2),
        RdxTableColumn(title: 'ACTIONS', minWidth: context.w(90), flex: 1),
      ],
      rows: notifications.map((item) {
        final status = item.scheduled ? 'Scheduled' : 'Sent';
        final statusColor =
            item.scheduled ? AppColors.warning : AppColors.success;
        final date = item.scheduledAt ?? item.sentAt ?? item.createdAt;

        return [
          // STATUS
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: context.w(7),
                height: context.h(7),
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.w(8)),
              Flexible(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySecondary(context)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
            ],
          ),

          // TITLE
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySecondary(context)
                .copyWith(color: colors.textPrimary),
          ),

          // DATE / TIME
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDate(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textPrimary),
              ),
              SizedBox(height: context.h(3)),
              Text(
                _formatTime(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySecondary(context)
                    .copyWith(color: colors.textMuted),
              ),
            ],
          ),

          // ACTIONS
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RdxTableActionButton(
                icon: Icons.visibility_outlined,
                tooltip: 'View notification',
                onPressed: () {},
              ),
              if (item.scheduled) ...[
                SizedBox(width: context.w(4)),
                RdxTableActionButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit notification',
                  onPressed: () {},
                ),
              ],
            ],
          ),
        ];
      }).toList(),
    );
  }

  // ============================================================
  // FILTERING
  // ============================================================

  List<NotificationModel> _filteredNotifications(
    List<NotificationModel> notifications,
  ) {
    switch (_statusFilter) {
      case 'Sent':
        return notifications
            .where(
              (item) => !item.scheduled,
            )
            .toList();

      case 'Scheduled':
        return notifications
            .where(
              (item) => item.scheduled,
            )
            .toList();

      default:
        return notifications;
    }
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatDate(DateTime date) {
    return '${_month(date.month)} '
        '${date.day}, '
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}
