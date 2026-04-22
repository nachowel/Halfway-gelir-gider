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
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import '../../../shared/hi_fi/hi_fi_list_row.dart';
import '../../../shared/overlay/app_overlay.dart';

class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  String? _selectedCategoryFilterId;

  AsyncValue<List<CategoryData>> get _categoriesState =>
      ref.watch(expenseCategoriesProvider);

  AsyncValue<List<SupplierData>> get _suppliersState =>
      ref.watch(suppliersProvider(SuppliersQuery(
        expenseCategoryId: _selectedCategoryFilterId,
      )));

  Future<void> _openEditor({SupplierData? supplier}) async {
    final List<CategoryData> categories =
        _categoriesState.asData?.value ?? const <CategoryData>[];
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.expense,
          content: Text(context.strings.noCategoriesCreateInSettings),
        ),
      );
      return;
    }

    await showAppModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SupplierEditorSheet(
        supplier: supplier,
        categories: categories,
        initialCategoryId:
            supplier?.expenseCategoryId ?? _selectedCategoryFilterId,
      ),
    );
  }

  Widget _buildCategoryFilters(List<CategoryData> categories) {
    final AppLocalizations strings = context.strings;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenSide),
      child: Row(
        children: <Widget>[
          HiFiFilterChip(
            label: strings.all,
            selected: _selectedCategoryFilterId == null,
            onTap: () => setState(() => _selectedCategoryFilterId = null),
          ),
          const SizedBox(width: 6),
          for (final CategoryData category in categories) ...<Widget>[
            HiFiFilterChip(
              label: category.name,
              selected: _selectedCategoryFilterId == category.id,
              onTap: () =>
                  setState(() => _selectedCategoryFilterId = category.id),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildBody() {
    final AppLocalizations strings = context.strings;
    return _suppliersState.when(
      data: (List<SupplierData> suppliers) {
        if (suppliers.isEmpty) {
          return HiFiCard.flush(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(strings.noSuppliersYet, style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    strings.addSupplier,
                    style: AppTypography.bodySoft.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HiFiButton(
                    label: strings.addSupplier,
                    onPressed: _openEditor,
                  ),
                ],
              ),
            ),
          );
        }

        return HiFiCard.flush(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < suppliers.length; i++)
                HiFiListRow(
                  key: ValueKey<String>('supplier-row-${suppliers[i].id}'),
                  leading: const Icon(
                    Icons.store_outlined,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                  title: suppliers[i].name,
                  meta: suppliers[i].expenseCategoryName,
                  onTap: () => _openEditor(supplier: suppliers[i]),
                  showDivider: i != suppliers.length - 1,
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace _) => HiFiCard.flush(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.categoriesLoadError(strings.suppliers),
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(error.toString(), style: AppTypography.bodySoft),
              const SizedBox(height: AppSpacing.md),
              HiFiButton(
                label: strings.tryAgain,
                onPressed: () => ref.invalidate(suppliersProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final List<CategoryData> categories =
        _categoriesState.asData?.value ?? const <CategoryData>[];

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
                Row(
                  children: <Widget>[
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => context.pop(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 2,
                        ),
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
                              strings.settings,
                              style: AppTypography.bodySoft.copyWith(
                                fontSize: 13,
                              ),
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
                        key: const ValueKey<String>('supplier-add-action'),
                        onTap: _openEditor,
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
                                strings.newLabel,
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
                RichText(
                  text: TextSpan(
                    style: AppTypography.h1,
                    children: <InlineSpan>[
                      TextSpan(
                        text: strings.suppliers,
                        style: AppTypography.h1.copyWith(
                          color: AppColors.brand,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(strings.selectCategory, style: AppTypography.lbl),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _buildCategoryFilters(categories)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenSide,
            AppSpacing.sm,
            AppSpacing.screenSide,
            120,
          ),
          sliver: SliverToBoxAdapter(child: _buildBody()),
        ),
      ],
    );
  }
}

class _SupplierEditorSheet extends ConsumerStatefulWidget {
  const _SupplierEditorSheet({
    required this.supplier,
    required this.categories,
    required this.initialCategoryId,
  });

  final SupplierData? supplier;
  final List<CategoryData> categories;
  final String? initialCategoryId;

  @override
  ConsumerState<_SupplierEditorSheet> createState() =>
      _SupplierEditorSheetState();
}

class _SupplierEditorSheetState
    extends ConsumerState<_SupplierEditorSheet> {
  late final TextEditingController _nameController;
  String? _selectedCategoryId;
  String? _nameError;
  String? _categoryError;
  bool _saving = false;
  bool _archiving = false;

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    final String? initial =
        widget.initialCategoryId ?? widget.supplier?.expenseCategoryId;
    if (initial != null &&
        widget.categories.any((CategoryData c) => c.id == initial)) {
      _selectedCategoryId = initial;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.expense,
        content: Text(message),
      ),
    );
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.income,
        duration: const Duration(milliseconds: 1400),
        content: Text(message),
      ),
    );
  }

  Future<void> _save() async {
    final AppLocalizations strings = context.strings;
    final String name = _nameController.text.trim();
    final String? categoryId = _selectedCategoryId;

    setState(() {
      _nameError = name.isEmpty ? strings.supplierNameIsRequired : null;
      _categoryError = categoryId == null ? strings.categoryIsRequired : null;
    });
    if (_nameError != null || _categoryError != null) {
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(giderRepositoryProvider).saveSupplier(
            id: widget.supplier?.id,
            draft: SupplierDraft(
              expenseCategoryId: categoryId!,
              name: name,
            ),
          );
      ref.read(refreshKeyProvider.notifier).state++;
      ref.invalidate(suppliersProvider);
      ref.invalidate(activeSuppliersProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSuccessSnack(
        _isEditing ? strings.supplierUpdated : strings.supplierAdded,
      );
    } on DomainValidationException catch (error) {
      if (error.code == 'supplier.duplicate_name') {
        setState(() => _nameError = strings.supplierDuplicateInCategory);
      } else {
        _showErrorSnack(error.message);
      }
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        setState(() => _nameError = strings.supplierDuplicateInCategory);
      } else {
        _showErrorSnack(error.message);
      }
    } on AuthException catch (error) {
      _showErrorSnack(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final AppLocalizations strings = context.strings;
    final SupplierData? supplier = widget.supplier;
    if (supplier == null) return;
    setState(() => _archiving = true);
    try {
      await ref
          .read(giderRepositoryProvider)
          .archiveSupplier(id: supplier.id);
      ref.read(refreshKeyProvider.notifier).state++;
      ref.invalidate(suppliersProvider);
      ref.invalidate(activeSuppliersProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      _showSuccessSnack(strings.supplierArchived);
    } on DomainValidationException catch (error) {
      _showErrorSnack(error.message);
    } on AuthException catch (error) {
      _showErrorSnack(error.message);
    } finally {
      if (mounted) setState(() => _archiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = context.strings;
    final bool busy = _saving || _archiving;

    return HiFiBottomSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _isEditing
                ? strings.editSupplier.toUpperCase()
                : strings.addSupplier.toUpperCase(),
            style: AppTypography.eye,
          ),
          const SizedBox(height: 4),
          Text(
            _isEditing ? strings.editSupplier : strings.addSupplier,
            style: AppTypography.h2,
          ),
          const SizedBox(height: AppSpacing.md),
          HiFiInputField(
            key: const ValueKey<String>('supplier-name-field'),
            controller: _nameController,
            label: strings.supplierName,
            errorText: _nameError,
            readOnly: busy,
            onChanged: (_) {
              if (_nameError != null) {
                setState(() => _nameError = null);
              }
            },
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(strings.selectCategory, style: AppTypography.lbl),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final CategoryData category in widget.categories)
                HiFiFilterChip(
                  label: category.name,
                  selected: _selectedCategoryId == category.id,
                  onTap: busy
                      ? () {}
                      : () {
                          setState(() {
                            _selectedCategoryId = category.id;
                            _categoryError = null;
                          });
                        },
                ),
            ],
          ),
          if (_categoryError != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _categoryError!,
              style: AppTypography.meta.copyWith(color: AppColors.expense),
            ),
          ],
          if (_isEditing) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            HiFiButton(
              key: const ValueKey<String>('supplier-archive-button'),
              label: strings.archiveSupplier,
              variant: HiFiButtonVariant.expense,
              loading: _archiving,
              onPressed: busy ? null : _archive,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: HiFiButton(
                  label: strings.cancel,
                  variant: HiFiButtonVariant.ghost,
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 16,
                child: HiFiButton(
                  key: const ValueKey<String>('supplier-save-button'),
                  label: _isEditing ? strings.saveChanges : strings.save,
                  loading: _saving,
                  onPressed: busy ? null : _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
