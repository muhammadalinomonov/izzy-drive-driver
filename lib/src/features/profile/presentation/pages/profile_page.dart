import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/outputs_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/choose_language_bottom_sheet.dart';
import 'package:taxi_app/src/routes/pages.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    context.read<ProfileBloc>().add(LoadProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) =>
            p.logoutStatus != c.logoutStatus ||
            p.deleteAccountStatus != c.deleteAccountStatus,
        listener: (context, state) {
          if (state.deleteAccountStatus == AuthStatus.failure) {
            AppSnackBar.showError(
              context,
              state.errorMessage ?? 'Could not delete account',
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.status == ProfileStatus.loading) {
              return Center(
                child: CupertinoActivityIndicator(color: AppColor.kPrimaryColor),
              );
            } else if (state.status == ProfileStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message ?? 'Something went wrong'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else if (state.status == ProfileStatus.loaded) {
              final profile = state.profile;
              final fullName = profile?.fullName ?? '';
              final email = profile?.email ?? '';
              final initial = fullName.trim().isNotEmpty
                  ? fullName.trim().substring(0, 1).toUpperCase()
                  : '.';
              final mark = profile?.truckMark ?? '';
              final model = profile?.truckmodel ?? '';
              final vehicle = '$mark $model'.trim();
              final topPadding = MediaQuery.paddingOf(context).top;

              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Image.asset(
                      AppImages.profileGradient,
                      width: context.sizeOf.width,
                      height: 257,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12 + topPadding,
                      right: 0,
                      left: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColor.blueMain, const Color(0xFFCE08FF)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName.isEmpty ? 'No user name' : fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isEmpty ? 'no email' : email,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColor.grey,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 168 + topPadding,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom + 16,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 18),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: _VehicleCard(
                                  title: vehicle.isEmpty ? 'No Vehicle model' : vehicle,
                                  amount: r'-$0',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const OutputsScreen()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: _ProfileMenu(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.title,
    required this.amount,
    required this.onTap,
  });

  final String title;
  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 69,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        amount,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                          height: 1.3,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(
                  'assets/images/truck.png',
                  width: 80,
                  height: 52,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu();

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              confirmText,
              style: TextStyle(color: confirmColor ?? AppColor.kPrimaryColor),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _onLogout(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Log out',
      message: 'Do you want to log out of your account?',
      confirmText: 'Sign out',
    );
    if (!ok || !context.mounted) return;
    context.read<AuthBloc>().add(
          LogoutEvent(
            onSuccess: () {
              if (!context.mounted) return;
              context.go(Pages.signIn);
            },
            onError: () {},
          ),
        );
  }

  void _onDeleteAccount(BuildContext context) async {
    final ok = await _confirm(
      context,
      title: 'Delete account',
      message: 'Deleting your account cannot be undone. Do you want to continue?',
      confirmText: 'Delete',
      confirmColor: AppColor.red,
    );
    if (!ok || !context.mounted) return;
    context.read<AuthBloc>().add(
          DeleteAccountEvent(
            onSuccess: () {
              if (!context.mounted) return;
              AppSnackBar.showSuccess(context, 'Account deleted');
              context.go(Pages.signIn);
            },
            onError: () {},
          ),
        );
  }

  void _onChooseLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChooseLanguageBottomSheet(),
    );
  }

  String _localeLabel(BuildContext context) {
    switch (context.locale.languageCode) {
      case 'uz':
        return "O'zbekcha";
      case 'ru':
        return 'Русский';
      case 'en':
      default:
        return 'English';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'My information',
          onTap: () => context.push(Pages.editProfile),
        ),
        _ProfileMenuItem(
          icon: Icons.history_rounded,
          title: 'Order history',
          onTap: () => context.push(Pages.ordersHistory),
        ),
        _ProfileMenuItem(
          icon: Icons.star_border_rounded,
          title: 'Rate our app',
          onTap: () {},
        ),
        // _ProfileMenuItem(
        //   icon: Icons.help_outline_rounded,
        //   title: 'For questions or suggestions',
        //   onTap: () {},
        // ),
        // _ProfileMenuItem(
        //   icon: Icons.language_rounded,
        //   title: 'Language',
        //   trailing: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text(
        //         _localeLabel(context),
        //         style: TextStyle(
        //           fontSize: 14,
        //           color: AppColor.grey,
        //           letterSpacing: -0.3,
        //         ),
        //       ),
        //       const SizedBox(width: 6),
        //       Icon(Icons.chevron_right_rounded, size: 22, color: AppColor.grey),
        //     ],
        //   ),
        //   onTap: () => _onChooseLanguage(context),
        // ),
        _ProfileMenuItem(
          icon: Icons.build_outlined,
          title: 'Become a master',
          onTap: () {},
        ),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.logoutStatus != c.logoutStatus,
          builder: (context, state) => _ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Log out',
            trailing: state.logoutStatus == AuthStatus.loading
                ? const SizedBox(width: 18, height: 18, child: CupertinoActivityIndicator())
                : null,
            onTap: () => _onLogout(context),
          ),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.deleteAccountStatus != c.deleteAccountStatus,
          builder: (context, state) => _ProfileMenuItem(
            icon: Icons.delete_outline_rounded,
            iconColor: AppColor.red,
            titleColor: AppColor.red,
            title: 'Delete account',
            trailing: state.deleteAccountStatus == AuthStatus.loading
                ? const SizedBox(width: 18, height: 18, child: CupertinoActivityIndicator())
                : null,
            onTap: () => _onDeleteAccount(context),
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: titleColor ?? Colors.black,
                  letterSpacing: -0.3,
                  height: 1.3,
                ),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, size: 22, color: AppColor.grey),
          ],
        ),
      ),
    );
  }
}
