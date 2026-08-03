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
import 'package:taxi_app/core/components/app_snack_bar.dart';
import 'package:taxi_app/core/constants/color/app_color.dart';
import 'package:taxi_app/core/constants/color/app_icons.dart';
import 'package:taxi_app/core/session/premium_session.dart';
import 'package:taxi_app/features/auth/presentation/bloc/bloc/auth_bloc.dart';
import 'package:taxi_app/features/common/presentation/widgets/common_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:taxi_app/features/profile/presentation/bloc/driver_profile/driver_profile_bloc.dart';
import 'package:taxi_app/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:taxi_app/features/trips/data/model/vehicle_model.dart';
import 'package:taxi_app/features/profile/presentation/pages/outputs_screen.dart';
import 'package:taxi_app/features/profile/presentation/widgets/choose_language_bottom_sheet.dart';
import 'package:taxi_app/routes/pages.dart';

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
    context.read<DriverProfileBloc>().add(const DriverProfileLoaded());
  }

  /// Pull-to-refresh reloads both backends. The legacy izzydrive profile still
  /// owns the avatar; the Quadrix profile owns name, contact and vehicles.
  Future<void> _refresh() async {
    context.read<ProfileBloc>().add(LoadProfile());
    context.read<DriverProfileBloc>().add(const DriverProfileRefreshed());
    await Future.delayed(const Duration(milliseconds: 350));
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
        child: RefreshIndicator.adaptive(
          onRefresh: _refresh,
          child: BlocBuilder<DriverProfileBloc, DriverProfileState>(
            builder: (context, driver) {
              return BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  final profile = driver.profile;
                  final legacy = state.profile;

                  // Only show the skeleton on a genuinely cold screen. Once
                  // either backend has answered there is something worth
                  // rendering, and a refresh must never collapse it.
                  final isCold = profile == null &&
                      legacy == null &&
                      driver.status != DriverProfileStatus.failure &&
                      state.status != ProfileStatus.error;
                  if (isCold) return const _ProfileSkeleton();

                  // Both backends failed with nothing cached - the only real
                  // error state.
                  if (profile == null &&
                      legacy == null &&
                      (driver.status == DriverProfileStatus.failure ||
                          state.status == ProfileStatus.error)) {
                    return _ProfileErrorView(
                      message: driver.errorMessage.isNotEmpty
                          ? driver.errorMessage
                          : (state.message ?? 'Something went wrong'),
                      errorCode: driver.errorCode,
                      onRetry: _loadProfile,
                    );
                  }

                  // Name and contact prefer the Quadrix profile and fall back
                  // to the legacy account, so the header stays populated while
                  // the new endpoints are still rolling out.
                  final name = profile?.displayName.isNotEmpty == true
                      ? profile!.displayName
                      : (legacy?.fullName ?? '');
                  final contact = profile?.phone.isNotEmpty == true
                      ? profile!.phone
                      : (legacy?.email ?? '');

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 16,
                      bottom: MediaQuery.paddingOf(context).bottom + 24,
                    ),
                    children: [
                      _ProfileHeaderCard(
                        name: name,
                        contact: contact,
                        driverNumber: profile?.driverNumber ?? '',
                        licenseLabel: profile?.licenseLabel ?? '',
                        photoUrl: legacy?.photo ?? '',
                        initials: avatarInitials(name),
                        isPremium: driver.isPremium,
                        isUploading: state.uploadAvatarStatus ==
                            FormzSubmissionStatus.inProgress,
                        onAvatarTap: _onAvatarTap,
                      ),
                      const SizedBox(height: 14),
                      _BalanceCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const OutputsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _VehiclesSection(
                        vehicles: driver.vehicles,
                        failed: driver.vehiclesFailed,
                        loading: driver.status == DriverProfileStatus.loading,
                        onRetry: _loadProfile,
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: _ProfileMenu(),
                      ),
                    ],
                  );
                },
              );
            },
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
          // Drop the entitlement so the next driver to sign in on this device
          // doesn't inherit premium features from the cached flag.
          PremiumSession.clear();
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
          PremiumSession.clear();
          if (!context.mounted) return;
          AppSnackBar.showSuccess(context, 'Account deleted');
          context.go(Pages.signIn);
        },
        onError: () {},
      ),
    );
  }

  // Both helpers below back the language-picker row, which is commented out
  // further down this file rather than deleted. Kept deliberately so the
  // switcher can be re-enabled by uncommenting one block - the analyzer's
  // "unused" warning is expected until then.
  // ignore: unused_element
  void _onChooseLanguage(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChooseLanguageBottomSheet(),
    );
  }

  // ignore: unused_element
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
                    width: 22,
                    height: 22,
                    colorFilter: iconColor != null
                        ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                        : null,
                  )
                else
                  Icon(icon, size: 22, color: materialIconColor),
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
                      size: 22,
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
                borderRadius: BorderRadius.circular(18),
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
                      fontSize: 15,
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
                  height: 50,
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
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
          height: 52,
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
                      fontSize: 15,
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

/// Redesigned header: avatar, name, contact, and the Premium badge.
///
/// One card instead of the old decorative header stack, so the screen reads as
/// a consistent stack of cards from top to bottom.
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.contact,
    required this.driverNumber,
    required this.licenseLabel,
    required this.photoUrl,
    required this.initials,
    required this.isPremium,
    required this.isUploading,
    required this.onAvatarTap,
  });

  final String name;
  final String contact;
  final String driverNumber;
  final String licenseLabel;
  final String photoUrl;
  final String initials;
  final bool isPremium;
  final bool isUploading;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _AvatarWidget(
            photoUrl: photoUrl,
            initial: initials,
            name: name,
            isUploading: isUploading,
            onTap: onAvatarTap,
          ),
          const SizedBox(height: 12),
          Text(
            name.isEmpty ? 'No user name' : name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          if (contact.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              contact,
              style: TextStyle(
                fontSize: 13,
                color: AppColor.grey,
                letterSpacing: -0.3,
                height: 1.3,
              ),
            ),
          ],
          // The badge fades and scales in, so it does not simply pop into
          // existence when the profile request resolves a moment after paint.
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: isPremium
                ? const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: _PremiumBadge(),
                  )
                : const SizedBox(width: double.infinity),
          ),
          if (driverNumber.isNotEmpty || licenseLabel.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: AppColor.grey2),
            const SizedBox(height: 12),
            Row(
              children: [
                if (driverNumber.isNotEmpty)
                  Expanded(
                    child: _HeaderFact(
                      label: 'Driver ID',
                      value: driverNumber,
                    ),
                  ),
                if (licenseLabel.isNotEmpty)
                  Expanded(
                    child: _HeaderFact(
                      label: 'License',
                      value: licenseLabel,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderFact extends StatelessWidget {
  const _HeaderFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColor.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

/// Premium indicator, shown only when `is_paid_user` is true.
class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFE6AE06), Color(0xFFF5D06B)],
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 15, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept from the previous design so the Outputs screen stays reachable - the
/// old vehicle card was the only route to it.
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColor.kPrimary2Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Balance',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
                Text(
                  r'$0',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.black,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AppColor.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vehicles assigned to the driver, from `GET mobile/vehicles`.
///
/// Carries its own empty and error states: no assigned truck is a normal
/// response per docs §3.4, and a failed vehicles call must not take down a
/// profile that loaded fine.
class _VehiclesSection extends StatelessWidget {
  const _VehiclesSection({
    required this.vehicles,
    required this.failed,
    required this.loading,
    required this.onRetry,
  });

  final List<VehicleModel> vehicles;
  final bool failed;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              'Vehicles',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColor.black,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _body(context),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (vehicles.isEmpty && failed) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Could not load vehicles',
              style: TextStyle(fontSize: 13, color: AppColor.grey),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (vehicles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            loading ? 'Loading vehicles...' : 'No vehicles assigned',
            style: TextStyle(fontSize: 13, color: AppColor.grey),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < vehicles.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 1, color: AppColor.grey2),
            ),
          _VehicleRow(vehicle: vehicles[i]),
        ],
      ],
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({required this.vehicle});

  final VehicleModel vehicle;

  @override
  Widget build(BuildContext context) {
    final spec = [
      if (vehicle.year > 0) '${vehicle.year}',
      vehicle.make,
      vehicle.model,
    ].where((p) => p.isNotEmpty).join(' ');

    final plate = [
      vehicle.licensePlate,
      if (vehicle.licenseState.isNotEmpty) vehicle.licenseState,
    ].where((p) => p.isNotEmpty).join(' · ');

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_shipping_rounded,
              size: 22,
              color: AppColor.kPrimaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vehicle.label.isEmpty ? 'Vehicle' : vehicle.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                if (spec.isNotEmpty || plate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    [spec, plate].where((p) => p.isNotEmpty).join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: AppColor.grey),
                  ),
                ],
              ],
            ),
          ),
          if (vehicle.status.isNotEmpty) _StatusChip(active: vehicle.isActive),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF00A911) : AppColor.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Shimmer placeholder for the cold-start load.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double height) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFE3E8EB),
            borderRadius: BorderRadius.circular(16),
          ),
        );

    return Shimmer.fromColors(
      baseColor: const Color(0xFFE3E8EB),
      highlightColor: const Color(0xFFF7F9FB),
      period: const Duration(milliseconds: 1400),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 16),
        children: [box(210), box(70), box(120), box(240)],
      ),
    );
  }
}

class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({
    required this.message,
    required this.errorCode,
    required this.onRetry,
  });

  final String message;
  final String errorCode;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // A missing toll account is a setup problem, not a transient failure -
    // retrying it forever would be pointless, so it gets its own copy.
    final isNotConnected = errorCode == 'TOLL_SESSION_MISSING';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      children: [
        Icon(
          isNotConnected ? Icons.link_off_rounded : Icons.error_outline_rounded,
          size: 40,
          color: AppColor.grey,
        ),
        const SizedBox(height: 12),
        Text(
          isNotConnected
              ? 'trips.notConnected'.tr()
              : (message.isEmpty ? 'Something went wrong' : message),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColor.grey),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: onRetry,
            child: const Text('Try again'),
          ),
        ),
      ],
    );
  }
}
