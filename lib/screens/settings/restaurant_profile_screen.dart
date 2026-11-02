import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rdx_admin/core/theme/text_styles.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_size.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/reusable_widgets/rdx_text_field.dart';
import '../../widgets/buttons/rdx_action_button.dart';
import '../../widgets/reusable_widgets/rdx_header.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  const RestaurantProfileScreen({super.key});

  @override
  ConsumerState<RestaurantProfileScreen> createState() =>
      _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState
    extends ConsumerState<RestaurantProfileScreen> {
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController addressController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;

  Uint8List? _logoBytes;
  String? _logoName;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();

    final settings = ref.read(settingsProvider);

    nameController = TextEditingController(text: settings.restaurantName);
    descriptionController = TextEditingController(text: settings.description);
    addressController = TextEditingController(text: settings.address);
    phoneController = TextEditingController(text: settings.phone);
    emailController = TextEditingController(text: settings.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();

    super.dispose();
  }

  Future<void> _pickLogo() async {
    if (_isUploadingLogo) return;

    setState(() {
      _isUploadingLogo = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (!mounted) return;

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploadingLogo = false;
        });
        return;
      }

      final file = result.files.single;
      const maxSizeInBytes = 2 * 1024 * 1024;

      if (file.size > maxSizeInBytes) {
        setState(() {
          _isUploadingLogo = false;
        });
        return;
      }

      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _isUploadingLogo = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to read the selected image.',
              style: AppTextStyles.bodySecondary(context).copyWith(
                color: Colors.white,
              ),
            ),
          ),
        );

        return;
      }

      setState(() {
        _logoBytes = bytes;
        _logoName = file.name;
        _isUploadingLogo = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isUploadingLogo = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select logo. Please try again.',
            style: AppTextStyles.bodySecondary(context).copyWith(
              color: Colors.white,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final ok = await ref.read(settingsProvider).save(
          name: nameController.text,
          desc: descriptionController.text,
          addr: addressController.text,
          ph: phoneController.text,
          em: emailController.text,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Settings saved' : 'Failed to save settings',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final provider = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          RdxHeader(
            title: 'Restaurant Profile',
            showBackButton: true,
            actions: [
              RdxActionButton.discard(
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              SizedBox(width: context.w(10)),
              RdxActionButton.save(
                isLoading: provider.isLoading,
                onPressed: _save,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: Responsive.pagePadding(context, top: 8, bottom: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileSection(
                        title: 'Brand Identity',
                        icon: Icons.image_outlined,
                        colors: colors,
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.background,
                                border: Border.all(
                                  color: colors.border,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _logoBytes != null
                                  ? Image.memory(
                                      _logoBytes!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.restaurant,
                                      color: AppColors.primary,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Brand Identity',
                                    style: AppTextStyles.bodySecondary(context),
                                  ),
                                  Text(
                                    'Recommended size: 512x512px. Max 2MB.',
                                    style: AppTextStyles.body(context),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _pickLogo,
                                    child: _isUploadingLogo
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            _logoBytes != null
                                                ? 'Change Logo'
                                                : 'Upload New',
                                            style:
                                                AppTextStyles.section(context)
                                                    .copyWith(
                                              color: colors.primary,
                                            ),
                                          ),
                                  ),
                                  if (_logoName != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _logoName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style:
                                          AppTextStyles.body(context).copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ProfileSection(
                        title: 'Basic Information',
                        icon: Icons.description_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: nameController,
                              maxLength: 25,
                              label: 'Restaurant Name',
                            ),
                            const SizedBox(height: 12),
                            RdxTextField(
                              controller: descriptionController,
                              maxLength: 300,
                              label: 'Brief Description',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      _ProfileSection(
                        title: 'Location & Contact',
                        icon: Icons.location_on_outlined,
                        colors: colors,
                        child: Column(
                          children: [
                            RdxTextField(
                              controller: addressController,
                              maxLength: 80,
                              label: 'Primary Address',
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 480;

                                final phone = RdxTextField(
                                  controller: phoneController,
                                  maxLength: 10,
                                  label: 'Support Phone',
                                );

                                final email = RdxTextField(
                                  controller: emailController,
                                  maxLength: 80,
                                  label: 'Support Email',
                                );

                                return narrow
                                    ? Column(
                                        children: [
                                          phone,
                                          const SizedBox(height: 12),
                                          email,
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(child: phone),
                                          const SizedBox(width: 12),
                                          Expanded(child: email),
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ProfileSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final AppColorScheme colors;
  final Widget child;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.colors,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: context.h(18), color: AppColors.primary),
                SizedBox(width: context.w(8)),
                Text(
                  title,
                  style: AppTextStyles.section(context).copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}
