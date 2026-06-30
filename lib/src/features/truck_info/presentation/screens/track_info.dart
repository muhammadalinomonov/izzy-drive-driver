import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_app/src/core/components/app_snack_bar.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/core/utils/extensions.dart';
import 'package:taxi_app/src/core/widgets/app_button.dart';
import 'package:taxi_app/src/features/auth/presentation/widgets/auth_input_widget.dart';
import 'package:taxi_app/src/features/truck_info/data/model/driver_info_put_model.dart';
import 'package:taxi_app/src/features/truck_info/domain/model/track_model.dart';
import 'package:taxi_app/src/features/truck_info/presentation/bloc/bloc/track_info_bloc.dart';
import 'package:taxi_app/src/routes/pages.dart';
import 'package:shimmer/shimmer.dart';

class TrackInfoScreen extends StatefulWidget {
  const TrackInfoScreen({super.key});

  @override
  State<TrackInfoScreen> createState() => _TrackInfoScreenState();
}

class _TrackInfoScreenState extends State<TrackInfoScreen> {
  @override
  void initState() {
    super.initState();
    BlocProvider.of<TrackInfoBloc>(context).add(
      GetTrackMarskEvent(
        onError: () {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppSnackBar.showError(
              context,
              'Error occured while getting track marks',
            );
          });
        },
      ),
    );
    _yearController.addListener(() {
      setState(() {
        productionYear = _yearController.text;
      });
    });
    _addressController.addListener(() {
      setState(() {
        address = _addressController.text;
      });
    });
    _licenseController.addListener(() {
      setState(() {
        licenseNumber = _licenseController.text;
      });
    });
  }

  TruckMark? pickeDtruckMark;
  TruckModel? pickedTruckModel;
  String? productionYear;
  String? address;
  String? licenseNumber;
  File? _truckImageFile;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  bool isCreatingProccess = false;

  Future<void> _pickTruckImage() async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;
      setState(() => _truckImageFile = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Rasm tanlashda xato: $e');
    }
  }

  @override
  void dispose() {
    _yearController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Image.asset(
                      'assets/images/gradient2.png',
                      fit: BoxFit.fill,
                      height: 600,
                    ),
                  ),
                  Expanded(
                    child: Image.asset(
                      'assets/images/gradient1.png',
                      fit: BoxFit.fill,
                      height: 600,
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: context.padding.top + 12,
                bottom: context.padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          "Truck information",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "We recommend filling in your truck information - it will help you keep track of your records!",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 28),
                        const Text(
                          "Truck photo",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _pickTruckImage,
                            borderRadius: BorderRadius.circular(16),
                            child: _truckImageFile != null
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _truckImageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: () => setState(
                                              () => _truckImageFile = null,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(
                                                Icons.close,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: Colors.blue.shade700,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Tap to add a photo",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Truck make",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<TrackInfoBloc, TrackInfoState>(
                          buildWhen: (prev, curr) =>
                              prev.marksStatus != curr.marksStatus ||
                              prev.truckMarkResponse != curr.truckMarkResponse,
                          builder: (context, state) {
                            if (state.marksStatus == TrackInfoStatus.error) {
                              WidgetsBinding.instance.addPostFrameCallback((v) {
                                AppSnackBar.showError(
                                  context,
                                  state.errorMessage ??
                                      'Error occured please try again',
                                );
                              });
                            }
                            return TruckDropDownWidget(
                              isLoading:
                                  state.marksStatus == TrackInfoStatus.loading,
                              hint: 'Select truck make',
                              value: pickeDtruckMark?.name,
                              items:
                                  state.truckMarkResponse?.data.map((mark) {
                                    return DropdownMenuItem(
                                      value: mark.name,
                                      child: Text(mark.name),
                                    );
                                  }).toList() ??
                                  [],
                              onChanged: (value) {
                                final selectedMark = state
                                    .truckMarkResponse
                                    ?.data
                                    .firstWhere((mark) => mark.name == value);
                                if (selectedMark != null) {
                                  setState(() {
                                    pickeDtruckMark = selectedMark;
                                    pickedTruckModel = null;
                                  });
                                  BlocProvider.of<TrackInfoBloc>(context).add(
                                    GetTrackModelsEvent(
                                      id: selectedMark.id.toString(),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Truck model",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        BlocBuilder<TrackInfoBloc, TrackInfoState>(
                          buildWhen: (prev, curr) =>
                              prev.modelsStatus != curr.modelsStatus ||
                              prev.truckModelResponse !=
                                  curr.truckModelResponse,
                          builder: (context, state) {
                            final models =
                                state.truckModelResponse?.data.models ?? [];
                            final markSelected = pickeDtruckMark != null;
                            return TruckDropDownWidget(
                              isLoading:
                                  state.modelsStatus == TrackInfoStatus.loading,
                              enabled: markSelected,
                              hint: markSelected
                                  ? 'Select truck model'
                                  : 'Select make first',
                              value: pickedTruckModel?.name,
                              items: models
                                  .map(
                                    (model) => DropdownMenuItem(
                                      value: model.name,
                                      child: Text(model.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                final selectedModel = models.firstWhere(
                                  (model) => model.name == value,
                                );
                                setState(() {
                                  pickedTruckModel = selectedModel;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        AuthInputWidget(
                          hint: 'Enter',
                          label: 'Production year',
                          textInputType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          controller: _yearController,
                        ),
                        const SizedBox(height: 20),
                        AuthInputWidget(
                          hint: 'Address',
                          label: 'Address',
                          textInputAction: TextInputAction.next,
                          controller: _addressController,
                        ),
                        const SizedBox(height: 20),
                        AuthInputWidget(
                          hint: 'License number',
                          label: 'License number',
                          textInputAction: TextInputAction.done,
                          controller: _licenseController,
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          isLoading: isCreatingProccess,
                          title: "Save",
                          onTap: () {
                            isCreatingProccess = true;
                            setState(() {});
                            context.read<TrackInfoBloc>().add(
                              PutDriverInfoEvent(
                                data: DriverInfoPutModel(
                                  truckImageFile: _truckImageFile,
                                  avatar: '',
                                  truckImage: '',
                                  truckMark:
                                      pickeDtruckMark?.id.toString() ?? '',
                                  truckModel:
                                      pickedTruckModel?.id.toString() ?? '',
                                  truckYear: productionYear ?? '',
                                  phoneNumber: '',
                                  licenseNumber: licenseNumber ?? '',
                                  address: address ?? '',
                                ),
                                onError: () {
                                  isCreatingProccess = false;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    v,
                                  ) {
                                    AppSnackBar.showError(
                                      context,
                                      'Error occured',
                                    );
                                  });
                                },
                                onSuccess: () {
                                  isCreatingProccess = false;
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    v,
                                  ) {
                                    AppSnackBar.showSuccess(
                                      context,
                                      'Your driver profile has been updated',
                                    );
                                    context.go(Pages.main);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        // Truck info is optional ("we recommend ..."), so the
                        // user must always be able to leave this onboarding
                        // step and enter the app. Without this, a failed/empty
                        // submission traps the user on this screen.
                        Center(
                          child: TextButton(
                            onPressed: isCreatingProccess
                                ? null
                                : () => context.go(Pages.main),
                            child: Text(
                              'Skip for now',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColor.kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
}

class TruckDropDownWidget extends StatelessWidget {
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  final String hint;
  final bool isLoading;
  final bool enabled;

  const TruckDropDownWidget({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint = 'Select',
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
    final isInteractive = enabled && items.isNotEmpty;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value != null
              ? AppColor.kPrimaryColor.withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: Colors.white,
          elevation: 6,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: isInteractive
                ? AppColor.kPrimaryColor
                : AppColor.lightGreyBlue,
          ),
          iconSize: 26,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hint: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              hint,
              style: TextStyle(
                color: AppColor.lightGreyBlue,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          selectedItemBuilder: (context) => items
              .map(
                (item) => Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    child: item.child,
                  ),
                ),
              )
              .toList(),
          items: items,
          onChanged: isInteractive ? onChanged : null,
        ),
      ),
    );
  }
}
