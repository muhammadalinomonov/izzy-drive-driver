import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/constants/color/app_images.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
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
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.status == ProfileStatus.loading) {
            return Center(child: CupertinoActivityIndicator(color: AppColor.kPrimaryColor));
          } else if (state.status == ProfileStatus.loaded) {
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Image.asset(AppImages.profileGradient, width: context.sizeOf.width, height: 257, fit: BoxFit.cover),
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
                              colors: [AppColor.blueMain, Color(0xffCE08FF)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            state.profile?.fullName.isNotEmpty == true
                                ? state.profile!.fullName.substring(0, 1).toUpperCase()
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
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(state.profile?.email ?? 'no email', style: TextStyle(fontSize: 15, color: Colors.grey)),
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
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      width: MediaQuery.sizeOf(context).width,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Vehicle card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => OutputsScreen()));
                                // Navigate to vehicle details or edit page
                              },
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "${state.profile?.truckName ?? 'No Vehicle model'} ${state.profile?.truckmodel ?? ''}",
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            ),
                                            SizedBox(height: 8),
                                            Text('\$0', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
                          // Menu items
                          _ProfileMenu(),
                        ],
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
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _loadProfile();
                    },
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          } else {
            return const SizedBox();
          }
        },
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
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
        _ProfileMenuItem(icon: Icons.star_border, title: 'Ilovamizni baholang', onTap: () {}),
        _ProfileMenuItem(icon: Icons.help_outline, title: 'Savol yoki takliflar uchun', onTap: () {}),
        _ProfileMenuItem(
          icon: Icons.language,
          title: 'Til',
          trailing: const Text('O’zbekcha', style: TextStyle(color: Colors.grey)),
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => ChooseLanguageBottomSheet(),
            );
          },
        ),
        _ProfileMenuItem(icon: Icons.build_outlined, title: 'Usta bo’lish', onTap: () {}),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ProfileMenuItem({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      horizontalTitleGap: 12,
    );
  }
}
