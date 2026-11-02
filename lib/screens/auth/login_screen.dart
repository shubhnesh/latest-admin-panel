import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rdx_admin/core/theme/app_colors.dart';
import 'package:rdx_admin/core/theme/text_styles.dart';
import 'package:rdx_admin/core/utils/responsive_size.dart';
import 'package:rdx_admin/widgets/buttons/rdx_action_button.dart';
import 'package:rdx_admin/widgets/dialogs/category_dialog.dart';
import 'package:rdx_admin/widgets/reusable_widgets/loading_indicator.dart';
import 'package:rdx_admin/widgets/reusable_widgets/rdx_text_field.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isRegister = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final auth = ref.read(authProvider);

    final success = _isRegister
        ? await auth.register(
            _emailController.text.trim(),
            _passwordController.text,
          )
        : await auth.signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Unable to continue.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(context.w(20)),
          elevation: 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Stack(
        children: [
          const _PageBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(28),
                  vertical: context.h(28),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 900;

                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.w(960),
                      ),
                      child: isDesktop
                          ? _buildDesktopLayout(context, auth)
                          : _buildMobileLayout(context, auth),
                    );
                  },
                ),
              ),
            ),
          ),
          if (auth.isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP
  // ===========================================================================

  Widget _buildDesktopLayout(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.w(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: context.w(60),
            offset: Offset(0, context.h(24)),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.035),
            blurRadius: context.w(90),
            spreadRadius: -context.w(10),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 45,
              child: _buildBrandPanel(context),
            ),
            Expanded(
              flex: 55,
              child: _buildLoginPanel(context, auth),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MOBILE
  // ===========================================================================

  Widget _buildMobileLayout(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: context.w(520),
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(30),
        context.h(30),
        context.w(30),
        context.h(26),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(context.w(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: context.w(45),
            offset: Offset(0, context.h(20)),
          ),
        ],
      ),
      child: _buildLoginContent(context, auth),
    );
  }

  // ===========================================================================
  // LEFT BRAND PANEL
  // ===========================================================================

  Widget _buildBrandPanel(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: context.h(690),
      ),
      padding: EdgeInsets.fromLTRB(
        context.w(52),
        context.h(50),
        context.w(45),
        context.h(35),
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF171B22),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -context.w(150),
            right: -context.w(140),
            child: _darkGlow(
              context,
              context.w(390),
            ),
          ),
          Positioned(
            bottom: -context.w(170),
            left: -context.w(170),
            child: _darkGlow(
              context,
              context.w(430),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDarkBrand(context),
              SizedBox(height: context.h(65)),
              Container(
                width: context.w(38),
                height: context.h(3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              SizedBox(height: context.h(22)),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: context.w(38),
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Admin ',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: 'Panel',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.h(16)),
              Text(
                'Manage your restaurant,\n'
                'orders, customers and more —\n'
                'all in one place.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: context.w(15),
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              _buildDashboardPreview(context),
              SizedBox(height: context.h(20)),
              Text(
                'RDX ADMIN • RESTAURANT MANAGEMENT',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: context.w(9),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDarkBrand(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          'assets/images/logo/rdx_logo_picture.svg',
          width: context.w(48),
          height: context.h(48),
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            Colors.white,
            BlendMode.srcIn,
          ),
        ),
        SizedBox(width: context.w(13)),
        Text(
          'RDX',
          style: TextStyle(
            color: Colors.white,
            fontSize: context.w(24),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _darkGlow(
    BuildContext context,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DASHBOARD PREVIEW
  // ===========================================================================

  Widget _buildDashboardPreview(BuildContext context) {
    return Transform.rotate(
      angle: -0.035,
      child: Container(
        height: context.h(245),
        width: double.infinity,
        padding: EdgeInsets.all(context.w(13)),
        decoration: BoxDecoration(
          color: const Color(0xFF222731),
          borderRadius: BorderRadius.circular(context.w(17)),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: context.w(30),
              offset: Offset(0, context.h(15)),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: context.w(43),
              padding: EdgeInsets.symmetric(
                vertical: context.h(8),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF191D24),
                borderRadius: BorderRadius.circular(context.w(10)),
              ),
              child: Column(
                children: [
                  _dashboardSideIcon(
                    context,
                    Icons.home_rounded,
                    true,
                  ),
                  _dashboardSideIcon(
                    context,
                    Icons.receipt_long_rounded,
                    false,
                  ),
                  _dashboardSideIcon(
                    context,
                    Icons.restaurant_menu_rounded,
                    false,
                  ),
                  _dashboardSideIcon(
                    context,
                    Icons.people_alt_outlined,
                    false,
                  ),
                  const Spacer(),
                  _dashboardSideIcon(
                    context,
                    Icons.settings_outlined,
                    false,
                    isLast: true,
                  ),
                ],
              ),
            ),
            SizedBox(width: context.w(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _smallDashText(
                        context,
                        'Overview',
                        14,
                        true,
                      ),
                      const Spacer(),
                      Container(
                        width: context.w(32),
                        height: context.h(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(14)),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          'Orders',
                          '248',
                          Icons.shopping_bag_outlined,
                        ),
                      ),
                      SizedBox(width: context.w(8)),
                      Expanded(
                        child: _statCard(
                          context,
                          'Revenue',
                          '₹42.8K',
                          Icons.trending_up_rounded,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.h(10)),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(context.w(12)),
                      decoration: BoxDecoration(
                        color: const Color(0xFF292E37),
                        borderRadius: BorderRadius.circular(context.w(10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _smallDashText(
                            context,
                            'Weekly sales',
                            9,
                            false,
                          ),
                          SizedBox(height: context.h(8)),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return CustomPaint(
                                  size: Size(constraints.maxWidth,
                                      constraints.maxHeight),
                                  painter: _DashboardChartPainter(
                                    color: AppColors.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dashboardSideIcon(
    BuildContext context,
    IconData icon,
    bool active, {
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: isLast ? 0 : context.h(6),
      ),
      width: context.w(29),
      height: context.h(29),
      decoration: BoxDecoration(
        color:
            active ? AppColors.primary.withOpacity(0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(context.w(8)),
      ),
      child: Icon(
        icon,
        size: context.w(15),
        color: active ? AppColors.primary : Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(context.w(10)),
      decoration: BoxDecoration(
        color: const Color(0xFF292E37),
        borderRadius: BorderRadius.circular(context.w(10)),
      ),
      child: Row(
        children: [
          Container(
            width: context.w(27),
            height: context.h(27),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.11),
              borderRadius: BorderRadius.circular(context.w(7)),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: context.w(13),
            ),
          ),
          SizedBox(width: context.w(8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: context.w(8),
                  ),
                ),
                SizedBox(height: context.h(2)),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.w(12),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallDashText(
    BuildContext context,
    String text,
    double size,
    bool bold,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(
          bold ? 0.82 : 0.48,
        ),
        fontSize: context.w(size),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  // ===========================================================================
  // RIGHT LOGIN PANEL
  // ===========================================================================

  Widget _buildLoginPanel(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        context.w(65),
        context.h(50),
        context.w(65),
        context.h(38),
      ),
      child: _buildLoginContent(context, auth),
    );
  }

  Widget _buildLoginContent(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Text(
            'We. Serve. Passion',
            style: TextStyle(
              color: const Color(0xFF6F788A),
              fontSize: context.w(12),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
        ),
        SizedBox(height: context.h(58)),
        Text(
          _isRegister ? 'Create your account' : 'Welcome',
          style: AppTextStyles.heading(context).copyWith(
            color: const Color(0xFF182033),
            fontSize: context.w(31),
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        SizedBox(height: context.h(9)),
        Text(
          _isRegister
              ? 'Enter your details to create your RDX admin account.'
              : 'Sign in to your RDX admin account to continue.',
          style: AppTextStyles.bodySecondary(context).copyWith(
            color: const Color(0xFF7B8494),
            fontSize: context.w(14),
            height: 1.45,
          ),
        ),
        SizedBox(height: context.h(35)),
        _buildLabel(
          context,
          'Email Address',
        ),
        SizedBox(height: context.h(8)),
        RdxTextField(
          controller: _emailController,
          maxLength: 50,
          keyboardType: TextInputType.emailAddress,
          hint: 'Enter your email address',
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            size: context.w(18),
          ),
        ),
        SizedBox(height: context.h(21)),
        _buildLabel(
          context,
          'Password',
        ),
        SizedBox(height: context.h(8)),
        RdxTextField(
          controller: _passwordController,
          maxLength: 50,
          obscureText: _obscurePassword,
          hint: 'Enter your password',
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: context.w(18),
          ),
          suffixIcon: IconButton(
            tooltip: _obscurePassword ? 'Show password' : 'Hide password',
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: context.w(18),
            ),
          ),
        ),
        if (!_isRegister) ...[
          SizedBox(height: context.h(9)),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: auth.isLoading ? null : _showForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(2),
                  vertical: context.h(5),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot password?',
                style: AppTextStyles.label(context).copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: context.w(13),
                ),
              ),
            ),
          ),
        ],
        SizedBox(height: context.h(22)),
        _buildSignInButton(
          context,
          auth,
        ),
        SizedBox(height: context.h(24)),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isRegister
                    ? 'Already have an account?'
                    : 'Don\'t have an account?',
                style: AppTextStyles.label(context).copyWith(
                  color: const Color(0xFF7B8494),
                  fontSize: context.w(13),
                ),
              ),
              TextButton(
                onPressed: auth.isLoading
                    ? null
                    : () {
                        setState(() {
                          _isRegister = !_isRegister;
                        });
                      },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.w(4),
                    vertical: context.h(5),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _isRegister ? 'Sign in' : 'Create one',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: context.w(13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LABEL
  // ===========================================================================

  Widget _buildLabel(
    BuildContext context,
    String text,
  ) {
    return Text(
      text,
      style: AppTextStyles.label(context).copyWith(
        color: const Color(0xFF30394A),
        fontSize: context.w(13),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ===========================================================================
  // SIGN IN BUTTON
  // ===========================================================================

  Widget _buildSignInButton(
    BuildContext context,
    AuthProvider auth,
  ) {
    return Container(
      width: double.infinity,
      height: context.h(52),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          context.w(13),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: context.w(18),
            offset: Offset(0, context.h(8)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          context.w(13),
        ),
        child: RdxActionButton(
          label: _isRegister ? 'Create Account' : 'Sign In',
          onPressed: auth.isLoading ? null : _submit,
          isPrimary: true,
          isLoading: false,
        ),
      ),
    );
  }

  // ===========================================================================
  // LOADING
  // ===========================================================================

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.white.withOpacity(0.62),
        child: const LoadingIndicator(),
      ),
    );
  }

  // ===========================================================================
  // FORGOT PASSWORD
  // ===========================================================================

  Future<void> _showForgotPassword() async {
    final sent = await CategoryEntryDialog.show<bool>(
      context,
      title: 'Reset password',
      nameLabel: 'Email Address',
      nameHint: 'Enter your email address',
      nameMaxLength: 50,
      description: 'Enter your email address to receive a reset link.',
      initialName: _emailController.text,
      saveButtonLabel: 'Send reset link',
      onSave: (email, _) async {
        final success = await ref.read(authProvider).sendPasswordReset(email);
        if (!success) {
          throw StateError(
            ref.read(authProvider).errorMessage ?? 'Unable to send reset link.',
          );
        }
        return true;
      },
    );

    if (sent == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// =============================================================================
// PAGE BACKGROUND
// =============================================================================

class _PageBackground extends StatelessWidget {
  const _PageBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),
          Positioned(
            top: -context.w(180),
            right: -context.w(130),
            child: _backgroundGlow(
              context,
              context.w(420),
              AppColors.primary.withOpacity(0.06),
            ),
          ),
          Positioned(
            bottom: -context.w(220),
            left: -context.w(170),
            child: _backgroundGlow(
              context,
              context.w(500),
              AppColors.primary.withOpacity(0.025),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundGlow(
    BuildContext context,
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// BACKGROUND GRID
// =============================================================================

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF172033).withOpacity(0.018)
      ..strokeWidth = 1;

    const gap = 32.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _BackgroundPainter oldDelegate,
  ) {
    return false;
  }
}

// =============================================================================
// DASHBOARD CHART
// =============================================================================

class _DashboardChartPainter extends CustomPainter {
  final Color color;

  const _DashboardChartPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    if (!size.width.isFinite || !size.height.isFinite) return;

    final points = <Offset>[
      Offset(0, size.height * 0.72),
      Offset(size.width * 0.14, size.height * 0.58),
      Offset(size.width * 0.27, size.height * 0.64),
      Offset(size.width * 0.40, size.height * 0.43),
      Offset(size.width * 0.53, size.height * 0.51),
      Offset(size.width * 0.67, size.height * 0.28),
      Offset(size.width * 0.81, size.height * 0.36),
      Offset(size.width, size.height * 0.12),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 2.7, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashboardChartPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}