import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxi_app/src/core/constants/color/app_color.dart';
import 'package:taxi_app/src/features/cancel_reasons/data/model/cancel_reason_model.dart';
import 'package:taxi_app/src/features/cancel_reasons/data/repo/cancel_reason_repo_impl.dart';
import 'package:taxi_app/src/features/cancel_reasons/data/source/cancel_reason_data_source.dart';
import 'package:taxi_app/src/features/cancel_reasons/domain/repo/cancel_reason_repo.dart';

const int _kOtherId = -1;
const int _kOtherMaxLength = 500;

/// Open the cancel-reason picker. Returns:
///  - `null` if the user dismissed it — caller should abort the cancel flow.
///  - [CancelReasonChoice] containing either a `reasonId` or `customText`
///    (never both) when the user confirms.
Future<CancelReasonChoice?> showCancelReasonSheet(BuildContext context) {
  return showModalBottomSheet<CancelReasonChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (sheetContext) => const _CancelReasonSheet(),
  );
}

class _CancelReasonSheet extends StatefulWidget {
  const _CancelReasonSheet();

  @override
  State<_CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<_CancelReasonSheet> {
  final CancelReasonRepo _repo = CancelReasonRepoImpl(
    dataSource: CancelReasonDataSource(),
  );

  final TextEditingController _otherController = TextEditingController();
  final FocusNode _otherFocus = FocusNode();

  bool _loading = true;
  String _error = '';
  List<CancelReasonModel> _reasons = const [];

  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _otherController.addListener(_onOtherChanged);
    _fetch();
  }

  @override
  void dispose() {
    _otherController.removeListener(_onOtherChanged);
    _otherController.dispose();
    _otherFocus.dispose();
    super.dispose();
  }

  void _onOtherChanged() {
    setState(() {});
  }

  Future<void> _fetch() async {
    final response = await _repo.fetch(audience: 'driver');
    if (!mounted) return;
    if (response.errorText.isEmpty) {
      setState(() {
        _loading = false;
        _error = '';
        _reasons = response.data ?? const [];
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.errorText;
      });
    }
  }

  bool get _canConfirm {
    if (_selectedId == null) return false;
    if (_selectedId == _kOtherId) {
      return _otherController.text.trim().isNotEmpty;
    }
    return true;
  }

  void _onConfirm() {
    if (!_canConfirm) return;
    if (_selectedId == _kOtherId) {
      Navigator.of(context).pop(
        CancelReasonChoice(customText: _otherController.text.trim()),
      );
    } else {
      Navigator.of(context).pop(CancelReasonChoice(reasonId: _selectedId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DragHandle(),
              _Header(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 4),
              Flexible(child: _body(context)),
              _Footer(
                canConfirm: _canConfirm,
                showHint: _selectedId == null,
                onConfirm: _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_error.isNotEmpty && _reasons.isEmpty) {
      return _ErrorView(
        message: _error,
        onRetry: () {
          setState(() {
            _loading = true;
            _error = '';
          });
          _fetch();
        },
      );
    }

    final isOtherSelected = _selectedId == _kOtherId;

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      children: [
        ..._reasons.map(
          (reason) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ReasonTile(
              icon: Icons.flag_outlined,
              label: reason.localizedText(context),
              selected: _selectedId == reason.id,
              onTap: () {
                _otherFocus.unfocus();
                setState(() => _selectedId = reason.id);
              },
            ),
          ),
        ),
        _ReasonTile(
          icon: Icons.edit_outlined,
          label: 'Other'.tr(),
          selected: isOtherSelected,
          onTap: () {
            setState(() => _selectedId = _kOtherId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _otherFocus.requestFocus();
            });
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: isOtherSelected
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _OtherTextField(
                    controller: _otherController,
                    focusNode: _otherFocus,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: AppColor.grey2,
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cancel order'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tell us why'.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColor.grey,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: AppColor.lightBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close, size: 18, color: AppColor.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColor.kPrimaryColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: selected ? AppColor.kPrimary2Color : AppColor.lightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? accent : Colors.transparent,
          width: 1.4,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? accent : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: selected ? Colors.white : AppColor.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? AppColor.black : AppColor.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _CheckCircle(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckCircle extends StatelessWidget {
  const _CheckCircle({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final accent = AppColor.kPrimaryColor;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? accent : Colors.white,
        border: Border.all(
          color: selected ? accent : AppColor.lightGreyBlue,
          width: 1.6,
        ),
      ),
      child: selected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : const SizedBox.shrink(),
    );
  }
}

class _OtherTextField extends StatelessWidget {
  const _OtherTextField({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.lightBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: _kOtherMaxLength,
        maxLines: 4,
        minLines: 2,
        textInputAction: TextInputAction.done,
        inputFormatters: [LengthLimitingTextInputFormatter(_kOtherMaxLength)],
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Tell us why'.tr(),
          hintStyle: TextStyle(color: AppColor.grey, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          counterStyle: TextStyle(
            color: AppColor.grey,
            fontSize: 11,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canConfirm,
    required this.showHint,
    required this.onConfirm,
  });

  final bool canConfirm;
  final bool showHint;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColor.grey2, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: showHint
                ? Padding(
                    key: const ValueKey('hint'),
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'Please select a reason'.tr(),
                      style: TextStyle(color: AppColor.grey, fontSize: 12.5),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canConfirm ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.kPrimaryColor,
                disabledBackgroundColor: AppColor.lightBlue,
                foregroundColor: Colors.white,
                disabledForegroundColor: AppColor.grey,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                'Confirm'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColor.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: AppColor.red, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColor.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColor.kPrimaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              'common.retry'.tr(),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
