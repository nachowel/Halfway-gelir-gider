import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers/app_providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/domain/types.dart' show DomainValidationException;
import '../../../data/app_models.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_category_row.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import 'category_catalog.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_GB',
    symbol: '£',
    decimalDigits: 0,
  );

  CategoryKind _selectedKind = CategoryKind.expense;

  AsyncValue<List<CategoryData>> get _expenseState =>
      ref.watch(expenseCategoriesProvider);

  AsyncValue<List<CategoryData>> get _incomeState =>
      ref.watch(incomeCategoriesProvider);

  AsyncValue<List<CategoryData>> get _activeState =>
      _selectedKind == CategoryKind.expense ? _expenseState : _incomeState;

  CategoryType get _activeType => _selectedKind == CategoryKind.expense
      ? CategoryType.expense
      : CategoryType.income;

  int get _expenseCount => _expenseState.asData?.value.length ?? 0;

  int get _incomeCount => _incomeState.asData?.value.length ?? 0;

  Future<void> _openEditor({CategoryData? category}) async {
    final TextEditingController controller = TextEditingController(
      text: category?.name ?? '',
    );
    String? errorText;
    bool saving = false;
    bool archiving = false;
    final CategoryType categoryType = category?.type ?? _activeType;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final NavigatorState navigator = Navigator.of(sheetContext);

            Future<void> save() async {
              final String name = controller.text.trim();
              if (name.isEmpty) {
                setSheetState(
                  () => errorText = 'Category name cannot be empty.',
                );
                return;
              }

              setSheetState(() => saving = true);
              try {
                await ref
                    .read(giderRepositoryProvider)
                    .saveCategory(
                      id: category?.id,
                      type: categoryType,
                      name: name,
                    );
                ref.read(refreshKeyProvider.notifier).state++;
                if (!mounted) {
                  return;
                }
                navigator.pop();
              } on DomainValidationException catch (error) {
                setSheetState(() => errorText = error.message);
              } on AuthException catch (error) {
                _showErrorSnack(error.message);
              } finally {
                if (mounted) {
                  setSheetState(() => saving = false);
                }
              }
            }

            Future<void> archive() async {
              if (category == null) {
                return;
              }

              setSheetState(() => archiving = true);
              try {
                await ref
                    .read(giderRepositoryProvider)
                    .archiveCategory(id: category.id);
                ref.read(refreshKeyProvider.notifier).state++;
                if (!mounted) {
                  return;
                }
                navigator.pop();
              } on DomainValidationException catch (error) {
                _showErrorSnack(error.message);
              } on AuthException catch (error) {
                _showErrorSnack(error.message);
              } finally {
                if (mounted) {
                  setSheetState(() => archiving = false);
                }
              }
            }

            final bool busy = saving || archiving;

            return HiFiBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    category == null ? 'NEW CATEGORY' : 'EDIT CATEGORY',
                    style: AppTypography.eye,
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: AppTypography.h2,
                      children: <InlineSpan>[
                        TextSpan(
                          text: category == null ? 'Create ' : 'Rename ',
                        ),
                        TextSpan(
                          text: categoryType.label.toLowerCase(),
                          style: AppTypography.h2.copyWith(
                            color: AppColors.brand,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const TextSpan(text: ' category'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HiFiInputField(
                    controller: controller,
                    label: 'Name',
                    hint: categoryType == CategoryType.expense
                        ? 'e.g. Packaging'
                        : 'e.g. Card Sales',
                    errorText: errorText,
                    autofocus: false,
                    readOnly: busy,
                    onChanged: (_) {
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
                    },
                    onSubmitted: (_) => save(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    category == null
                        ? 'New categories appear immediately in the management list.'
                        : '${category.entryCount} entries · ${_formatCurrency(category.monthlyTotalMinor)} this month',
                    style: AppTypography.bodySoft.copyWith(height: 1.45),
                  ),
                  if (category != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    HiFiButton(
                      label: 'Archive category',
                      variant: HiFiButtonVariant.expense,
                      loading: archiving,
                      onPressed: busy ? null : archive,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: HiFiButton(
                          label: 'Cancel',
                          variant: HiFiButtonVariant.ghost,
                          onPressed: busy
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 16,
                        child: HiFiButton(
                          label: category == null
                              ? 'Save category'
                              : 'Save changes',
                          loading: saving,
                          onPressed: busy ? null : save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    controller.dispose();
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

  void _retryActiveList() {
    if (_selectedKind == CategoryKind.expense) {
      ref.invalidate(expenseCategoriesProvider);
    } else {
      ref.invalidate(incomeCategoriesProvider);
    }
  }

  String _formatCurrency(int amountMinor) {
    return _currencyFormatter.format(amountMinor / 100);
  }

  Widget _buildActiveBody() {
    return _activeState.when(
      data: (List<CategoryData> categories) {
        if (categories.isEmpty) {
          return HiFiCard.flush(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('No categories yet', style: AppTypography.h2),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Create your first ${_activeType.label.toLowerCase()} category for this business.',
                    style: AppTypography.bodySoft.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HiFiButton(label: 'Create category', onPressed: _openEditor),
                ],
              ),
            ),
          );
        }

        return HiFiCard.flush(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < categories.length; i++)
                HiFiCategoryRow(
                  icon: categories[i].icon,
                  tone: categories[i].tone,
                  title: categories[i].name,
                  meta:
                      '${categories[i].entryCount} entries · ${_formatCurrency(categories[i].monthlyTotalMinor)} this month',
                  showDivider: i != categories.length - 1,
                  onTap: () => _openEditor(category: categories[i]),
                ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object error, StackTrace stackTrace) => HiFiCard.flush(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('We could not load categories.', style: AppTypography.h2),
              const SizedBox(height: AppSpacing.xs),
              Text(error.toString(), style: AppTypography.bodySoft),
              const SizedBox(height: AppSpacing.md),
              HiFiButton(label: 'Try again', onPressed: _retryActiveList),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              'Settings',
                              style: AppTypography.bodySoft.copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _ActionPill(label: 'New', onTap: _openEditor),
                  ],
                ),
                const SizedBox(height: AppSpacing.smTight),
                RichText(
                  text: TextSpan(
                    style: AppTypography.h1,
                    children: <InlineSpan>[
                      TextSpan(
                        text: 'Categories',
                        style: AppTypography.h1.copyWith(
                          color: AppColors.brand,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage expense and income tags',
                  style: AppTypography.lbl,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _CategorySwitchHeaderDelegate(
            selectedKind: _selectedKind,
            expenseCount: _expenseCount,
            incomeCount: _incomeCount,
            onSelected: (CategoryKind value) {
              setState(() => _selectedKind = value);
            },
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenSide,
            AppSpacing.sm,
            AppSpacing.screenSide,
            120,
          ),
          sliver: SliverToBoxAdapter(child: _buildActiveBody()),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.add_rounded, size: 14, color: AppColors.onInk),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.meta.copyWith(
                  color: AppColors.onInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySwitchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CategorySwitchHeaderDelegate({
    required this.selectedKind,
    required this.expenseCount,
    required this.incomeCount,
    required this.onSelected,
  });

  final CategoryKind selectedKind;
  final int expenseCount;
  final int incomeCount;
  final ValueChanged<CategoryKind> onSelected;

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenCream,
          boxShadow: overlapsContent
              ? <BoxShadow>[
                  BoxShadow(
                    color: AppColors.bg.withValues(alpha: 0.92),
                    blurRadius: 18,
                    spreadRadius: 6,
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenSide,
            6,
            AppSpacing.screenSide,
            8,
          ),
          child: Row(
            children: <Widget>[
              HiFiFilterChip(
                label: 'Expense · $expenseCount',
                selected: selectedKind == CategoryKind.expense,
                onTap: () => onSelected(CategoryKind.expense),
              ),
              const SizedBox(width: 6),
              HiFiFilterChip(
                label: 'Income · $incomeCount',
                selected: selectedKind == CategoryKind.income,
                onTap: () => onSelected(CategoryKind.income),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategorySwitchHeaderDelegate oldDelegate) {
    return selectedKind != oldDelegate.selectedKind ||
        expenseCount != oldDelegate.expenseCount ||
        incomeCount != oldDelegate.incomeCount;
  }
}
