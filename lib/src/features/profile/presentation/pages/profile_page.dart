import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/constants/feature_flags.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/outputs_screen.dart';
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
                  child: CupertinoActivityIndicator(
                      color: AppColor.kPrimaryColor));
            } else if (state.status == ProfileStatus.loaded) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
                  children: [
                    Image.asset(AppImages.profileGradient,
                        width: context.sizeOf.width,
                        height: 257,
                        fit: BoxFit.cover),
                    Positioned(
                      top: 12 + MediaQuery.paddingOf(context).top,
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
                                colors: [
                                  AppColor.blueMain,
                                  const Color(0xffCE08FF),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              state.profile?.fullName.isNotEmpty == true
                                  ? state.profile!.fullName
                                      .substring(0, 1)
                                      .toUpperCase()
                                  : '.',
                              style: context.textTheme.headlineLarge!.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            state.profile?.fullName ?? 'No user name',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(state.profile?.email ?? 'no email',
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.grey)),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 168 + MediaQuery.paddingOf(context).top,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColor.white,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                        ),
                        width: MediaQuery.sizeOf(context).width,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom + 16,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // Vehicle card
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) =>
                                            const OutputsScreen()));
                                  },
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${state.profile?.truckMark} ${state.profile?.truckmodel ?? 'No Vehicle model'}",
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text('\$0',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.grey)),
                                              ],
                                            ),
                                          ),
                                          Image.asset(
                                            'assets/images/truck.png',
                                            width: 64,
                                            height: 48,
                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _ProfileMenu(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state.status == ProfileStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message ?? 'Something went wrong'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _loadProfile();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            } else {
              return const SizedBox();
            }
          },
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
      builder: (dialogCtx) {
        return AlertDialog(
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
        );
      },
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
      message:
          'Deleting your account cannot be undone. Do you want to continue?',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileMenuItem(
          icon: Icons.person_outline,
          title: 'My information',
          onTap: () {
            context.push(Pages.editProfile);
          },
        ),
        _ProfileMenuItem(
          icon: Icons.history,
          title: 'Order history',
          onTap: () {
            context.push(Pages.ordersHistory);
          },
        ),
        _ProfileMenuItem(
            icon: Icons.star_border,
            title: 'Rate our app',
            onTap: () {}),
        _ProfileMenuItem(
            icon: Icons.build_outlined, title: 'Become a master', onTap: () {}),
        ValueListenableBuilder<bool>(
          valueListenable: FeatureFlags.webSocketEnabledNotifier,
          builder: (context, enabled, _) {
            return SwitchListTile(
              secondary: Icon(
                enabled ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: Colors.black87,
              ),
              title: const Text('Real-time connection (WebSocket)'),
              subtitle: Text(
                enabled
                    ? 'New offers and status updates arrive instantly'
                    : 'REST only — refresh manually',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              value: enabled,
              activeThumbColor: AppColor.kPrimaryColor,
              onChanged: (v) => FeatureFlags.setWebSocketEnabled(v),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            );
          },
        ),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.logoutStatus != c.logoutStatus,
          builder: (context, state) {
            return _ProfileMenuItem(
              icon: Icons.logout,
              title: 'Log out',
              trailing: state.logoutStatus == AuthStatus.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(),
                    )
                  : null,
              onTap: () => _onLogout(context),
            );
          },
        ),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.deleteAccountStatus != c.deleteAccountStatus,
          builder: (context, state) {
            return _ProfileMenuItem(
              icon: Icons.delete_outline,
              iconColor: AppColor.red,
              titleColor: AppColor.red,
              title: 'Delete account',
              trailing: state.deleteAccountStatus == AuthStatus.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CupertinoActivityIndicator(),
                    )
                  : null,
              onTap: () => _onDeleteAccount(context),
            );
          },
        ),
        const SizedBox(height: 16),
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
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87),
      title: Text(title, style: TextStyle(color: titleColor)),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
    );
  }
}
