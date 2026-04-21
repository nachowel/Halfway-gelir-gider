import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_pill.dart';
import '../../../shared/overlay/app_overlay.dart';

enum RecurringPaymentMethod { cash, card, bankTransfer, other }

extension RecurringPaymentMethodX on RecurringPaymentMethod {
  String label(AppLocalizations strings) {
    switch (this) {
      case RecurringPaymentMethod.cash:
        return strings.cash;
      case RecurringPaymentMethod.card:
        return strings.card;
      case RecurringPaymentMethod.bankTransfer:
        return strings.paymentMethodLabel(PaymentMethodType.bankTransfer);
      case RecurringPaymentMethod.other:
        return strings.paymentMethodLabel(PaymentMethodType.other);
    }
  }
}

class RecurringPaymentDraft {
  const RecurringPaymentDraft({
    required this.id,
    required this.title,
    required this.frequencyLabel,
    required this.plannedAmountMinor,
    required this.currentDueDate,
    required this.nextDueDate,
    this.defaultMethod,
  });

  final String id;
  final String title;
  final String frequencyLabel;
  final int plannedAmountMinor;
  final DateTime currentDueDate;
  final DateTime nextDueDate;
  final RecurringPaymentMethod? defaultMethod;
}

class RecurringPaymentResult {
  const RecurringPaymentResult({
    required this.amountMinor,
    required this.paidOn,
    required this.method,
  });

  final int amountMinor;
  final DateTime paidOn;
  final RecurringPaymentMethod method;
}

Future<void> showMarkPaidSheet(
  BuildContext context, {
  required RecurringPaymentDraft draft,
  required Future<void> Function(RecurringPaymentResult result) onConfirm,
}) {
  return showAppModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x59112214),
    isScrollControlled: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 240),
      reverseDuration: Duration(milliseconds: 400),
    ),
    builder: (BuildContext sheetContext) {
      return _MarkPaidSheet(draft: draft, onConfirm: onConfirm);
    },
  );
}

class _MarkPaidSheet extends StatefulWidget {
  const _MarkPaidSheet({required this.draft, required this.onConfirm});

  final RecurringPaymentDraft draft;
  final Future<void> Function(RecurringPaymentResult result) onConfirm;

  @override
  State<_MarkPaidSheet> createState() => _MarkPaidSheetState();
}

enum _SubmitState { idle, saving, success, error }

class _MarkPaidSheetState extends State<_MarkPaidSheet> {
  late final TextEditingController _amountController;
  late DateTime _paidOn;
  RecurringPaymentMethod? _method;
  String? _amountError;
  _SubmitState _submitState = _SubmitState.idle;

  @override
  void initState() {
    super.initState();
    _paidOn = widget.draft.currentDueDate;
    _method = widget.draft.defaultMethod;
    _amountController = TextEditingController(
      text: _formatInputAmount(widget.draft.plannedAmountMinor),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatInputAmount(int amountMinor) {
    return (amountMinor / 100).toStringAsFixed(2);
  }

  String _formatCurrency(int amountMinor) {
    final String value = (amountMinor / 100).toStringAsFixed(2);
    final List<String> parts = value.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match _) => ',',
    );
    return '£$whole.${parts.last}';
  }

  int? _parseMinorAmount() {
    final String normalized = _amountController.text
        .replaceAll(',', '.')
        .trim();
    final double? parsed = double.tryParse(normalized);
    if (parsed == null) return null;
    return (parsed * 100).round();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showAppDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.brand,
              onPrimary: AppColors.onInk,
              surface: AppColors.surface,
              onSurface: AppColors.ink,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _paidOn = picked);
  }

  Future<void> _submit() async {
    final AppLocalizations strings = context.strings;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final int? amountMinor = _parseMinorAmount();
    final bool invalidAmount = amountMinor == null || amountMinor <= 0;
    final bool missingMethod = _method == null;

    setState(() {
      _amountError = invalidAmount ? strings.amountMustBeGreaterThanZero : null;
      if (_submitState == _SubmitState.error) {
        _submitState = _SubmitState.idle;
      }
    });

    if (invalidAmount || missingMethod) {
      if (missingMethod) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(strings.choosePaymentMethodToContinue),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _submitState = _SubmitState.saving);

    try {
      await widget.onConfirm(
        RecurringPaymentResult(
          amountMinor: amountMinor,
          paidOn: _paidOn,
          method: _method!,
        ),
      );

      if (!mounted) return;
      setState(() => _submitState = _SubmitState.success);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            strings.recordedPaymentMessage(_formatCurrency(amountMinor)),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitState = _SubmitState.error);
      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.paymentRecordFailed),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.expense,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _submitState = _SubmitState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final bool changedAmount =
        _amountController.text.trim() !=
        _formatInputAmount(widget.draft.plannedAmountMinor);
    final bool busy =
        _submitState == _SubmitState.saving ||
        _submitState == _SubmitState.success;

    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.confirmPayment.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 4),
          Text(
            strings.markAsPaidQuestion(widget.draft.title),
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.draft.title,
                  style: AppTypography.body.copyWith(fontSize: 15),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              HiFiPill(
                label: widget.draft.frequencyLabel,
                tone: HiFiPillTone.brandSoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          HiFiCard.compact(
            child: Column(
              children: <Widget>[
                _SheetSummaryRow(
                  label: strings.dueOn,
                  trailing: Text(
                    strings.dayMonthShortWeekday(widget.draft.currentDueDate),
                    style: AppTypography.numSm,
                  ),
                ),
                const Divider(color: AppColors.borderSoft, height: 14),
                _SheetSummaryRow(
                  label: strings.nextDue,
                  trailing: Text(
                    strings.dayMonthShortWeekday(widget.draft.nextDueDate),
                    style: AppTypography.numSm.copyWith(color: AppColors.brand),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _DateField(
            label: strings.paidOn,
            value: strings.dayMonthShortWeekday(_paidOn),
            onTap: busy ? null : _pickDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          HiFiInputField(
            controller: _amountController,
            label: strings.amount,
            prefix: Text('£', style: AppTypography.input),
            helper: changedAmount
                ? null
                : strings.plannedAmountHelper(
                    _formatCurrency(widget.draft.plannedAmountMinor),
                  ),
            errorText: _amountError,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.,]')),
            ],
            onChanged: (_) {
              if (_amountError != null) {
                setState(() => _amountError = null);
              } else {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(strings.paymentMethod, style: AppTypography.lbl),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: RecurringPaymentMethod.values.map((
                RecurringPaymentMethod method,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: HiFiFilterChip(
                    label: method.label(strings),
                    selected: method == _method,
                    tone: HiFiFilterChipTone.brand,
                    onTap: busy
                        ? () {}
                        : () => setState(() => _method = method),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            strings.paymentContinueMessage(
              strings.dayMonthShortWeekday(widget.draft.nextDueDate),
            ),
            style: AppTypography.bodySoft.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: HiFiButton(
                  label: strings.later,
                  variant: HiFiButtonVariant.ghost,
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 16,
                child: HiFiButton(
                  label: switch (_submitState) {
                    _SubmitState.saving => strings.saving,
                    _SubmitState.success => strings.saved,
                    _SubmitState.error => strings.retrySave,
                    _SubmitState.idle => strings.markPaid,
                  },
                  variant: HiFiButtonVariant.income,
                  leading: const Icon(Icons.check_rounded),
                  onPressed: busy ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetSummaryRow extends StatelessWidget {
  const _SheetSummaryRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: AppTypography.lbl),
        trailing,
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x99FFFFFF),
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: AppTypography.lbl),
                    const SizedBox(height: 4),
                    Text(value, style: AppTypography.input),
                  ],
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
