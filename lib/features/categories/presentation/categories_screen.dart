import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/hi_fi/hi_fi_bottom_sheet.dart';
import '../../../shared/hi_fi/hi_fi_button.dart';
import '../../../shared/hi_fi/hi_fi_card.dart';
import '../../../shared/hi_fi/hi_fi_category_row.dart';
import '../../../shared/hi_fi/hi_fi_filter_chip.dart';
import '../../../shared/hi_fi/hi_fi_icon_tile.dart';
import '../../../shared/hi_fi/hi_fi_input_field.dart';
import 'category_catalog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  CategoryKind _selectedKind = CategoryKind.expense;
  late List<CategoryPresentationData> _expenseCategories;
  late List<CategoryPresentationData> _incomeCategories;

  @override
  void initState() {
    super.initState();
    _expenseCategories = List<CategoryPresentationData>.of(
      expenseCategoryCatalog,
    );
    _incomeCategories = List<CategoryPresentationData>.of(
      incomeCategoryCatalog,
    );
  }

  List<CategoryPresentationData> get _activeCategories =>
      _selectedKind == CategoryKind.expense
      ? _expenseCategories
      : _incomeCategories;

  Future<void> _openEditor({CategoryPresentationData? category}) async {
    final TextEditingController controller = TextEditingController(
      text: category?.title ?? '',
    );
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
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
                          text: _selectedKind.label.toLowerCase(),
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
                    hint: _selectedKind == CategoryKind.expense
                        ? 'e.g. Packaging'
                        : 'e.g. Card Sales',
                    errorText: errorText,
                    autofocus: true,
                    onChanged: (_) {
                      if (errorText != null) {
                        setSheetState(() => errorText = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Usage and counts stay in place even when this screen has placeholder data.',
                    style: AppTypography.bodySoft.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: HiFiButton(
                          label: 'Cancel',
                          variant: HiFiButtonVariant.ghost,
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        flex: 16,
                        child: HiFiButton(
                          label: category == null
                              ? 'Save category'
                              : 'Save changes',
                          onPressed: () {
                            final String name = controller.text.trim();
                            if (name.isEmpty) {
                              setSheetState(
                                () => errorText =
                                    'Category name cannot be empty.',
                              );
                              return;
                            }

                            setState(() {
                              if (_selectedKind == CategoryKind.expense) {
                                _expenseCategories = _upsertCategory(
                                  _expenseCategories,
                                  category,
                                  name,
                                  HiFiIconTileTone.expense,
                                  Icons.sell_outlined,
                                );
                              } else {
                                _incomeCategories = _upsertCategory(
                                  _incomeCategories,
                                  category,
                                  name,
                                  HiFiIconTileTone.income,
                                  Icons.payments_outlined,
                                );
                              }
                            });
                            Navigator.of(sheetContext).pop();
                          },
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

  List<CategoryPresentationData> _upsertCategory(
    List<CategoryPresentationData> current,
    CategoryPresentationData? category,
    String name,
    HiFiIconTileTone tone,
    IconData icon,
  ) {
    if (category == null) {
      return <CategoryPresentationData>[
        ...current,
        CategoryPresentationData(
          title: name,
          icon: icon,
          tone: tone,
          entryCount: 0,
          monthlyTotalLabel: '£0',
        ),
      ];
    }

    return current
        .map(
          (CategoryPresentationData item) =>
              item == category ? item.copyWith(title: name) : item,
        )
        .toList();
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
            expenseCount: _expenseCategories.length,
            incomeCount: _incomeCategories.length,
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
          sliver: SliverToBoxAdapter(
            child: HiFiCard.flush(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < _activeCategories.length; i++)
                    HiFiCategoryRow(
                      icon: _activeCategories[i].icon,
                      tone: _activeCategories[i].tone,
                      title: _activeCategories[i].title,
                      meta: _activeCategories[i].metaLabel,
                      showDivider: i != _activeCategories.length - 1,
                      onTap: () => _openEditor(category: _activeCategories[i]),
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
    return DecoratedBox(
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
    );
  }

  @override
  bool shouldRebuild(covariant _CategorySwitchHeaderDelegate oldDelegate) {
    return selectedKind != oldDelegate.selectedKind ||
        expenseCount != oldDelegate.expenseCount ||
        incomeCount != oldDelegate.incomeCount;
  }
}
