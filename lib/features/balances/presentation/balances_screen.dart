import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/domain/types.dart' show DomainValidationException;
import '../../../l10n/app_localizations.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_date_field.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_list_row.dart';
import '../../../shared/overlay/app_overlay.dart';
import '../domain/balance_models.dart';

class BalancesScreen extends ConsumerStatefulWidget {
  const BalancesScreen({super.key});

  @override
  ConsumerState<BalancesScreen> createState() => _BalancesScreenState();
}

class _BalancesScreenState extends ConsumerState<BalancesScreen> {
  BalanceDirection _selectedDirection = BalanceDirection.payable;

  Future<void> _openAccountSheet() async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _BalanceAccountSheet(),
    );
  }

  Future<void> _openQuickDecreaseSheet(
    BalanceDirection direction,
    List<BalanceAccountData> accounts,
  ) async {
    final List<BalanceAccountData> eligibleAccounts = accounts
        .where(
          (BalanceAccountData account) =>
              account.direction == direction &&
              account.status == BalanceAccountStatus.active &&
              account.remainingMinor > 0,
        )
        .toList();
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _QuickDecreaseSheet(direction: direction, accounts: eligibleAccounts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<BalanceSummaryData> summary = ref.watch(
      balancesSummaryProvider,
    );

    return summary.when(
      data: (BalanceSummaryData data) {
        final List<BalanceAccountData> accounts = data.byDirection(
          _selectedDirection,
        );
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenSide,
                  AppSpacing.xs,
                  AppSpacing.screenSide,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _Header(
                      title: strings.balancesTitle,
                      parentLabel: strings.settings,
                      onBack: () => context.pop(),
                      onAdd: _openAccountSheet,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _SummaryCard(
                            label: strings.balanceIOwe,
                            amountMinor: data.iOweMinor,
                            tone: _AmountTone.expense,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _SummaryCard(
                            label: strings.balanceOwedToMe,
                            amountMinor: data.owedToMeMinor,
                            tone: _AmountTone.income,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _SummaryCard(
                      label: strings.balanceNetPosition,
                      amountMinor: data.netPositionMinor,
                      tone: data.netPositionMinor < 0
                          ? _AmountTone.expense
                          : _AmountTone.brand,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: HiFiButton(
                            label: strings.payDebt,
                            variant: HiFiButtonVariant.ghost,
                            onPressed: () => _openQuickDecreaseSheet(
                              BalanceDirection.payable,
                              data.accounts,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: HiFiButton(
                            label: strings.collectReceivable,
                            variant: HiFiButtonVariant.ghost,
                            onPressed: () => _openQuickDecreaseSheet(
                              BalanceDirection.receivable,
                              data.accounts,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: <Widget>[
                        HiFiFilterChip(
                          label: strings.balancePayables,
                          selected:
                              _selectedDirection == BalanceDirection.payable,
                          onTap: () => setState(
                            () => _selectedDirection = BalanceDirection.payable,
                          ),
                        ),
                        const SizedBox(width: 6),
                        HiFiFilterChip(
                          label: strings.balanceReceivables,
                          selected:
                              _selectedDirection == BalanceDirection.receivable,
                          onTap: () => setState(
                            () => _selectedDirection =
                                BalanceDirection.receivable,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenSide,
                0,
                AppSpacing.screenSide,
                120,
              ),
              sliver: SliverList.separated(
                itemCount: accounts.isEmpty ? 1 : accounts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (BuildContext context, int index) {
                  if (accounts.isEmpty) {
                    return _EmptyBalancesCard(onAdd: _openAccountSheet);
                  }
                  final BalanceAccountData account = accounts[index];
                  return _BalanceAccountCard(
                    account: account,
                    onTap: () =>
                        context.push('/settings/balances/${account.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _LoadError(
        title: strings.balanceLoadError,
        error: error,
        onRetry: () => ref.invalidate(balancesSummaryProvider),
      ),
    );
  }
}

class BalanceAccountDetailScreen extends ConsumerWidget {
  const BalanceAccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  Future<void> _openMovementSheet(
    BuildContext context,
    BalanceAccountData account,
    BalanceMovementData? movement,
  ) async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _BalanceMovementSheet(account: account, movement: movement),
    );
  }

  Future<void> _openEditAccountSheet(
    BuildContext context,
    BalanceAccountData account,
  ) async {
    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BalanceAccountSheet(account: account),
    );
  }

  Future<void> _closeAccount(
    BuildContext context,
    WidgetRef ref,
    BalanceAccountData account,
  ) async {
    try {
      await ref.read(balancesRepositoryProvider).closeAccount(account.id);
      ref.read(refreshKeyProvider.notifier).state++;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income,
          content: Text(context.strings.balanceAccountClosed),
        ),
      );
    } on DomainValidationException catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(context, _localizedBalanceError(context.strings, error));
    } on AuthException catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(context, _localizedBalanceError(context.strings, error));
    } catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(context, _localizedBalanceError(context.strings, error));
    }
  }

  Future<void> _deleteMovement(
    BuildContext context,
    WidgetRef ref,
    BalanceAccountData account,
    BalanceMovementData movement,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final AppLocalizations strings = dialogContext.strings;
        return AlertDialog(
          title: Text(strings.deleteBalanceMovementConfirmTitle),
          content: Text(strings.deleteBalanceMovementConfirmMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(balancesRepositoryProvider)
          .deleteMovement(accountId: account.id, movementId: movement.id);
      ref.read(refreshKeyProvider.notifier).state++;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.income,
          content: Text(context.strings.balanceMovementDeleted),
        ),
      );
    } on DomainValidationException catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(
        context,
        _localizedBalanceError(
          context.strings,
          error,
          fallback: context.strings.balanceDeleteMovementFailed,
        ),
      );
    } on AuthException catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(context, _localizedBalanceError(context.strings, error));
    } catch (error) {
      if (!context.mounted) return;
      _showErrorSnack(
        context,
        _localizedBalanceError(
          context.strings,
          error,
          fallback: context.strings.balanceDeleteMovementFailed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = context.strings;
    final AsyncValue<BalanceAccountData?> accountState = ref.watch(
      balanceAccountProvider(accountId),
    );

    return accountState.when(
      data: (BalanceAccountData? account) {
        if (account == null) {
          return _LoadError(
            title: strings.balanceAccountNotFound,
            error: strings.balanceAccountRemoved,
            onRetry: () => ref.invalidate(balanceAccountProvider(accountId)),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenSide,
            AppSpacing.xs,
            AppSpacing.screenSide,
            120,
          ),
          children: <Widget>[
            _Header(
              title: account.name,
              parentLabel: strings.balancesTitle,
              onBack: () => context.pop(),
              onAdd: () => _openMovementSheet(context, account, null),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SummaryCard(
              label: strings.balanceRemaining,
              amountMinor: account.remainingMinor,
              tone: account.direction == BalanceDirection.payable
                  ? _AmountTone.expense
                  : _AmountTone.income,
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.balanceAccountInfo, style: AppTypography.lbl),
                  const SizedBox(height: AppSpacing.sm),
                  if (account.counterpartyName.trim().isNotEmpty)
                    _InfoRow(
                      label: strings.balanceCounterparty,
                      value: account.counterpartyName,
                    ),
                  _InfoRow(
                    label: strings.balanceDirection,
                    value: strings.balanceDirectionLabel(account.direction),
                  ),
                  _InfoRow(
                    label: strings.balanceType,
                    value: strings.balanceAccountTypeLabel(account.type),
                  ),
                  _InfoRow(
                    label: strings.balanceOpened,
                    value: strings.dayMonthYear(account.openedAt),
                  ),
                  _InfoRow(
                    label: strings.balanceStatus,
                    value: strings.balanceAccountStatusLabel(account.status),
                  ),
                  if (account.notes != null)
                    _InfoRow(
                      label: strings.balanceNotes,
                      value: account.notes!,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiButton(
              label: strings.addBalanceMovement,
              onPressed: () => _openMovementSheet(context, account, null),
            ),
            const SizedBox(height: AppSpacing.xs),
            HiFiButton(
              label: strings.editBalanceAccount,
              variant: HiFiButtonVariant.ghost,
              onPressed: () => _openEditAccountSheet(context, account),
            ),
            if (account.canClose &&
                account.status == BalanceAccountStatus.active) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              HiFiButton(
                label: strings.closeBalanceAccount,
                variant: HiFiButtonVariant.ink,
                onPressed: () => _closeAccount(context, ref, account),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(strings.balanceMovementHistory, style: AppTypography.lbl),
            const SizedBox(height: AppSpacing.xs),
            if (account.movements.isEmpty)
              HiFiCard(
                child: Text(
                  strings.noBalanceMovementsYet,
                  style: AppTypography.bodySoft,
                ),
              )
            else
              HiFiCard.flush(
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < account.movements.length; i++)
                      HiFiListRow(
                        leading: Icon(
                          _movementIcon(account.movements[i].type),
                          size: 20,
                          color:
                              account.movements[i].type ==
                                  BalanceMovementType.decrease
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                        title: strings.balanceMovementActionLabel(
                          account.direction,
                          account.movements[i].type,
                        ),
                        meta:
                            '${strings.dayMonthYear(account.movements[i].occurredAt)} · ${strings.balancePaymentMethodLabel(account.movements[i].paymentMethod)}'
                            '${account.movements[i].notes == null ? '' : ' · ${account.movements[i].notes}'}',
                        trailing: _MovementRowActions(
                          amount: _balanceCurrencyMinor(
                            strings,
                            account.movements[i].amountMinor,
                          ),
                          color:
                              account.movements[i].type ==
                                  BalanceMovementType.decrease
                              ? AppColors.expense
                              : AppColors.income,
                          onEdit: () => _openMovementSheet(
                            context,
                            account,
                            account.movements[i],
                          ),
                          onDelete: () => _deleteMovement(
                            context,
                            ref,
                            account,
                            account.movements[i],
                          ),
                        ),
                        onTap: () => _openMovementSheet(
                          context,
                          account,
                          account.movements[i],
                        ),
                        showDivider: i != account.movements.length - 1,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) => _LoadError(
        title: strings.balanceAccountLoadError,
        error: error,
        onRetry: () => ref.invalidate(balanceAccountProvider(accountId)),
      ),
    );
  }
}

class _BalanceAccountSheet extends ConsumerStatefulWidget {
  const _BalanceAccountSheet({this.account});

  final BalanceAccountData? account;

  @override
  ConsumerState<_BalanceAccountSheet> createState() =>
      _BalanceAccountSheetState();
}

class _BalanceAccountSheetState extends ConsumerState<_BalanceAccountSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _counterpartyController;
  late final TextEditingController _openingAmountController;
  late final TextEditingController _notesController;
  BalanceDirection _direction = BalanceDirection.payable;
  BalanceAccountType _type = BalanceAccountType.personal;
  DateTime _openedAt = DateTime.now();
  String? _errorText;
  String? _nameErrorText;
  String? _counterpartyErrorText;
  String? _openingAmountErrorText;
  bool _saving = false;
  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final BalanceAccountData? account = widget.account;
    _nameController = TextEditingController(text: account?.name);
    _counterpartyController = TextEditingController(
      text: account?.counterpartyName,
    );
    _openingAmountController = TextEditingController();
    _notesController = TextEditingController(text: account?.notes);
    if (account != null) {
      _direction = account.direction;
      _type = account.type;
      _openedAt = account.openedAt;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _counterpartyController.dispose();
    _openingAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await _pickAppDate(context, _openedAt);
    if (picked != null) {
      setState(() => _openedAt = picked);
    }
  }

  Future<void> _save() async {
    final AppLocalizations strings = context.strings;
    setState(() {
      _errorText = null;
      _nameErrorText = null;
      _counterpartyErrorText = null;
      _openingAmountErrorText = null;
    });

    final int? openingAmountMinor = _editing
        ? 0
        : _parseOptionalAmountMinor(_openingAmountController.text);
    bool hasValidationError = false;
    if (_nameController.text.trim().isEmpty) {
      _nameErrorText = strings.balanceNameRequired;
      hasValidationError = true;
    }
    if (openingAmountMinor == null) {
      _openingAmountErrorText = strings.balanceOpeningAmountInvalid;
      hasValidationError = true;
    }
    if (hasValidationError) {
      setState(() {});
      return;
    }
    final int resolvedOpeningAmountMinor = openingAmountMinor!;

    setState(() => _saving = true);
    try {
      if (_editing) {
        await ref
            .read(balancesRepositoryProvider)
            .updateAccount(
              accountId: widget.account!.id,
              draft: BalanceAccountEditDraft(
                name: _nameController.text,
                counterpartyName: _counterpartyController.text,
                type: _type,
                openedAt: _openedAt,
                notes: _notesController.text,
              ),
            );
      } else {
        await ref
            .read(balancesRepositoryProvider)
            .createAccount(
              BalanceAccountDraft(
                direction: _direction,
                name: _nameController.text,
                counterpartyName: _counterpartyController.text,
                type: _type,
                openingAmountMinor: resolvedOpeningAmountMinor,
                openedAt: _openedAt,
                notes: _notesController.text,
              ),
            );
      }
      ref.read(refreshKeyProvider.notifier).state++;
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DomainValidationException catch (error) {
      if (!mounted) return;
      _applyAccountSaveError(error);
    } on AuthException catch (error) {
      if (!mounted) return;
      _applyAccountSaveError(error);
    } catch (error) {
      if (!mounted) return;
      _applyAccountSaveError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyAccountSaveError(Object error) {
    final AppLocalizations strings = context.strings;
    final _BalanceAccountErrorField field = _balanceAccountErrorField(error);
    setState(() {
      switch (field) {
        case _BalanceAccountErrorField.name:
          _nameErrorText = strings.balanceNameRequired;
        case _BalanceAccountErrorField.counterparty:
          _counterpartyErrorText = strings.balanceCounterpartyInvalid;
        case _BalanceAccountErrorField.openingAmount:
          _openingAmountErrorText = strings.balanceOpeningAmountInvalid;
        case _BalanceAccountErrorField.generic:
          _errorText = _localizedBalanceError(strings, error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      child: _SheetScrollBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _editing
                  ? strings.editBalanceAccount.toUpperCase()
                  : strings.addAccountUpper,
              style: AppTypography.eye,
            ),
            const SizedBox(height: 4),
            Text(
              _editing ? strings.editBalanceAccount : strings.newBalanceAccount,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_editing) ...<Widget>[
              _ChipPicker<BalanceDirection>(
                label: strings.balanceDirection,
                values: BalanceDirection.values,
                selectedValue: _direction,
                labelBuilder: strings.balanceDirectionLabel,
                onSelected: (BalanceDirection value) {
                  setState(() => _direction = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            HiFiInputField(
              controller: _nameController,
              label: strings.balanceName,
              hint: strings.balanceNameHint,
              textInputAction: TextInputAction.next,
              readOnly: _saving,
              errorText: _nameErrorText,
              onChanged: (_) {
                if (_nameErrorText != null) {
                  setState(() => _nameErrorText = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiInputField(
              controller: _counterpartyController,
              label: strings.balanceCounterpartyName,
              hint: strings.balanceCounterpartyHint,
              textInputAction: TextInputAction.next,
              readOnly: _saving,
              errorText: _counterpartyErrorText,
              onChanged: (_) {
                if (_counterpartyErrorText != null) {
                  setState(() => _counterpartyErrorText = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChipPicker<BalanceAccountType>(
              label: strings.balanceType,
              values: BalanceAccountType.values,
              selectedValue: _type,
              labelBuilder: strings.balanceAccountTypeLabel,
              onSelected: (BalanceAccountType value) {
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!_editing) ...<Widget>[
              HiFiInputField(
                controller: _openingAmountController,
                label: strings.balanceOpeningAmount,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                readOnly: _saving,
                errorText: _openingAmountErrorText,
                onChanged: (_) {
                  if (_openingAmountErrorText != null) {
                    setState(() => _openingAmountErrorText = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            HiFiDateField(
              label: strings.balanceOpenedDate,
              value: strings.dayMonthYear(_openedAt),
              onTap: _saving ? () {} : _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiInputField(
              controller: _notesController,
              label: strings.balanceNotes,
              hint: strings.balanceOptional,
              maxLines: 3,
              minLines: 2,
              readOnly: _saving,
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorText!,
                style: AppTypography.meta.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: HiFiButton(
                    label: strings.cancel,
                    variant: HiFiButtonVariant.ghost,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: HiFiButton(
                    label: strings.save,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceMovementSheet extends ConsumerStatefulWidget {
  const _BalanceMovementSheet({required this.account, this.movement});

  final BalanceAccountData account;
  final BalanceMovementData? movement;

  @override
  ConsumerState<_BalanceMovementSheet> createState() =>
      _BalanceMovementSheetState();
}

class _BalanceMovementSheetState extends ConsumerState<_BalanceMovementSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  BalanceMovementType _type = BalanceMovementType.decrease;
  BalancePaymentMethod _paymentMethod = BalancePaymentMethod.cash;
  DateTime _occurredAt = DateTime.now();
  String? _errorText;
  String? _amountErrorText;
  bool _saving = false;
  bool get _editing => widget.movement != null;

  @override
  void initState() {
    super.initState();
    final BalanceMovementData? movement = widget.movement;
    _amountController = TextEditingController(
      text: movement == null ? null : _amountText(movement.amountMinor),
    );
    _notesController = TextEditingController(text: movement?.notes);
    if (movement != null) {
      _type = movement.type == BalanceMovementType.decrease
          ? BalanceMovementType.decrease
          : BalanceMovementType.increase;
      _paymentMethod = movement.paymentMethod;
      _occurredAt = movement.occurredAt;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await _pickAppDate(context, _occurredAt);
    if (picked != null) {
      setState(() => _occurredAt = picked);
    }
  }

  Future<void> _save() async {
    setState(() {
      _errorText = null;
      _amountErrorText = null;
    });
    final int? amountMinor = _parsePositiveAmountMinor(_amountController.text);
    if (amountMinor == null) {
      setState(
        () => _amountErrorText = context.strings.balanceAmountGreaterThanZero,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final BalanceMovementDraft draft = BalanceMovementDraft(
        type: _type,
        amountMinor: amountMinor,
        occurredAt: _occurredAt,
        paymentMethod: _paymentMethod,
        notes: _notesController.text,
      );
      if (_editing) {
        await ref
            .read(balancesRepositoryProvider)
            .updateMovement(
              accountId: widget.account.id,
              movementId: widget.movement!.id,
              draft: draft,
            );
      } else {
        await ref
            .read(balancesRepositoryProvider)
            .addMovement(accountId: widget.account.id, draft: draft);
      }
      ref.read(refreshKeyProvider.notifier).state++;
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DomainValidationException catch (error) {
      if (!mounted) return;
      _applyMovementSaveError(error);
    } on AuthException catch (error) {
      if (!mounted) return;
      _applyMovementSaveError(error);
    } catch (error) {
      if (!mounted) return;
      _applyMovementSaveError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applyMovementSaveError(Object error) {
    setState(() {
      _errorText = _localizedBalanceError(
        context.strings,
        error,
        fallback: context.strings.balanceSaveMovementFailed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiBottomSheet(
      child: _SheetScrollBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _editing
                  ? strings.editBalanceMovement.toUpperCase()
                  : strings.addMovementUpper,
              style: AppTypography.eye,
            ),
            const SizedBox(height: 4),
            Text(
              _editing ? strings.editBalanceMovement : widget.account.name,
              style: AppTypography.h2,
            ),
            const SizedBox(height: AppSpacing.md),
            _ChipPicker<BalanceMovementType>(
              label: strings.balanceType,
              values: const <BalanceMovementType>[
                BalanceMovementType.increase,
                BalanceMovementType.decrease,
              ],
              selectedValue: _type,
              labelBuilder: (BalanceMovementType value) => strings
                  .balanceMovementActionLabel(widget.account.direction, value),
              onSelected: (BalanceMovementType value) {
                setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiInputField(
              controller: _amountController,
              label: strings.balanceAmount,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              readOnly: _saving,
              errorText: _amountErrorText,
              onChanged: (_) {
                if (_amountErrorText != null) {
                  setState(() => _amountErrorText = null);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiDateField(
              label: strings.balanceOccurredDate,
              value: strings.dayMonthYear(_occurredAt),
              onTap: _saving ? () {} : _pickDate,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChipPicker<BalancePaymentMethod>(
              label: strings.balancePaymentMethod,
              values: BalancePaymentMethod.values,
              selectedValue: _paymentMethod,
              labelBuilder: strings.balancePaymentMethodLabel,
              onSelected: (BalancePaymentMethod value) {
                setState(() => _paymentMethod = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            HiFiInputField(
              controller: _notesController,
              label: strings.balanceNotes,
              hint: strings.balanceOptional,
              maxLines: 3,
              minLines: 2,
              readOnly: _saving,
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorText!,
                style: AppTypography.meta.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: HiFiButton(
                    label: strings.cancel,
                    variant: HiFiButtonVariant.ghost,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: HiFiButton(
                    label: strings.save,
                    loading: _saving,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickDecreaseSheet extends ConsumerStatefulWidget {
  const _QuickDecreaseSheet({required this.direction, required this.accounts});

  final BalanceDirection direction;
  final List<BalanceAccountData> accounts;

  @override
  ConsumerState<_QuickDecreaseSheet> createState() =>
      _QuickDecreaseSheetState();
}

class _QuickDecreaseSheetState extends ConsumerState<_QuickDecreaseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _notesController;
  late BalanceAccountData? _selectedAccount;
  BalancePaymentMethod _paymentMethod = BalancePaymentMethod.cash;
  DateTime _occurredAt = DateTime.now();
  String? _amountErrorText;
  String? _errorText;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _notesController = TextEditingController();
    _selectedAccount = widget.accounts.isEmpty ? null : widget.accounts.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await _pickAppDate(context, _occurredAt);
    if (picked != null) {
      setState(() => _occurredAt = picked);
    }
  }

  Future<void> _save() async {
    final AppLocalizations strings = context.strings;
    setState(() {
      _amountErrorText = null;
      _errorText = null;
    });
    final BalanceAccountData? account = _selectedAccount;
    final int? amountMinor = _parsePositiveAmountMinor(_amountController.text);
    if (account == null) {
      setState(() {
        _errorText = widget.direction == BalanceDirection.payable
            ? strings.noPayablesToPay
            : strings.noReceivablesToCollect;
      });
      return;
    }
    if (amountMinor == null) {
      setState(() => _amountErrorText = strings.balanceAmountGreaterThanZero);
      return;
    }
    if (amountMinor > account.remainingMinor) {
      setState(
        () => _amountErrorText = strings.balanceAmountCannotExceedRemaining,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref
          .read(balancesRepositoryProvider)
          .addMovement(
            accountId: account.id,
            draft: BalanceMovementDraft(
              type: BalanceMovementType.decrease,
              amountMinor: amountMinor,
              occurredAt: _occurredAt,
              paymentMethod: _paymentMethod,
              notes: _notesController.text,
            ),
          );
      ref.read(refreshKeyProvider.notifier).state++;
      if (!mounted) return;
      Navigator.of(context).pop();
    } on DomainValidationException catch (error) {
      if (!mounted) return;
      _applySaveError(error);
    } on AuthException catch (error) {
      if (!mounted) return;
      _applySaveError(error);
    } catch (error) {
      if (!mounted) return;
      _applySaveError(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _applySaveError(Object error) {
    setState(() {
      _errorText = _localizedBalanceError(
        context.strings,
        error,
        fallback: context.strings.balanceSaveMovementFailed,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final String title = widget.direction == BalanceDirection.payable
        ? strings.payDebt
        : strings.collectReceivable;
    return HiFiBottomSheet(
      child: _SheetScrollBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title.toUpperCase(), style: AppTypography.eye),
            const SizedBox(height: 4),
            Text(title, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.md),
            if (widget.accounts.isEmpty)
              Text(
                widget.direction == BalanceDirection.payable
                    ? strings.noPayablesToPay
                    : strings.noReceivablesToCollect,
                style: AppTypography.bodySoft,
              )
            else ...<Widget>[
              _ChipPicker<BalanceAccountData>(
                label: strings.selectBalanceAccount,
                values: widget.accounts,
                selectedValue: _selectedAccount!,
                labelBuilder: (BalanceAccountData account) =>
                    _accountChoiceLabel(strings, account),
                onSelected: (BalanceAccountData account) {
                  setState(() {
                    _selectedAccount = account;
                    _amountErrorText = null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              HiFiInputField(
                controller: _amountController,
                label: strings.balanceAmount,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                readOnly: _saving,
                errorText: _amountErrorText,
                onChanged: (_) {
                  if (_amountErrorText != null) {
                    setState(() => _amountErrorText = null);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              HiFiDateField(
                label: strings.balanceOccurredDate,
                value: strings.dayMonthYear(_occurredAt),
                onTap: _saving ? () {} : _pickDate,
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChipPicker<BalancePaymentMethod>(
                label: strings.balancePaymentMethod,
                values: BalancePaymentMethod.values,
                selectedValue: _paymentMethod,
                labelBuilder: strings.balancePaymentMethodLabel,
                onSelected: (BalancePaymentMethod value) {
                  setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              HiFiInputField(
                controller: _notesController,
                label: strings.balanceNotes,
                hint: strings.balanceOptional,
                maxLines: 3,
                minLines: 2,
                readOnly: _saving,
              ),
            ],
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                _errorText!,
                style: AppTypography.meta.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: HiFiButton(
                    label: strings.cancel,
                    variant: HiFiButtonVariant.ghost,
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  flex: 2,
                  child: HiFiButton(
                    label: strings.save,
                    loading: _saving,
                    onPressed: _saving || widget.accounts.isEmpty
                        ? null
                        : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.parentLabel,
    required this.onBack,
    required this.onAdd,
  });

  final String title;
  final String parentLabel;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onBack,
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
                      parentLabel,
                      style: AppTypography.bodySoft.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Material(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                key: const ValueKey<String>('balance-add-action'),
                onTap: onAdd,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: AppColors.onInk,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.strings.newLabel,
                        style: AppTypography.meta.copyWith(
                          color: AppColors.onInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.smTight),
        Text(
          title,
          style: AppTypography.h1.copyWith(
            color: AppColors.brand,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amountMinor,
    required this.tone,
  });

  final String label;
  final int amountMinor;
  final _AmountTone tone;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (tone) {
      _AmountTone.income => AppColors.income,
      _AmountTone.expense => AppColors.expense,
      _AmountTone.brand => AppColors.brand,
    };
    return HiFiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(), style: AppTypography.eye),
          const SizedBox(height: 6),
          Text(
            _balanceCurrencyMinor(context.strings, amountMinor),
            style: AppTypography.numMd.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

enum _AmountTone { income, expense, brand }

String _accountMeta(AppLocalizations strings, BalanceAccountData account) {
  final String type = strings.balanceAccountTypeLabel(account.type);
  final String counterparty = account.counterpartyName.trim();
  if (counterparty.isEmpty) {
    return type;
  }
  return '$counterparty · $type';
}

String _accountChoiceLabel(
  AppLocalizations strings,
  BalanceAccountData account,
) {
  final String counterparty = account.counterpartyName.trim();
  final String name = counterparty.isEmpty
      ? account.name
      : '${account.name} · $counterparty';
  return '$name · ${_balanceCurrencyMinor(strings, account.remainingMinor)}';
}

String _balanceCurrencyMinor(AppLocalizations strings, int amountMinor) {
  return strings.currencyMinor(
    amountMinor,
    decimalDigits: balanceCurrencyDecimalDigits(amountMinor),
  );
}

class _BalanceAccountCard extends StatelessWidget {
  const _BalanceAccountCard({required this.account, required this.onTap});

  final BalanceAccountData account;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(account.name, style: AppTypography.ttl)),
              Text(
                _balanceCurrencyMinor(context.strings, account.remainingMinor),
                style: AppTypography.numSm.copyWith(
                  color: account.direction == BalanceDirection.payable
                      ? AppColors.expense
                      : AppColors.income,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_accountMeta(strings, account), style: AppTypography.meta),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: _MiniStat(
                  label: strings.balanceMovementActionLabel(
                    account.direction,
                    BalanceMovementType.increase,
                  ),
                  value: _balanceCurrencyMinor(
                    strings,
                    account.totalIncreasedMinor,
                  ),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: strings.balanceMovementActionLabel(
                    account.direction,
                    BalanceMovementType.decrease,
                  ),
                  value: _balanceCurrencyMinor(
                    strings,
                    account.totalDecreasedMinor,
                  ),
                ),
              ),
              _StatusPill(status: account.status),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementRowActions extends StatelessWidget {
  const _MovementRowActions({
    required this.amount,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final String amount;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(amount, style: AppTypography.lbl.copyWith(color: color)),
        SizedBox(
          width: 32,
          height: 32,
          child: PopupMenuButton<_MovementAction>(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert_rounded, size: 18),
            onSelected: (_MovementAction value) {
              switch (value) {
                case _MovementAction.edit:
                  onEdit();
                case _MovementAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<_MovementAction>>[
                  PopupMenuItem<_MovementAction>(
                    value: _MovementAction.edit,
                    child: Text(strings.editBalanceMovement),
                  ),
                  PopupMenuItem<_MovementAction>(
                    value: _MovementAction.delete,
                    child: Text(strings.deleteBalanceMovement),
                  ),
                ],
          ),
        ),
      ],
    );
  }
}

enum _MovementAction { edit, delete }

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.meta),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.lbl),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BalanceAccountStatus status;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final bool closed = status == BalanceAccountStatus.closed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: closed
            ? AppColors.ink.withValues(alpha: 0.08)
            : AppColors.brandTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Text(
        strings.balanceAccountStatusLabel(status),
        style: AppTypography.meta.copyWith(
          fontWeight: FontWeight.w700,
          color: closed ? AppColors.inkSoft : AppColors.brand,
        ),
      ),
    );
  }
}

class _EmptyBalancesCard extends StatelessWidget {
  const _EmptyBalancesCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    return HiFiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.noBalanceAccountsYet, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.balancesEmptyBody,
            style: AppTypography.bodySoft.copyWith(height: 1.45),
          ),
          const SizedBox(height: AppSpacing.md),
          HiFiButton(label: strings.addBalanceAccount, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: AppTypography.meta)),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipPicker<T> extends StatelessWidget {
  const _ChipPicker({
    required this.label,
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AppTypography.lbl),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final T value in values)
              HiFiFilterChip(
                label: labelBuilder(value),
                selected: selectedValue == value,
                onTap: () => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _SheetScrollBody extends StatelessWidget {
  const _SheetScrollBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableHeight =
        mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        96;
    final double maxHeight = availableHeight < 120 ? 120 : availableHeight;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.only(
          bottom: mediaQuery.viewInsets.bottom > 0 ? 12 : 0,
        ),
        child: child,
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.title,
    required this.error,
    required this.onRetry,
  });

  final String title;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final String description = error is String
        ? error as String
        : context.strings.checkConnectionAndTryAgain;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: AppTypography.h2),
            const SizedBox(height: 8),
            Text(description, style: AppTypography.bodySoft),
            const SizedBox(height: AppSpacing.md),
            HiFiButton(label: context.strings.tryAgain, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

Future<DateTime?> _pickAppDate(BuildContext context, DateTime initialDate) {
  final DateTime today = DateTime.now();
  return showAppDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2020, 1, 1),
    lastDate: DateTime(today.year + 2, 12, 31),
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
}

int? _parseOptionalAmountMinor(String raw) {
  final String value = raw.trim();
  if (value.isEmpty) {
    return 0;
  }
  final double? parsed = double.tryParse(value.replaceAll(',', '.'));
  if (parsed == null || parsed < 0) {
    return null;
  }
  return (parsed * 100).round();
}

int? _parsePositiveAmountMinor(String raw) {
  final int? parsed = _parseOptionalAmountMinor(raw);
  if (parsed == null || parsed <= 0) {
    return null;
  }
  return parsed;
}

String _amountText(int amountMinor) {
  final String value = (amountMinor / 100).toStringAsFixed(2);
  return value.endsWith('.00') ? value.substring(0, value.length - 3) : value;
}

enum _BalanceAccountErrorField { name, counterparty, openingAmount, generic }

_BalanceAccountErrorField _balanceAccountErrorField(Object error) {
  if (error is DomainValidationException) {
    return switch (error.code) {
      'balance_account_name.required' => _BalanceAccountErrorField.name,
      'balance.opening_amount_negative' =>
        _BalanceAccountErrorField.openingAmount,
      'balance_counterparty_name.required' ||
      'balance_counterparty_name.blank' =>
        _BalanceAccountErrorField.counterparty,
      _ => _errorFieldFromMessage(error.message),
    };
  }
  return _errorFieldFromMessage(error.toString());
}

_BalanceAccountErrorField _errorFieldFromMessage(String raw) {
  final String message = raw.toLowerCase();
  if (message.contains('balance_counterparty_name') ||
      message.contains('counterparty_name')) {
    return _BalanceAccountErrorField.counterparty;
  }
  if (message.contains('balance_account_name')) {
    return _BalanceAccountErrorField.name;
  }
  if (message.contains('opening_amount')) {
    return _BalanceAccountErrorField.openingAmount;
  }
  return _BalanceAccountErrorField.generic;
}

String _localizedBalanceError(
  AppLocalizations strings,
  Object error, {
  String? fallback,
}) {
  if (error is AuthException) {
    return strings.balanceAuthenticationRequired;
  }
  if (error is DomainValidationException) {
    return switch (error.code) {
      'balance.close_requires_zero' => strings.balanceCannotCloseNonZero,
      'balance.account_not_found' => strings.balanceAccountMissing,
      'balance.movement_not_found' => strings.balanceMovementMissing,
      'balance.remaining_negative' => strings.balanceRemainingCannotBeNegative,
      'balance.opening_movement_failed' ||
      'balance.opening_movement_failed_rollback_failed' =>
        strings.balanceSaveAccountFailed,
      'amount.non_positive' => strings.balanceAmountGreaterThanZero,
      _ => fallback ?? strings.balanceSaveAccountFailed,
    };
  }
  final String message = error.toString().toLowerCase();
  if (message.contains('balance_counterparty_name') ||
      message.contains('counterparty_name')) {
    return strings.balanceCounterpartyInvalid;
  }
  if (message.contains('balance_account_name')) {
    return strings.balanceNameRequired;
  }
  return fallback ?? strings.balanceSaveAccountFailed;
}

void _showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.expense,
      content: Text(message),
    ),
  );
}

IconData _movementIcon(BalanceMovementType value) => switch (value) {
  BalanceMovementType.increase => Icons.add_circle_outline_rounded,
  BalanceMovementType.decrease => Icons.remove_circle_outline_rounded,
  BalanceMovementType.adjustment => Icons.tune_rounded,
};
