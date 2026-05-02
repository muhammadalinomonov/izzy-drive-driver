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
              state.errorMessage ?? 'Akkauntni o\'chirib bo\'lmadi',
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
                                                  "${state.profile?.truckName ?? 'No Vehicle model'} ${state.profile?.truckmodel ?? ''}",
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
              child: const Text('Bekor qilish'),
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
      title: 'Tizimdan chiqish',
      message: 'Akkauntdan chiqishni xohlaysizmi?',
      confirmText: 'Chiqish',
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
      title: 'Akkauntni o\'chirish',
      message:
          'Akkauntni o\'chirish qaytarib bo\'lmaydi. Davom etishni xohlaysizmi?',
      confirmText: 'O\'chirish',
      confirmColor: AppColor.red,
    );
    if (!ok || !context.mounted) return;
    context.read<AuthBloc>().add(
          DeleteAccountEvent(
            onSuccess: () {
              if (!context.mounted) return;
              AppSnackBar.showSuccess(context, 'Akkaunt o\'chirildi');
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
          title: 'Mening ma’lumotlarim',
          onTap: () {
            context.push(Pages.editProfile);
          },
        ),
        _ProfileMenuItem(
          icon: Icons.history,
          title: 'Buyurtmalar tarixi',
          onTap: () {
            context.push(Pages.ordersHistory);
          },
        ),
        _ProfileMenuItem(
            icon: Icons.star_border,
            title: 'Ilovamizni baholang',
            onTap: () {}),
        _ProfileMenuItem(
          icon: Icons.language,
          title: 'Til',
          trailing: const Text('O’zbekcha',
              style: TextStyle(color: Colors.grey)),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => const ChooseLanguageBottomSheet(),
            );
          },
        ),
        _ProfileMenuItem(
            icon: Icons.build_outlined, title: 'Usta bo’lish', onTap: () {}),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.logoutStatus != c.logoutStatus,
          builder: (context, state) {
            return _ProfileMenuItem(
              icon: Icons.logout,
              title: 'Tizimdan chiqish',
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
              title: 'Akkauntni o\'chirish',
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
