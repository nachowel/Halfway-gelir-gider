import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/domain/types.dart' show DomainValidationException;
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/overlay/app_overlay.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_date_field.dart';

Future<void> showRecurringFormSheet(
  BuildContext context, {
  RecurringExpenseData? existing,
}) async {
  await showAppModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RecurringFormSheet(existing: existing),
  );
}

class _RecurringFormSheet extends ConsumerStatefulWidget {
  const _RecurringFormSheet({this.existing});

  final RecurringExpenseData? existing;

  @override
  ConsumerState<_RecurringFormSheet> createState() =>
      _RecurringFormSheetState();
}

class _RecurringFormSheetState extends ConsumerState<_RecurringFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  late RecurringFrequencyType _frequency;
  late DateTime _nextDueOn;
  late bool _includeInReservePlanner;
  String? _selectedCategoryId;
  PaymentMethodType? _selectedPaymentMethod;

  bool _saving = false;
  bool _deactivating = false;

  String? _nameError;
  String? _amountError;
  String? _categoryError;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _amountController = TextEditingController(
      text: e == null ? '' : (e.amountMinor / 100).toStringAsFixed(2),
    );
    _frequency = e?.frequency ?? RecurringFrequencyType.monthly;
    _nextDueOn = e?.nextDueOn ?? DateTime.now();
    _includeInReservePlanner = e?.reserveEnabled ?? false;
    _selectedCategoryId = e?.categoryId;
    _selectedPaymentMethod = e?.defaultPaymentMethod;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double? _parseAmount() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: _nextDueOn,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(today.year + 5, 12, 31),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
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
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() => _nextDueOn = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final AppLocalizations strings = context.strings;
    final amount = _parseAmount();
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? strings.enterName
          : null;
      _amountError = amount == null || amount <= 0
          ? strings.enterAmountGreaterThanZero
          : null;
      _categoryError = _selectedCategoryId == null
          ? strings.chooseCategory
          : null;
    });
    if (_nameError != null || _amountError != null || _categoryError != null) {
      return;
    }

    final draft = RecurringDraft(
      name: _nameController.text.trim(),
      categoryId: _selectedCategoryId!,
      amountMinor: (amount! * 100).round(),
      frequency: _frequency,
      nextDueOn: _nextDueOn,
      reserveEnabled: _includeInReservePlanner,
      defaultPaymentMethod: _selectedPaymentMethod,
    );

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await ref
            .read(giderRepositoryProvider)
            .updateRecurringExpense(id: widget.existing!.id, draft: draft);
      } else {
        await ref.read(giderRepositoryProvider).createRecurringExpense(draft);
      }
      ref.invalidate(recurringItemsProvider);
      ref.invalidate(recurringSummaryProvider);
      ref.invalidate(dashboardSnapshotProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DomainValidationException catch (e) {
      _showError(e.message);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(context.strings.couldNotSaveTryAgain);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    if (_deactivating || _saving) return;
    setState(() => _deactivating = true);
    try {
      await ref
          .read(giderRepositoryProvider)
          .deactivateRecurringExpense(id: widget.existing!.id);
      ref.invalidate(recurringItemsProvider);
      ref.invalidate(recurringSummaryProvider);
      ref.invalidate(dashboardSnapshotProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DomainValidationException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError(context.strings.couldNotRemoveTryAgain);
    } finally {
      if (mounted) setState(() => _deactivating = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.expense,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final mq = MediaQuery.of(context);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final categories = categoriesAsync.asData?.value ?? const <CategoryData>[];
    final double keyboardInset = mq.viewInsets.bottom;
    final double rawSheetHeight = (mq.size.height * 0.92) - keyboardInset;
    final double sheetHeight = rawSheetHeight.isFinite
        ? rawSheetHeight.clamp(220.0, 560.0)
        : 420.0;

    return HiFiBottomSheet(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _isEditing
                        ? strings.editRecurring
                        : strings.newRecurringExpense,
                    style: AppTypography.h2.copyWith(fontSize: 18),
                  ),
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: _deactivating ? null : _deactivate,
                    child: Text(
                      strings.remove,
                      style: AppTypography.body.copyWith(
                        color: AppColors.expense,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Name
                    HiFiInputField(
                      controller: _nameController,
                      label: strings.name,
                      hint: strings.recurringNameHint,
                      errorText: _nameError,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_nameError != null) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Amount
                    HiFiInputField(
                      controller: _amountController,
                      label: strings.amount,
                      hint: '0.00',
                      prefix: Text('£', style: AppTypography.body),
                      errorText: _amountError,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                      ],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        if (_amountError != null) {
                          setState(() => _amountError = null);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Frequency
                    Text(strings.frequency, style: AppTypography.lbl),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: RecurringFrequencyType.values
                          .map(
                            (f) => HiFiFilterChip(
                              label: context.strings.recurringFrequencyLabel(f),
                              selected: _frequency == f,
                              onTap: () => setState(() => _frequency = f),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Next due date
                    AppDateField(
                      label: strings.nextDueLabel,
                      value: strings.dayMonthYear(_nextDueOn),
                      showTodayPill: false,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Category
                    if (categoriesAsync.isLoading)
                      Text(strings.loadingCategories, style: AppTypography.meta)
                    else ...<Widget>[
                      Text(strings.category, style: AppTypography.lbl),
                      if (_categoryError != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          _categoryError!,
                          style: AppTypography.meta.copyWith(
                            color: AppColors.expense,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: categories
                            .map(
                              (c) => HiFiFilterChip(
                                label: c.name,
                                selected: _selectedCategoryId == c.id,
                                onTap: () => setState(() {
                                  _selectedCategoryId = c.id;
                                  _categoryError = null;
                                }),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),

                    // Payment method (optional)
                    Text(strings.paymentMethod, style: AppTypography.lbl),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: PaymentMethodType.values
                          .map(
                            (PaymentMethodType method) => HiFiFilterChip(
                              label: strings.paymentMethodLabel(method),
                              selected: _selectedPaymentMethod == method,
                              onTap: () => setState(() {
                                _selectedPaymentMethod =
                                    _selectedPaymentMethod == method
                                    ? null
                                    : method;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface2,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              final Widget content = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    strings.includeInReservePlanner,
                                    style: AppTypography.lbl,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    strings.reservePlannerHelper,
                                    style: AppTypography.meta.copyWith(
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              );
                              final Widget toggle = Switch.adaptive(
                                value: _includeInReservePlanner,
                                activeColor: AppColors.brand,
                                onChanged: (bool value) {
                                  setState(
                                    () => _includeInReservePlanner = value,
                                  );
                                },
                              );

                              if (constraints.maxWidth < 340) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    content,
                                    const SizedBox(height: AppSpacing.xs),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: toggle,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: <Widget>[
                                  Expanded(child: content),
                                  const SizedBox(width: AppSpacing.sm),
                                  toggle,
                                ],
                              );
                            },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _isEditing ? strings.saveChanges : strings.addRecurring,
              onPressed: _saving ? null : _save,
              variant: AppButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }
}
