import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_icons.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/src/features/common/presentation/widgets/common_image.dart';
import 'package:taxi_app/src/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/src/features/profile/presentation/pages/outputs_screen.dart';
import 'package:taxi_app/src/features/profile/presentation/widgets/choose_language_bottom_sheet.dart';
import 'package:taxi_app/src/routes/pages.dart';

/// Opens the IzzyDrive Mechanic ("master") app on the platform's store.
Future<void> _openBecomeAMaster(BuildContext context) async {
  final url = Platform.isIOS
      ? 'https://apps.apple.com/us/app/izzydrive-mechanic/id6751299030'
      : 'https://play.google.com/store/apps/details?id=com.izzy.drive.mechanic';
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    AppSnackBar.showError(context, 'Could not open the store');
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    context.read<ProfileBloc>().add(LoadProfile());
  }

  Future<void> _onAvatarTap() async {
    if (context.read<ProfileBloc>().state.uploadAvatarStatus ==
        FormzSubmissionStatus.inProgress) {
      return;
    }
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AvatarSourceSheet(),
    );
    if (source == null || !mounted) return;
    await _pickAndUpload(source);
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (picked == null || !mounted) return;
      context.read<ProfileBloc>().add(
        UploadAvatarEvent(
          file: File(picked.path),
          onError: (message) {
            if (!mounted) return;
            AppSnackBar.showError(context, message);
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Rasm tanlashda xato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF3F6),
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
                  color: AppColor.kPrimaryColor,
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
              // Ism va familiyaning bosh harflaridan (1–2 ta) yasalgan
              // default avatar matni. "Eshonov Fakhriyor" → "EF".
              final initial = avatarInitials(fullName);
              final mark = profile?.truckMark ?? '';
              final model = profile?.truckmodel ?? '';
              final vehicle = '$mark $model'.trim();
              final topPadding = MediaQuery.paddingOf(context).top;
              final headerHeight = 257.0 + topPadding;

              return SingleChildScrollView(
                // physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header bo'limi - oq fonli, dekorativ blur doiralar bilan.
                    // Vehicle card uning pastki qismiga yopishib turadi.
                    SizedBox(
                      height: headerHeight + 34,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: headerHeight,
                            child: const _ProfileHeaderBg(),
                          ),
                          Positioned(
                            top: 45 + topPadding,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _AvatarWidget(
                                  photoUrl: profile?.photo ?? '',
                                  initial: initial,
                                  name: fullName,
                                  isUploading:
                                      state.uploadAvatarStatus ==
                                      FormzSubmissionStatus.inProgress,
                                  onTap: _onAvatarTap,
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
                          // Vehicle card - header pastki qismiga yopishtirilgan
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 0,
                            child: _VehicleCard(
                              title: vehicle.isEmpty
                                  ? 'No Vehicle model'
                                  : vehicle,
                              amount: r'$0',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const OutputsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: _ProfileMenu(),
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

/// Header foni - Figma'da oq fonga ikkita yumshoq blur doira (chap-binafsha,
/// o'ng-cyan) qo'shilgan. Profile gradient PNG ham xuddi shu effektni beradi,
/// shu sababli mavjud asset'ni ishlatamiz; agar dizayn pixel-precise kerak
/// bo'lsa, dekorativ doiralar manually qo'shilishi mumkin.
class _ProfileHeaderBg extends StatelessWidget {
  const _ProfileHeaderBg();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImages.profileGradient,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
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
          svgIcon: AppIcons.memberList,
          title: 'My information',
          onTap: () => context.push(Pages.editProfile),
        ),
        const SizedBox(height: 8),
        _ProfileMenuItem(
          svgIcon: AppIcons.timePast,
          title: 'Order history',
          onTap: () => context.push(Pages.ordersHistory),
        ),
        const SizedBox(height: 8),
        // "Rate our app" is hidden until the driver app is published on the
        // stores — there is nothing to rate yet, and a non-functional button
        // is an App Review (2.2) risk. Re-enable with the in_app_review native
        // prompt (or the store URL) once the app is live.
        // _ProfileMenuItem(
        //   svgIcon: AppIcons.frame,
        //   title: 'Rate our app',
        //   onTap: () {},
        // ),
        // const SizedBox(height: 8),
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
          svgIcon: AppIcons.tools,
          title: 'Become a master',
          onTap: () => _openBecomeAMaster(context),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.logoutStatus != c.logoutStatus,
          builder: (context, state) => _ProfileMenuItem(
            icon: Icons.logout_rounded,
            title: 'Log out',
            trailing: state.logoutStatus == AuthStatus.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CupertinoActivityIndicator(),
                  )
                : null,
            onTap: () => _onLogout(context),
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (p, c) => p.deleteAccountStatus != c.deleteAccountStatus,
          builder: (context, state) => _ProfileMenuItem(
            icon: Icons.delete_outline_rounded,
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
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData? icon;
  final String? svgIcon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _ProfileMenuItem({
    this.icon,
    this.svgIcon,
    required this.title,
    this.trailing,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  }) : assert(
         icon != null || svgIcon != null,
         'Provide either icon or svgIcon',
       );

  @override
  Widget build(BuildContext context) {
    // SVG iconlar Figma'dan native rang bilan (Gray/5 = #43484B) eksport
    // qilingan. Agar `iconColor` aniq berilmasa (default holat) - colorFilter
    // qo'llamaymiz, shunda SVG o'z rangida ko'rinadi. Material `Icon` esa
    // doim qora bo'ladi, shu sababli unga ham Gray/5 default beramiz.
    const defaultGray = Color(0xFF43484B);
    final materialIconColor = iconColor ?? defaultGray;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (svgIcon != null)
                  SvgPicture.asset(
                    svgIcon!,
                    width: 24,
                    height: 24,
                    colorFilter: iconColor != null
                        ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                        : null,
                  )
                else
                  Icon(icon, size: 24, color: materialIconColor),
                const SizedBox(width: 18),
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
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 24,
                      color: AppColor.grey,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 80x80 circular avatar with a small floating badge in the top-right.
///
/// Figma frames `1913:4738` (no-photo state with "+" badge over a
/// blue→purple gradient + initial letter) and `14441:5941` (uploaded photo
/// with a pencil/edit badge) are both represented here - we swap the badge
/// icon based on whether a photo URL is present, and overlay a centered
/// progress indicator while [isUploading] is true.
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.photoUrl,
    required this.initial,
    required this.name,
    required this.isUploading,
    required this.onTap,
  });

  final String photoUrl;
  final String initial;
  final String name;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 90,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar circle - gradient + initial when no photo, network
            // image once uploaded.
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                height: 80,
                width: 80,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasPhoto
                      ? null
                      : LinearGradient(
                          colors: avatarGradientFor(name),
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                ),
                alignment: Alignment.center,
                child: hasPhoto
                    ? Image.network(
                        photoUrl,
                        // Key URL bilan bog'langan - URL o'zgarganda Flutter
                        // eski Image elementini emas, yangisini yaratadi va
                        // shu sabab yangi rasm darrov tushadi (oldingi rasm
                        // widget kesh'iga yopishib qolmaydi).
                        key: ValueKey(photoUrl),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColor.kPrimary2Color,
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: TextStyle(
                              color: AppColor.kPrimaryColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                color: AppColor.lightGrey,
                                alignment: Alignment.center,
                                child: CupertinoActivityIndicator(
                                  color: AppColor.kPrimaryColor,
                                ),
                              ),
                      )
                    : initial.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 40,
                      )
                    : Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
              ),
            ),
            // Uploading overlay - dims the avatar while the request is
            // in flight and shows a spinner over the centre of the circle.
            if (isUploading)
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  alignment: Alignment.center,
                  child: const CupertinoActivityIndicator(color: Colors.white),
                ),
              ),
            // Edit badge - small white circle in the top-right with a "+"
            // (no photo) or pencil (photo present) icon, matching the
            // Figma frames 1913:4738 / 14441:5941.
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasPhoto ? Icons.edit : Icons.add,
                  size: 14,
                  color: AppColor.kPrimaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for choosing the avatar source - gallery or camera.
/// Returns the selected [ImageSource] (or null on dismiss).
class _AvatarSourceSheet extends StatelessWidget {
  const _AvatarSourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Asosiy karta - drag handle + sarlavha + ikkita variant.
            // Divider o'rniga element orasidagi bo'sh joy ishlatilgan.
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColor.lightGrey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose photo source',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  const SizedBox(height: 8),
                  _SourceTile(
                    icon: Icons.photo_camera_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Cancel - alohida karta sifatida iOS action sheet uslubida.
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEFF3F6),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 22, color: AppColor.kPrimaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColor.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
