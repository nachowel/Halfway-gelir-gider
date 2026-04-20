import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_attachment_tile.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/layout/mobile_scaffold.dart';
import '../../../shared/widgets/app_amount_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_date_field.dart';
import '../../../shared/widgets/app_form_section_card.dart';
import '../../categories/presentation/category_catalog.dart';

enum EntryKind { expense, income }

class EntryScreen extends StatefulWidget {
  const EntryScreen({required this.kind, super.key});

  final EntryKind kind;

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _noteController;

  late DateTime _occurredOn;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  String? _selectedSourcePlatform;
  String? _attachmentLabel;
  bool _didAttemptSubmit = false;

  String? _amountError;
  String? _categoryError;
  String? _paymentError;

  final List<String> _paymentMethods = const <String>[
    'Cash',
    'Card',
    'Bank transfer',
    'Other',
  ];

  final List<String> _sourcePlatforms = const <String>[
    'Direct',
    'Uber',
    'Just Eat',
    'Other',
  ];

  bool get _isExpense => widget.kind == EntryKind.expense;

  List<CategoryPresentationData> get _categories =>
      _isExpense ? expenseCategoryCatalog : incomeCategoryCatalog;

  String get _screenTitle => _isExpense ? 'Gider ekle' : 'Gelir ekle';

  String get _pillLabel => _isExpense ? 'Gider' : 'Gelir';

  String get _saveLabel => _isExpense ? 'Gideri kaydet' : 'Geliri kaydet';

  String get _dateSubtitle => '${_formatHeaderDate(_occurredOn)} · yeni kayit';

  bool get _isToday {
    final DateTime now = DateTime.now();
    return _occurredOn.year == now.year &&
        _occurredOn.month == now.month &&
        _occurredOn.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _vendorController = TextEditingController();
    _noteController = TextEditingController();
    _occurredOn = DateTime.now();
    _selectedPaymentMethod = 'Card';
    _selectedSourcePlatform = _isExpense ? null : 'Direct';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatHeaderDate(DateTime date) {
    return DateFormat('EEE d MMM').format(date);
  }

  double? _parseAmount() {
    final String raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _occurredOn,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(today.year + 1, 12, 31),
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
    if (picked == null) {
      return;
    }
    setState(() => _occurredOn = picked);
  }

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.sheetTop),
                  bottom: Radius.circular(AppRadius.sheetBottom),
                ),
                boxShadow: AppShadows.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x2E15282B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('CATEGORY', style: AppTypography.eye),
                    ),
                  ),
                  for (final CategoryPresentationData category in _categories)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () =>
                            Navigator.of(sheetContext).pop(category.title),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                          child: Row(
                            children: <Widget>[
                              HiFiIconTile(
                                icon: category.icon,
                                tone: category.tone,
                                size: HiFiIconTileSize.small,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  category.title,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              if (_selectedCategory == category.title)
                                const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.income,
                                )
                              else
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.inkFade,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }
    setState(() {
      _selectedCategory = selected;
      _categoryError = null;
    });
  }

  void _toggleAttachment() {
    setState(() {
      _attachmentLabel = _attachmentLabel == null
          ? (_isExpense ? 'receipt-apr20.jpg' : 'payout-apr20.pdf')
          : null;
    });
  }

  void _showRecurringHandoff() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Recurring handoff stays visual in this batch. Persistence comes later.',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final double? amount = _parseAmount();
    setState(() {
      _didAttemptSubmit = true;
      _amountError = amount == null || amount <= 0
          ? 'Enter an amount greater than £0.00.'
          : null;
      _categoryError = _selectedCategory == null ? 'Choose a category.' : null;
      _paymentError = _selectedPaymentMethod == null
          ? 'Choose a payment method.'
          : null;
    });

    if (_amountError != null ||
        _categoryError != null ||
        _paymentError != null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isExpense ? AppColors.brand : AppColors.income,
        content: Text(
          '${_isExpense ? 'Expense' : 'Income'} saved for £${amount!.toStringAsFixed(2)}',
        ),
      ),
    );
    context.pop();
  }

  void _handleAmountChanged(String _) {
    if (!_didAttemptSubmit) {
      return;
    }
    final double? amount = _parseAmount();
    setState(() {
      _amountError = amount == null || amount <= 0
          ? 'Enter an amount greater than £0.00.'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final double bottomInset = mq.viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: HiFiScreenBackground(
        tone: _isExpense ? HiFiScreenTone.cream : HiFiScreenTone.tealMint,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: MobileScaffold(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screenSide,
                        AppSpacing.xs,
                        AppSpacing.screenSide,
                        178 + mq.padding.bottom + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _EntryHeader(
                            title: _screenTitle,
                            subtitle: _dateSubtitle,
                            pillLabel: _pillLabel,
                            isExpense: _isExpense,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppAmountField(
                            controller: _amountController,
                            tone: _isExpense
                                ? AppAmountFieldTone.expense
                                : AppAmountFieldTone.income,
                            autofocus: true,
                            errorText: _amountError,
                            onChanged: _handleAmountChanged,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_isExpense)
                            _ExpenseFields(
                              categories: _categories,
                              selectedCategory: _selectedCategory,
                              selectedPaymentMethod: _selectedPaymentMethod,
                              paymentMethods: _paymentMethods,
                              categoryError: _categoryError,
                              paymentError: _paymentError,
                              vendorController: _vendorController,
                              noteController: _noteController,
                              occurredOnLabel: _formatHeaderDate(_occurredOn),
                              showTodayPill: _isToday,
                              attachmentLabel: _attachmentLabel,
                              onCategorySelected: (String value) {
                                setState(() {
                                  _selectedCategory = value;
                                  _categoryError = null;
                                });
                              },
                              onPaymentSelected: (String value) {
                                setState(() {
                                  _selectedPaymentMethod = value;
                                  _paymentError = null;
                                });
                              },
                              onDateTap: _pickDate,
                              onAttachmentTap: _toggleAttachment,
                            )
                          else
                            _IncomeFields(
                              selectedSourcePlatform: _selectedSourcePlatform,
                              sourcePlatforms: _sourcePlatforms,
                              selectedPaymentMethod: _selectedPaymentMethod,
                              paymentMethods: _paymentMethods,
                              selectedCategory: _selectedCategory,
                              categoryError: _categoryError,
                              paymentError: _paymentError,
                              noteController: _noteController,
                              occurredOnLabel: _formatHeaderDate(_occurredOn),
                              showTodayPill: _isToday,
                              attachmentLabel: _attachmentLabel,
                              onSourcePlatformSelected: (String value) {
                                setState(() => _selectedSourcePlatform = value);
                              },
                              onPaymentSelected: (String value) {
                                setState(() {
                                  _selectedPaymentMethod = value;
                                  _paymentError = null;
                                });
                              },
                              onCategoryTap: _pickCategory,
                              onDateTap: _pickDate,
                              onAttachmentTap: _toggleAttachment,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      height: 148,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            AppColors.surface.withValues(alpha: 0),
                            AppColors.surface.withValues(alpha: 0.7),
                            AppColors.surface.withValues(alpha: 0.98),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedPadding(
                    duration: AppDurations.fast,
                    curve: AppEasing.standard,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.screenSide,
                      12,
                      AppSpacing.screenSide,
                      mathMax(bottomInset, mq.padding.bottom) + 14,
                    ),
                    child: MobileScaffold(
                      child: _StickySaveBar(
                        saveLabel: _saveLabel,
                        saveVariant: _isExpense
                            ? AppButtonVariant.primary
                            : AppButtonVariant.income,
                        onSave: _submit,
                        secondaryLabel: _isExpense ? 'Recurring' : null,
                        onSecondaryTap: _isExpense
                            ? _showRecurringHandoff
                            : null,
                      ),
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

double mathMax(double a, double b) => a > b ? a : b;

class _EntryHeader extends StatelessWidget {
  const _EntryHeader({
    required this.title,
    required this.subtitle,
    required this.pillLabel,
    required this.isExpense,
  });

  final String title;
  final String subtitle;
  final String pillLabel;
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => context.pop(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Geri',
                      style: AppTypography.bodySoft.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: isExpense ? AppColors.expense : AppColors.income,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isExpense ? AppColors.expense : AppColors.income,
                ),
              ),
              child: Text(
                pillLabel,
                style: AppTypography.meta.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onInk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smTight),
        RichText(
          text: TextSpan(
            style: AppTypography.h1,
            children: <InlineSpan>[
              TextSpan(text: isExpense ? 'Gider ' : 'Gelir '),
              TextSpan(
                text: isExpense ? 'ekle' : 'ekle',
                style: AppTypography.h1.copyWith(
                  color: AppColors.brand,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: AppTypography.lbl),
      ],
    );
  }
}

class _ExpenseFields extends StatelessWidget {
  const _ExpenseFields({
    required this.categories,
    required this.selectedCategory,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    required this.categoryError,
    required this.paymentError,
    required this.vendorController,
    required this.noteController,
    required this.occurredOnLabel,
    required this.showTodayPill,
    required this.attachmentLabel,
    required this.onCategorySelected,
    required this.onPaymentSelected,
    required this.onDateTap,
    required this.onAttachmentTap,
  });

  final List<CategoryPresentationData> categories;
  final String? selectedCategory;
  final String? selectedPaymentMethod;
  final List<String> paymentMethods;
  final String? categoryError;
  final String? paymentError;
  final TextEditingController vendorController;
  final TextEditingController noteController;
  final String occurredOnLabel;
  final bool showTodayPill;
  final String? attachmentLabel;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<String> onPaymentSelected;
  final VoidCallback onDateTap;
  final VoidCallback onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ChipSection(
          label: 'Category',
          errorText: categoryError,
          values: categories.map((CategoryPresentationData item) => item.title).toList(),
          selectedValue: selectedCategory,
          onSelected: onCategorySelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChipSection(
          label: 'Payment method',
          errorText: paymentError,
          values: paymentMethods,
          selectedValue: selectedPaymentMethod,
          onSelected: onPaymentSelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: 'Vendor',
          helper: 'Optional · supplier or quick receipt context',
          child: _CardTextField(
            controller: vendorController,
            hint: 'Shell - Mile End',
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDateField(
          label: 'Occurred on',
          value: occurredOnLabel,
          showTodayPill: showTodayPill,
          onTap: onDateTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: 'Note',
          helper: 'Optional · add the detail you need later',
          child: _CardTextField(
            controller: noteController,
            hint: 'Fuel top-up before evening run',
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiAttachmentTile(
          label: 'Attachment',
          hint: 'Add receipt photo',
          attachmentLabel: attachmentLabel,
          tone: HiFiAttachmentTone.expense,
          onTap: onAttachmentTap,
        ),
      ],
    );
  }
}

class _IncomeFields extends StatelessWidget {
  const _IncomeFields({
    required this.selectedSourcePlatform,
    required this.sourcePlatforms,
    required this.selectedPaymentMethod,
    required this.paymentMethods,
    required this.selectedCategory,
    required this.categoryError,
    required this.paymentError,
    required this.noteController,
    required this.occurredOnLabel,
    required this.showTodayPill,
    required this.attachmentLabel,
    required this.onSourcePlatformSelected,
    required this.onPaymentSelected,
    required this.onCategoryTap,
    required this.onDateTap,
    required this.onAttachmentTap,
  });

  final String? selectedSourcePlatform;
  final List<String> sourcePlatforms;
  final String? selectedPaymentMethod;
  final List<String> paymentMethods;
  final String? selectedCategory;
  final String? categoryError;
  final String? paymentError;
  final TextEditingController noteController;
  final String occurredOnLabel;
  final bool showTodayPill;
  final String? attachmentLabel;
  final ValueChanged<String> onSourcePlatformSelected;
  final ValueChanged<String> onPaymentSelected;
  final VoidCallback onCategoryTap;
  final VoidCallback onDateTap;
  final VoidCallback onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _ChipSection(
          label: 'Source platform',
          helper: 'Optional · direct sale or delivery settlement',
          values: sourcePlatforms,
          selectedValue: selectedSourcePlatform,
          chipTone: HiFiFilterChipTone.brand,
          onSelected: onSourcePlatformSelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChipSection(
          label: 'Payment method',
          errorText: paymentError,
          values: paymentMethods,
          selectedValue: selectedPaymentMethod,
          chipTone: HiFiFilterChipTone.brand,
          onSelected: onPaymentSelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard.compact(
          variant: AppCardVariant.mint,
          onTap: onCategoryTap,
          border: Border.all(color: AppColors.cardMintBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Category', style: AppTypography.lbl),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      selectedCategory ?? 'Choose category',
                      style: (selectedCategory == null
                              ? AppTypography.bodySoft
                              : AppTypography.body)
                          .copyWith(fontSize: 14.5),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.inkFade,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (categoryError != null) ...<Widget>[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              categoryError!,
              style: AppTypography.meta.copyWith(color: AppColors.expense),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppDateField(
          label: 'Occurred on',
          value: occurredOnLabel,
          showTodayPill: showTodayPill,
          onTap: onDateTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: 'Note',
          helper: 'Optional · context for the settlement or sale',
          child: _CardTextField(
            controller: noteController,
            hint: 'Lunch rush payout',
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiAttachmentTile(
          label: 'Attachment',
          hint: 'Add payout slip',
          attachmentLabel: attachmentLabel,
          tone: HiFiAttachmentTone.income,
          onTap: onAttachmentTap,
        ),
      ],
    );
  }
}

class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.onSelected,
    this.errorText,
    this.helper,
    this.chipTone = HiFiFilterChipTone.ink,
  });

  final String label;
  final List<String> values;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final String? errorText;
  final String? helper;
  final HiFiFilterChipTone chipTone;

  @override
  Widget build(BuildContext context) {
    return AppFormSectionCard(
      label: label,
      helper: helper,
      errorText: errorText,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: values
            .map(
              (String value) => HiFiFilterChip(
                label: value,
                selected: selectedValue == value,
                tone: chipTone,
                onTap: () => onSelected(value),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CardTextField extends StatelessWidget {
  const _CardTextField({
    required this.controller,
    required this.hint,
    required this.textInputAction,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      textInputAction: textInputAction,
      cursorColor: AppColors.brand,
      style: AppTypography.body.copyWith(fontSize: 14.5),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: AppTypography.bodySoft.copyWith(
          color: AppColors.inkFade,
          fontSize: 13.5,
        ),
      ),
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({
    required this.saveLabel,
    required this.saveVariant,
    required this.onSave,
    this.secondaryLabel,
    this.onSecondaryTap,
  });

  final String saveLabel;
  final AppButtonVariant saveVariant;
  final VoidCallback onSave;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppShadows.md,
          ),
          child: Row(
            children: <Widget>[
              if (secondaryLabel != null && onSecondaryTap != null) ...<Widget>[
                AppButton(
                  label: secondaryLabel!,
                  onPressed: onSecondaryTap,
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.compact,
                  expanded: false,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: AppButton(
                  label: saveLabel,
                  onPressed: onSave,
                  variant: saveVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
