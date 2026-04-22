import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/domain/types.dart' show DomainValidationException;
import '../../../data/app_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_attachment_tile.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_screen_background.dart';
import '../../../shared/layout/mobile_scaffold.dart';
import '../../../shared/overlay/app_overlay.dart';
import '../../../shared/widgets/app_amount_field.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_date_field.dart';
import '../../../shared/widgets/app_form_section_card.dart';

enum EntryKind { expense, income }

enum _IncomeTypeOption {
  cashSale,
  cardSale,
  uberSettlement,
  justEatSettlement,
  other,
}

extension _IncomeTypeOptionX on _IncomeTypeOption {
  String label(AppLocalizations strings) => switch (this) {
    _IncomeTypeOption.cashSale => strings.cashSaleType,
    _IncomeTypeOption.cardSale => strings.cardSaleType,
    _IncomeTypeOption.uberSettlement => strings.uberSettlementType,
    _IncomeTypeOption.justEatSettlement => strings.justEatSettlementType,
    _IncomeTypeOption.other => strings.otherIncomeType,
  };
}

class EntryScreen extends ConsumerStatefulWidget {
  const EntryScreen({required this.kind, this.transactionId, super.key});

  final EntryKind kind;
  final String? transactionId;

  @override
  ConsumerState<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends ConsumerState<EntryScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _vendorController;
  late final TextEditingController _noteController;
  late final ScrollController _scrollController;

  late DateTime _occurredOn;
  String? _selectedCategoryId;
  String? _selectedSupplierId;
  String? _selectedSupplierName;
  PaymentMethodType? _selectedPaymentMethod;
  SourcePlatformType? _selectedSourcePlatform;
  String? _attachmentLabel;
  bool _didAttemptSubmit = false;
  bool _saving = false;
  bool _saveSucceeded = false;
  bool _deleting = false;
  bool _preloading = false;
  bool _preloadFailed = false;

  String? _amountError;
  String? _categoryError;
  String? _paymentError;

  bool get _isExpense => widget.kind == EntryKind.expense;

  bool get _isEditing => widget.transactionId != null;

  bool get _isSettlementSelected =>
      _selectedSourcePlatform != null &&
      _selectedSourcePlatform != SourcePlatformType.direct &&
      _selectedSourcePlatform != SourcePlatformType.other;

  AsyncValue<List<CategoryData>> get _categoriesAsync => _isExpense
      ? ref.watch(expenseCategoriesProvider)
      : ref.watch(incomeCategoriesProvider);

  String get _screenTitle {
    final AppLocalizations strings = context.strings;
    if (_isEditing) {
      return _isExpense ? strings.editExpenseTitle : strings.editIncomeTitle;
    }
    return _isExpense ? strings.addExpenseTitle : strings.addIncomeTitle;
  }

  String get _pillLabel =>
      _isExpense ? context.strings.expense : context.strings.income;

  String get _saveLabel {
    final AppLocalizations strings = context.strings;
    if (_saveSucceeded) {
      return strings.saved;
    }
    if (_isEditing) {
      return strings.saveChanges;
    }
    return _isExpense ? strings.saveExpense : strings.saveIncome;
  }

  String get _dateSubtitle {
    final AppLocalizations strings = context.strings;
    final String dateLabel = _formatHeaderDate(_occurredOn);
    return _isEditing
        ? strings.editingHeaderSubtitle(dateLabel)
        : strings.newEntryHeaderSubtitle(dateLabel);
  }

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
    _scrollController = ScrollController(keepScrollOffset: false);
    _occurredOn = DateTime.now();
    _selectedPaymentMethod = _isExpense ? PaymentMethodType.card : null;
    _selectedSourcePlatform = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(0);
    });
    if (widget.transactionId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditData());
    }
  }

  Future<void> _loadEditData() async {
    if (!mounted) return;
    setState(() => _preloading = true);
    try {
      final TransactionData? t = await ref
          .read(giderRepositoryProvider)
          .fetchTransaction(id: widget.transactionId!);
      if (!mounted || t == null) return;
      setState(() {
        _amountController.text = (t.amountMinor / 100).toStringAsFixed(2);
        _occurredOn = t.occurredOn;
        _selectedCategoryId = t.categoryId;
        _selectedSupplierId = _isExpense ? t.supplierId : null;
        _selectedSupplierName = _isExpense ? t.supplierName : null;
        _selectedPaymentMethod = t.paymentMethod;
        _selectedSourcePlatform =
            t.sourcePlatform ?? (_isExpense ? null : SourcePlatformType.direct);
        _vendorController.text = t.vendor ?? '';
        _noteController.text = t.note ?? '';
      });
    } catch (_) {
      if (mounted) setState(() => _preloadFailed = true);
    } finally {
      if (mounted) setState(() => _preloading = false);
    }
  }

  Future<bool> _confirmDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations strings = dialogContext.strings;
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.borderSoft),
          ),
          title: Text(strings.deleteEntryConfirmTitle, style: AppTypography.h2),
          content: Text(
            strings.deleteEntryConfirmMessage,
            style: AppTypography.bodySoft,
          ),
          actions: <Widget>[
            TextButton(
              key: const ValueKey<String>('entry-delete-cancel-button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancel, style: AppTypography.button),
            ),
            TextButton(
              key: const ValueKey<String>('entry-delete-confirm-button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                strings.delete,
                style: AppTypography.button.copyWith(color: AppColors.expense),
              ),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _delete() async {
    if (_deleting || _saving || widget.transactionId == null) return;
    FocusScope.of(context).unfocus();
    final bool confirmed = await _confirmDelete();
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deleting = true);
    try {
      await ref
          .read(giderRepositoryProvider)
          .deleteTransaction(id: widget.transactionId!);
      _refreshAfterTransactionMutation();
      await _finishSuccessfulDelete();
    } on DomainValidationException catch (error) {
      _showErrorSnack(error.message);
    } catch (error) {
      _showErrorSnack(context.strings.couldNotDeleteEntry(error.toString()));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _vendorController.dispose();
    _noteController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatHeaderDate(DateTime date) {
    return context.strings.weekdayShortDate(date);
  }

  double? _parseAmount() {
    final String raw = _amountController.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final DateTime today = DateTime.now();
    final DateTime? picked = await showAppDatePicker(
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

  Future<void> _pickCategory(List<CategoryData> categories) async {
    FocusScope.of(context).unfocus();
    if (categories.isEmpty) {
      return;
    }
    final CategoryData? selected = await showAppModalBottomSheet<CategoryData>(
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
                      child: Text(
                        sheetContext.strings.chooseCategorySheetTitle,
                        style: AppTypography.eye,
                      ),
                    ),
                  ),
                  for (final CategoryData category in categories)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.of(sheetContext).pop(category),
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
                                  category.name,
                                  style: AppTypography.body.copyWith(
                                    fontSize: 14.5,
                                  ),
                                ),
                              ),
                              if (_selectedCategoryId == category.id)
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
      _selectedCategoryId = selected.id;
      _selectedSupplierId = null;
      _selectedSupplierName = null;
      _categoryError = null;
    });
  }

  Future<void> _pickSupplier({
    required String categoryName,
    required List<SupplierData> suppliers,
    required bool loading,
    required String? errorMessage,
  }) async {
    FocusScope.of(context).unfocus();
    if (_selectedCategoryId == null) {
      return;
    }

    SupplierData? selectedActiveSupplier;
    if (_selectedSupplierId != null) {
      for (final SupplierData supplier in suppliers) {
        if (supplier.id == _selectedSupplierId) {
          selectedActiveSupplier = supplier;
          break;
        }
      }
    }
    final bool selectedSupplierIsArchived =
        _selectedSupplierId != null &&
        _selectedSupplierName != null &&
        selectedActiveSupplier == null &&
        !loading &&
        errorMessage == null;

    final _SupplierPickerResult? result =
        await showAppModalBottomSheet<_SupplierPickerResult>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (BuildContext sheetContext) {
            return _SupplierPickerSheet(
              categoryName: categoryName,
              suppliers: suppliers,
              loading: loading,
              errorMessage: errorMessage,
              selectedSupplierId: _selectedSupplierId,
              archivedLinkedSupplierName: selectedSupplierIsArchived
                  ? _selectedSupplierName
                  : null,
            );
          },
        );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.cleared) {
        _selectedSupplierId = null;
        _selectedSupplierName = null;
        return;
      }
      _selectedSupplierId = result.supplier!.id;
      _selectedSupplierName = result.supplier!.name;
    });
  }

  _IncomeTypeOption? _incomeTypeForCategoryName(String? categoryName) {
    final String normalized = categoryName?.trim().toLowerCase() ?? '';
    return switch (normalized) {
      'cash sales' => _IncomeTypeOption.cashSale,
      'card sales' => _IncomeTypeOption.cardSale,
      'uber settlement' => _IncomeTypeOption.uberSettlement,
      'just eat settlement' => _IncomeTypeOption.justEatSettlement,
      'other income' => _IncomeTypeOption.other,
      _ => null,
    };
  }

  String _incomeTypeCategoryName(_IncomeTypeOption option) => switch (option) {
    _IncomeTypeOption.cashSale => 'Cash Sales',
    _IncomeTypeOption.cardSale => 'Card Sales',
    _IncomeTypeOption.uberSettlement => 'Uber Settlement',
    _IncomeTypeOption.justEatSettlement => 'Just Eat Settlement',
    _IncomeTypeOption.other => 'Other Income',
  };

  CategoryData? _findIncomeCategory(
    List<CategoryData> categories,
    _IncomeTypeOption option,
  ) {
    final String desiredName = _incomeTypeCategoryName(option).toLowerCase();
    for (final CategoryData category in categories) {
      if (category.name.trim().toLowerCase() == desiredName) {
        return category;
      }
    }
    return null;
  }

  Future<void> _pickIncomeType(List<CategoryData> categories) async {
    FocusScope.of(context).unfocus();
    String? currentCategoryName;
    if (_selectedCategoryId != null) {
      for (final CategoryData category in categories) {
        if (category.id == _selectedCategoryId) {
          currentCategoryName = category.name;
          break;
        }
      }
    }
    final _IncomeTypeOption? currentType = _incomeTypeForCategoryName(
      currentCategoryName,
    );
    final _IncomeTypeOption?
    selected = await showAppModalBottomSheet<_IncomeTypeOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations strings = sheetContext.strings;
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
                      child: Text(
                        strings.incomeTypeSheetTitle,
                        style: AppTypography.eye,
                      ),
                    ),
                  ),
                  for (final _IncomeTypeOption option
                      in _IncomeTypeOption.values)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _findIncomeCategory(categories, option) == null
                            ? null
                            : () => Navigator.of(sheetContext).pop(option),
                        child: Opacity(
                          opacity:
                              _findIncomeCategory(categories, option) == null
                              ? 0.42
                              : 1,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    option.label(strings),
                                    style: AppTypography.body.copyWith(
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                if (currentType == option)
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

    final CategoryData? category = _findIncomeCategory(categories, selected);
    setState(() {
      _selectedCategoryId = category?.id;
      _categoryError = null;
      _paymentError = null;
      _selectedPaymentMethod = switch (selected) {
        _IncomeTypeOption.cashSale => PaymentMethodType.cash,
        _IncomeTypeOption.cardSale => PaymentMethodType.card,
        _IncomeTypeOption.uberSettlement ||
        _IncomeTypeOption.justEatSettlement => PaymentMethodType.bankTransfer,
        _IncomeTypeOption.other =>
          _selectedPaymentMethod ?? PaymentMethodType.other,
      };
      _selectedSourcePlatform = switch (selected) {
        _IncomeTypeOption.cashSale ||
        _IncomeTypeOption.cardSale => SourcePlatformType.direct,
        _IncomeTypeOption.uberSettlement => SourcePlatformType.uber,
        _IncomeTypeOption.justEatSettlement => SourcePlatformType.justEat,
        _IncomeTypeOption.other => SourcePlatformType.other,
      };
      if (selected == _IncomeTypeOption.uberSettlement ||
          selected == _IncomeTypeOption.justEatSettlement) {
        _occurredOn = _sundayOf(_occurredOn);
      }
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
      SnackBar(content: Text(context.strings.recurringHandoffVisualOnly)),
    );
  }

  void _refreshAfterTransactionMutation() {
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(reportsSnapshotProvider);
    ref.invalidate(recurringItemsProvider);
    ref.invalidate(recurringSummaryProvider);
    ref.invalidate(incomeCategoriesProvider);
    ref.invalidate(expenseCategoriesProvider);
    for (final TransactionsFilter filter in TransactionsFilter.values) {
      ref.invalidate(transactionsProvider(filter));
    }
    ref.read(refreshKeyProvider.notifier).state++;
  }

  Future<void> _finishSuccessfulSubmit() async {
    if (!mounted) {
      return;
    }
    final AppLocalizations strings = context.strings;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter? router = GoRouter.maybeOf(context);

    setState(() {
      _saving = false;
      _saveSucceeded = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final bool didPop = mounted
        ? await Navigator.of(context).maybePop()
        : false;
    if (!didPop) {
      router?.go('/summary');
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income,
          duration: const Duration(milliseconds: 1200),
          content: Text(strings.saved),
        ),
      );
  }

  Future<void> _finishSuccessfulDelete() async {
    if (!mounted) {
      return;
    }
    final AppLocalizations strings = context.strings;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final GoRouter? router = GoRouter.maybeOf(context);

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final bool didPop = mounted
        ? await Navigator.of(context).maybePop()
        : false;
    if (!didPop) {
      router?.go('/summary');
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income,
          duration: const Duration(milliseconds: 1200),
          content: Text(strings.deleted),
        ),
      );
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }
    FocusScope.of(context).unfocus();
    final double? amount = _parseAmount();
    setState(() {
      _didAttemptSubmit = true;
      _amountError = amount == null || amount <= 0
          ? context.strings.enterAmountGreaterThanZeroPence
          : null;
      _categoryError = _selectedCategoryId == null
          ? (_isExpense
                ? context.strings.chooseCategory
                : context.strings.chooseIncomeType)
          : null;
      _paymentError = _selectedPaymentMethod == null
          ? context.strings.choosePaymentMethod
          : null;
    });

    if (_amountError != null ||
        _categoryError != null ||
        _paymentError != null) {
      return;
    }

    final EntryDraft draft = EntryDraft(
      type: _isExpense ? TransactionType.expense : TransactionType.income,
      occurredOn: _occurredOn,
      amountMinor: (amount! * 100).round(),
      categoryId: _selectedCategoryId!,
      paymentMethod: _selectedPaymentMethod!,
      sourcePlatform: _isExpense ? null : _selectedSourcePlatform,
      vendor: _isExpense ? _trimToNull(_vendorController.text) : null,
      supplierId: _isExpense ? _selectedSupplierId : null,
      note: _trimToNull(_noteController.text),
    );

    setState(() {
      _saving = true;
      _saveSucceeded = false;
    });
    try {
      if (!_isExpense) {
        debugPrint('INCOME_SAVE_STARTED');
      }
      if (_isEditing) {
        await ref
            .read(giderRepositoryProvider)
            .updateTransaction(id: widget.transactionId!, draft: draft);
      } else {
        await ref.read(giderRepositoryProvider).createTransaction(draft);
      }
      _refreshAfterTransactionMutation();
      if (!_isExpense) {
        debugPrint('INCOME_SAVE_SUCCESS');
      }
      await _finishSuccessfulSubmit();
    } on DomainValidationException catch (error) {
      if (!_isExpense) {
        debugPrint('INCOME_SAVE_ERROR');
        debugPrint('INCOME_SAVE_ERROR_DETAILS: ${error.message}');
      }
      _showErrorSnack(error.message);
    } on AuthException catch (error) {
      if (!_isExpense) {
        debugPrint('INCOME_SAVE_ERROR');
        debugPrint('INCOME_SAVE_ERROR_DETAILS: ${error.message}');
      }
      _showErrorSnack(error.message);
    } catch (error) {
      if (!_isExpense) {
        debugPrint('INCOME_SAVE_ERROR');
        debugPrint('INCOME_SAVE_ERROR_DETAILS: $error');
      }
      _showErrorSnack(context.strings.couldNotSaveEntry(error.toString()));
    } finally {
      if (mounted && !_saveSucceeded) {
        setState(() => _saving = false);
      }
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.expense,
        content: Text(message),
      ),
    );
  }

  DateTime _sundayOf(DateTime date) {
    final DateTime normalized = DateTime(date.year, date.month, date.day);
    final int daysUntilSunday = (DateTime.sunday - normalized.weekday) % 7;
    return normalized.add(Duration(days: daysUntilSunday));
  }

  String? _trimToNull(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _handleAmountChanged(String _) {
    if (!_didAttemptSubmit) {
      return;
    }
    final double? amount = _parseAmount();
    setState(() {
      _amountError = amount == null || amount <= 0
          ? context.strings.enterAmountGreaterThanZeroPence
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final MediaQueryData mq = MediaQuery.of(context);
    final double bottomInset = mq.viewInsets.bottom;
    final AsyncValue<List<CategoryData>> categoriesAsync = _categoriesAsync;
    final List<CategoryData> categories =
        categoriesAsync.asData?.value ?? const <CategoryData>[];
    final bool categoriesLoading = categoriesAsync.isLoading;
    final String? categoriesErrorMessage = categoriesAsync.hasError
        ? categoriesAsync.error.toString()
        : null;
    String? selectedCategoryName;
    if (_selectedCategoryId != null) {
      for (final CategoryData item in categories) {
        if (item.id == _selectedCategoryId) {
          selectedCategoryName = item.name;
          break;
        }
      }
    }
    final _IncomeTypeOption? selectedIncomeType = _incomeTypeForCategoryName(
      selectedCategoryName,
    );
    final AsyncValue<List<SupplierData>> suppliersAsync =
        _isExpense && _selectedCategoryId != null
        ? ref.watch(
            suppliersProvider(
              SuppliersQuery(expenseCategoryId: _selectedCategoryId),
            ),
          )
        : const AsyncData(<SupplierData>[]);
    final List<SupplierData> suppliers =
        suppliersAsync.asData?.value ?? const <SupplierData>[];
    final bool suppliersLoading =
        _isExpense && _selectedCategoryId != null && suppliersAsync.isLoading;
    final String? suppliersErrorMessage =
        _isExpense &&
            _selectedCategoryId != null &&
            suppliersAsync.hasError
        ? suppliersAsync.error.toString()
        : null;
    SupplierData? selectedActiveSupplier;
    if (_selectedSupplierId != null) {
      for (final SupplierData supplier in suppliers) {
        if (supplier.id == _selectedSupplierId) {
          selectedActiveSupplier = supplier;
          break;
        }
      }
    }
    final String? selectedSupplierName =
        selectedActiveSupplier?.name ?? _selectedSupplierName;
    final bool selectedSupplierIsArchived =
        _selectedSupplierId != null &&
        _selectedSupplierName != null &&
        selectedActiveSupplier == null &&
        !suppliersLoading &&
        suppliersErrorMessage == null;

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
                      key: const ValueKey<String>('entry-scroll-view'),
                      controller: _scrollController,
                      primary: false,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                            // Web autofocus can force the scroll view to jump
                            // near the bottom on first paint, which makes the
                            // form look blank.
                            autofocus: !kIsWeb,
                            errorText: _amountError,
                            onChanged: _handleAmountChanged,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (_isExpense)
                            _ExpenseFields(
                              categories: categories,
                              categoriesLoading: categoriesLoading,
                              categoriesErrorMessage: categoriesErrorMessage,
                              selectedCategoryId: _selectedCategoryId,
                              selectedSupplierId: _selectedSupplierId,
                              selectedSupplierName: selectedSupplierName,
                              selectedSupplierIsArchived:
                                  selectedSupplierIsArchived,
                              suppliers: suppliers,
                              suppliersLoading: suppliersLoading,
                              suppliersErrorMessage: suppliersErrorMessage,
                              selectedPaymentMethod: _selectedPaymentMethod,
                              paymentMethods: PaymentMethodType.values,
                              categoryError: _categoryError,
                              paymentError: _paymentError,
                              vendorController: _vendorController,
                              noteController: _noteController,
                              occurredOnLabel: _formatHeaderDate(_occurredOn),
                              showTodayPill: _isToday,
                              attachmentLabel: _attachmentLabel,
                              onCategorySelected: (CategoryData category) {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                  _selectedSupplierId = null;
                                  _selectedSupplierName = null;
                                  _categoryError = null;
                                });
                              },
                              onSupplierTap: _selectedCategoryId == null
                                  ? null
                                  : () => _pickSupplier(
                                      categoryName:
                                          selectedCategoryName ??
                                          strings.category,
                                      suppliers: suppliers,
                                      loading: suppliersLoading,
                                      errorMessage: suppliersErrorMessage,
                                    ),
                              onSupplierCleared: _selectedSupplierId == null
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedSupplierId = null;
                                        _selectedSupplierName = null;
                                      });
                                    },
                              onPaymentSelected: (PaymentMethodType value) {
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
                              selectedIncomeType: selectedIncomeType,
                              selectedPaymentMethod: _selectedPaymentMethod,
                              categoryError: _categoryError,
                              paymentError: _paymentError,
                              noteController: _noteController,
                              occurredOnLabel: _formatHeaderDate(_occurredOn),
                              showTodayPill: _isToday,
                              attachmentLabel: _attachmentLabel,
                              isSettlementSelected: _isSettlementSelected,
                              categoriesLoading: categoriesLoading,
                              categoriesErrorMessage: categoriesErrorMessage,
                              onIncomeTypeTap: () =>
                                  _pickIncomeType(categories),
                              onPaymentSelected: (PaymentMethodType value) {
                                setState(() {
                                  _selectedPaymentMethod = value;
                                  _paymentError = null;
                                });
                              },
                              onDateTap: _pickDate,
                              onAttachmentTap: _toggleAttachment,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_preloading)
                  const Positioned.fill(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_preloadFailed)
                  Positioned.fill(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 40,
                              color: AppColors.inkFade,
                            ),
                            SizedBox(height: 12),
                            Text(
                              strings.couldNotLoadEntry,
                              style: AppTypography.body,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              strings.checkConnectionAndTryAgain,
                              style: AppTypography.meta,
                              textAlign: TextAlign.center,
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
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: _StickySaveBar(
                          saveLabel: _saveLabel,
                          saveLoading: _saving,
                          saveVariant: _isExpense
                              ? AppButtonVariant.primary
                              : AppButtonVariant.income,
                          onSave: _saving || _preloading || _saveSucceeded
                              ? null
                              : _submit,
                          secondaryLabel: _isEditing
                              ? strings.delete
                              : (_isExpense ? strings.recurring : null),
                          onSecondaryTap: _isEditing
                              ? (_deleting || _saving || _saveSucceeded
                                    ? null
                                    : _delete)
                              : (_isExpense && !_saving && !_saveSucceeded
                                    ? _showRecurringHandoff
                                    : null),
                          secondaryDestructive: _isEditing,
                        ),
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
    final AppLocalizations strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.of(context).maybePop(),
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
                      strings.back,
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
              TextSpan(
                text: title,
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
    required this.categoriesLoading,
    required this.categoriesErrorMessage,
    required this.selectedCategoryId,
    required this.selectedSupplierId,
    required this.selectedSupplierName,
    required this.selectedSupplierIsArchived,
    required this.suppliers,
    required this.suppliersLoading,
    required this.suppliersErrorMessage,
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
    required this.onSupplierTap,
    required this.onSupplierCleared,
    required this.onPaymentSelected,
    required this.onDateTap,
    required this.onAttachmentTap,
  });

  final List<CategoryData> categories;
  final bool categoriesLoading;
  final String? categoriesErrorMessage;
  final String? selectedCategoryId;
  final String? selectedSupplierId;
  final String? selectedSupplierName;
  final bool selectedSupplierIsArchived;
  final List<SupplierData> suppliers;
  final bool suppliersLoading;
  final String? suppliersErrorMessage;
  final PaymentMethodType? selectedPaymentMethod;
  final List<PaymentMethodType> paymentMethods;
  final String? categoryError;
  final String? paymentError;
  final TextEditingController vendorController;
  final TextEditingController noteController;
  final String occurredOnLabel;
  final bool showTodayPill;
  final String? attachmentLabel;
  final ValueChanged<CategoryData> onCategorySelected;
  final VoidCallback? onSupplierTap;
  final VoidCallback? onSupplierCleared;
  final ValueChanged<PaymentMethodType> onPaymentSelected;
  final VoidCallback onDateTap;
  final VoidCallback onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final String? sectionHelper;
    if (categoriesLoading && categories.isEmpty) {
      sectionHelper = strings.loadingCategories;
    } else if (categoriesErrorMessage != null) {
      sectionHelper = strings.loadingCategoriesPullToRetry;
    } else if (categories.isEmpty) {
      sectionHelper = strings.noCategoriesCreateInSettings;
    } else {
      sectionHelper = null;
    }
    final String? supplierHelper;
    if (selectedCategoryId == null) {
      supplierHelper = strings.chooseCategoryFirstForSuppliers;
    } else if (selectedSupplierIsArchived) {
      supplierHelper = strings.archivedSupplierLinkedHelper;
    } else if (suppliersLoading && suppliers.isEmpty) {
      supplierHelper = strings.loadingSuppliers;
    } else if (suppliersErrorMessage != null) {
      supplierHelper = strings.couldNotLoadSuppliers;
    } else if (suppliers.isEmpty) {
      supplierHelper = strings.noSuppliersForCategory;
    } else {
      supplierHelper = strings.optionalSupplierSelectionHelper;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppFormSectionCard(
          label: strings.category,
          helper: sectionHelper,
          errorText: categoryError,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final CategoryData category in categories)
                HiFiFilterChip(
                  label: category.name,
                  selected: selectedCategoryId == category.id,
                  onTap: () => onCategorySelected(category),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          key: const ValueKey<String>('entry-supplier-selector'),
          onTap: onSupplierTap,
          label: strings.chooseSupplier,
          helper: supplierHelper,
          trailing: selectedSupplierId == null
              ? null
              : InkWell(
                  key: const ValueKey<String>('entry-supplier-clear-button'),
                  borderRadius: BorderRadius.circular(999),
                  onTap: onSupplierCleared,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.inkFade,
                    ),
                  ),
                ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  selectedSupplierName ?? strings.chooseSupplier,
                  style: (selectedSupplierName == null
                          ? AppTypography.bodySoft
                          : AppTypography.body)
                      .copyWith(fontSize: 14.5),
                ),
              ),
              if (selectedSupplierIsArchived) ...<Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    strings.archivedLabel,
                    style: AppTypography.meta.copyWith(
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                onSupplierTap == null
                    ? Icons.lock_outline_rounded
                    : Icons.search_rounded,
                size: 18,
                color: AppColors.inkFade,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChipSection(
          label: strings.paymentMethod,
          errorText: paymentError,
          values: paymentMethods,
          selectedValue: selectedPaymentMethod,
          labelBuilder: strings.paymentMethodLabel,
          onSelected: onPaymentSelected,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: strings.vendor,
          helper: strings.optionalSupplierHelper,
          child: _CardTextField(
            controller: vendorController,
            hint: strings.vendorHint,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppDateField(
          label: strings.occurredOn,
          value: occurredOnLabel,
          showTodayPill: showTodayPill,
          onTap: onDateTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: strings.note,
          helper: strings.optionalNoteExpenseHelper,
          child: _CardTextField(
            controller: noteController,
            hint: strings.expenseNoteHint,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiAttachmentTile(
          label: strings.attachment,
          hint: strings.addReceiptPhoto,
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
    required this.selectedIncomeType,
    required this.selectedPaymentMethod,
    required this.categoryError,
    required this.paymentError,
    required this.noteController,
    required this.occurredOnLabel,
    required this.showTodayPill,
    required this.attachmentLabel,
    required this.isSettlementSelected,
    required this.categoriesLoading,
    required this.categoriesErrorMessage,
    required this.onIncomeTypeTap,
    required this.onPaymentSelected,
    required this.onDateTap,
    required this.onAttachmentTap,
  });

  final _IncomeTypeOption? selectedIncomeType;
  final PaymentMethodType? selectedPaymentMethod;
  final String? categoryError;
  final String? paymentError;
  final TextEditingController noteController;
  final String occurredOnLabel;
  final bool showTodayPill;
  final String? attachmentLabel;
  final bool isSettlementSelected;
  final bool categoriesLoading;
  final String? categoriesErrorMessage;
  final VoidCallback onIncomeTypeTap;
  final ValueChanged<PaymentMethodType> onPaymentSelected;
  final VoidCallback onDateTap;
  final VoidCallback onAttachmentTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final String selectorHelper = isSettlementSelected
        ? strings.settlementWeekHelper
        : strings.incomeTypeHelper;
    final String? incomeTypeHint;
    if (categoriesLoading && selectedIncomeType == null) {
      incomeTypeHint = strings.loadingCategories;
    } else if (categoriesErrorMessage != null) {
      incomeTypeHint = strings.loadingCategoriesPullToRetry;
    } else {
      incomeTypeHint = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppCard.compact(
          variant: AppCardVariant.mint,
          onTap: onIncomeTypeTap,
          border: Border.all(color: AppColors.cardMintBorder),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(strings.incomeType, style: AppTypography.lbl),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      selectedIncomeType?.label(strings) ??
                          strings.chooseIncomeTypeLabel,
                      style:
                          (selectedIncomeType == null
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
              const SizedBox(height: 6),
              Text(
                selectorHelper,
                style: AppTypography.meta.copyWith(color: AppColors.inkFade),
              ),
              if (incomeTypeHint != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  incomeTypeHint,
                  style: AppTypography.meta.copyWith(color: AppColors.inkFade),
                ),
              ],
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
        if (selectedIncomeType == _IncomeTypeOption.other) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          _ChipSection(
            label: strings.paymentMethod,
            helper: strings.otherIncomePaymentHelper,
            errorText: paymentError,
            values: PaymentMethodType.values,
            selectedValue: selectedPaymentMethod,
            labelBuilder: strings.paymentMethodLabel,
            chipTone: HiFiFilterChipTone.brand,
            onSelected: onPaymentSelected,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        AppDateField(
          label: strings.occurredOn,
          value: occurredOnLabel,
          showTodayPill: showTodayPill,
          onTap: onDateTap,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFormSectionCard(
          label: strings.note,
          helper: strings.optionalNoteIncomeHelper,
          child: _CardTextField(
            controller: noteController,
            hint: strings.incomeNoteHint,
            maxLines: 3,
            minLines: 2,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        HiFiAttachmentTile(
          label: strings.attachment,
          hint: strings.addPayoutSlip,
          attachmentLabel: attachmentLabel,
          tone: HiFiAttachmentTone.income,
          onTap: onAttachmentTap,
        ),
      ],
    );
  }
}

class _ChipSection<T> extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
    this.errorText,
    this.helper,
    this.chipTone = HiFiFilterChipTone.ink,
  });

  final String label;
  final List<T> values;
  final T? selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
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
              (T value) => HiFiFilterChip(
                label: labelBuilder(value),
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

class _SupplierPickerResult {
  const _SupplierPickerResult._({this.supplier, required this.cleared});

  const _SupplierPickerResult.selected(SupplierData supplier)
    : this._(supplier: supplier, cleared: false);

  const _SupplierPickerResult.cleared() : this._(cleared: true);

  final SupplierData? supplier;
  final bool cleared;
}

class _SupplierPickerSheet extends StatefulWidget {
  const _SupplierPickerSheet({
    required this.categoryName,
    required this.suppliers,
    required this.loading,
    required this.errorMessage,
    required this.selectedSupplierId,
    required this.archivedLinkedSupplierName,
  });

  final String categoryName;
  final List<SupplierData> suppliers;
  final bool loading;
  final String? errorMessage;
  final String? selectedSupplierId;
  final String? archivedLinkedSupplierName;

  @override
  State<_SupplierPickerSheet> createState() => _SupplierPickerSheetState();
}

class _SupplierPickerSheetState extends State<_SupplierPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final String normalizedQuery = _query.trim().toLowerCase();
    final List<SupplierData> filteredSuppliers = normalizedQuery.isEmpty
        ? widget.suppliers
        : widget.suppliers.where((SupplierData supplier) {
            return supplier.name.toLowerCase().contains(normalizedQuery);
          }).toList();

    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.chooseSupplier.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 4),
          Text(widget.categoryName, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(strings.searchSuppliersHint, style: AppTypography.bodySoft),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              key: const ValueKey<String>('entry-supplier-search-field'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.brand,
              onChanged: (String value) {
                setState(() => _query = value);
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                icon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.inkFade,
                ),
                hintText: strings.searchSuppliersHint,
                hintStyle: AppTypography.bodySoft.copyWith(
                  color: AppColors.inkFade,
                ),
              ),
            ),
          ),
          if (widget.archivedLinkedSupplierName != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              key: const ValueKey<String>('entry-supplier-archived-banner'),
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      widget.archivedLinkedSupplierName!,
                      style: AppTypography.body.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    strings.archivedLabel,
                    style: AppTypography.meta.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _buildSupplierList(strings, filteredSuppliers),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(
    AppLocalizations strings,
    List<SupplierData> filteredSuppliers,
  ) {
    if (widget.loading && widget.suppliers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (widget.errorMessage != null && widget.suppliers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(strings.couldNotLoadSuppliers, style: AppTypography.body),
      );
    }
    if (widget.suppliers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(strings.noSuppliersForCategory, style: AppTypography.body),
      );
    }
    if (filteredSuppliers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(strings.noSuppliersMatchSearch, style: AppTypography.body),
      );
    }

    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        if (widget.selectedSupplierId != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey<String>('entry-supplier-clear-option'),
              onTap: () {
                Navigator.of(context).pop(const _SupplierPickerResult.cleared());
              },
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.block_rounded,
                      size: 18,
                      color: AppColors.inkFade,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(strings.noSupplier, style: AppTypography.body),
                    ),
                  ],
                ),
              ),
            ),
          ),
        for (final SupplierData supplier in filteredSuppliers)
          Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey<String>('entry-supplier-option-${supplier.id}'),
              onTap: () {
                Navigator.of(
                  context,
                ).pop(_SupplierPickerResult.selected(supplier));
              },
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.store_outlined,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(supplier.name, style: AppTypography.body),
                    ),
                    if (widget.selectedSupplierId == supplier.id)
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
    );
  }
}

class _StickySaveBar extends StatelessWidget {
  const _StickySaveBar({
    required this.saveLabel,
    required this.saveLoading,
    required this.saveVariant,
    required this.onSave,
    this.secondaryLabel,
    this.onSecondaryTap,
    this.secondaryDestructive = false,
  });

  final String saveLabel;
  final bool saveLoading;
  final AppButtonVariant saveVariant;
  final VoidCallback? onSave;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryTap;
  final bool secondaryDestructive;

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
              if (secondaryLabel != null) ...<Widget>[
                AppButton(
                  label: secondaryLabel!,
                  onPressed: onSecondaryTap,
                  variant: secondaryDestructive
                      ? AppButtonVariant.expense
                      : AppButtonVariant.ghost,
                  size: AppButtonSize.compact,
                  expanded: false,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: AppButton(
                  label: saveLabel,
                  loading: saveLoading,
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
