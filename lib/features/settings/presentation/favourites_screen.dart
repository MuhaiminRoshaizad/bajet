import '../../../core/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../../core/widgets/card_group.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../ledger/domain/ledger_models.dart';
import '../../ledger/presentation/category_visuals.dart';
import '../../ledger/presentation/ledger_providers.dart';

/// Shortcuts that fill in the logger. They never save anything themselves.
class FavouritesScreen extends ConsumerWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final favourites = ref.watch(favouritesProvider).value ?? const <Favourite>[];
    final categories = {for (final x in ref.watch(categoriesProvider).value ?? const <Category>[]) x.key: x};
    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, AppSpacing.xs, AppSpacing.m),
            child: Text('Tapping one in the logger fills in its amount and category. Nothing is saved until you press Log.', style: TextStyle(color: c.muted)),
          ),
          if (favourites.isNotEmpty)
            CardGroup(
              children: [
                for (final f in favourites)
                  ListTile(
                    minTileHeight: 60,
                    leading: CategoryBubble(categoryKey: f.categoryKey, tint: categoryTint(categories[f.categoryKey])),
                    title: Text(f.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(categories[f.categoryKey]?.label ?? f.categoryKey),
                    trailing: Text(Money.format(f.amount), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
                    onTap: () => _openForm(context, f),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.l),
          FilledButton.icon(
            onPressed: () => _openForm(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a favourite'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, Favourite? editing) => showAppSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _FavouriteForm(editing: editing, messenger: ScaffoldMessenger.of(context)),
      );
}

class _FavouriteForm extends ConsumerStatefulWidget {
  const _FavouriteForm({required this.editing, required this.messenger});

  final Favourite? editing;
  final ScaffoldMessengerState messenger;

  @override
  ConsumerState<_FavouriteForm> createState() => _FavouriteFormState();
}

class _FavouriteFormState extends ConsumerState<_FavouriteForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.editing?.label ?? '');
  late final _amount = TextEditingController(text: widget.editing == null ? '' : RinggitCentsFormatter.format(widget.editing!.amount));
  late String? _category = widget.editing?.categoryKey;
  bool _categoryMissing = false;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = _form.currentState!.validate();
    setState(() => _categoryMissing = _category == null);
    if (!ok || _category == null) return;
    final repo = ref.read(favouriteRepositoryProvider);
    final label = _name.text.trim();
    final amount = RinggitCentsFormatter.parse(_amount.text);
    final editing = widget.editing;
    if (editing == null) {
      final id = await repo.add(label: label, categoryKey: _category!, amount: amount);
      if (mounted) Navigator.of(context).pop();
      showBar(widget.messenger, 'Added $label', undo: () => repo.delete(id));
      return;
    }
    await repo.update(Favourite(id: editing.id, label: label, categoryKey: _category!, amount: amount));
    if (mounted) Navigator.of(context).pop();
    showBar(widget.messenger, 'Saved $label', undo: () => repo.update(editing));
  }

  Future<void> _remove() async {
    final f = widget.editing!;
    final confirmed = await confirmDelete(context, title: 'Remove ${f.label}?', message: 'Past entries stay as they are. Only the shortcut goes.', action: 'Remove');
    if (!confirmed) return;
    final repo = ref.read(favouriteRepositoryProvider);
    await repo.delete(f.id);
    if (!mounted) return;
    Navigator.of(context).pop();
    showBar(widget.messenger, 'Removed ${f.label}', undo: () => repo.add(label: f.label, categoryKey: f.categoryKey, amount: f.amount));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = [...?ref.watch(categoriesProvider).value?.where((x) => !x.isIncome && !x.isAutomatic)];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.editing == null ? 'New favourite' : 'Edit favourite', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.l),
              TextFormField(
                controller: _name,
                maxLength: 24,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteractionIfError,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Give it a name' : null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Coffee',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _amount,
                label: 'Usual amount',
                hint: 'e.g. 4.50',
                helper: 'You can still change it each time you log.',
                textInputAction: TextInputAction.done,
                validator: (sen) => sen > 0 ? null : 'Enter the usual amount',
              ),
              const SizedBox(height: AppSpacing.l),
              Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _categoryMissing ? c.bad : c.muted)),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final cat in categories)
                    ChoiceChip(
                      label: Text(cat.label),
                      avatar: Icon(categoryIcon(cat.key), size: 18),
                      selected: _category == cat.key,
                      onSelected: (_) => setState(() {
                        _category = cat.key;
                        _categoryMissing = false;
                      }),
                    ),
                ],
              ),
              if (_categoryMissing)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('Pick a category', style: TextStyle(color: c.bad, fontSize: 12)),
                ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text('Save favourite'),
              ),
              if (widget.editing != null) ...[
                const SizedBox(height: AppSpacing.s),
                TextButton(
                  onPressed: _remove,
                  style: TextButton.styleFrom(foregroundColor: c.bad, minimumSize: const Size.fromHeight(48)),
                  child: const Text('Remove favourite'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
