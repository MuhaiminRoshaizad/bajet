import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/money_field.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/account_models.dart';
import '../domain/known_providers.dart';
import 'account_providers.dart';
import 'card_face.dart';
import 'card_palette.dart';

/// Changes how [account]'s card looks: its finish, colour and nickname. Its
/// balance changes only through what is logged.
Future<void> showCardDesigner(BuildContext context, Account account) => _open(context, _CardDesigner(account: account));

/// Changes how the total card looks.
Future<void> showTotalCardDesigner(BuildContext context) => _open(context, const _CardDesigner());

/// Asks what kind of account to add, then opens it in the designer with what
/// it holds now.
Future<void> showAddAccount(BuildContext context) async {
  final kind = await showModalBottomSheet<AccountKind>(context: context, useSafeArea: true, builder: (_) => const _KindChooser());
  if (kind != null && context.mounted) await _open(context, _CardDesigner(newKind: kind));
}

class _KindChooser extends StatelessWidget {
  const _KindChooser();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Add an account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.l),
          Row(children: [
            for (final (kind, label, icon) in const [
              (AccountKind.cash, 'Cash', Icons.payments_outlined),
              (AccountKind.bank, 'Bank account', Icons.account_balance_outlined),
              (AccountKind.ewallet, 'E-wallet', Icons.phone_iphone_outlined),
            ]) ...[
              if (kind != AccountKind.cash) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(kind),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 96), padding: const EdgeInsets.all(AppSpacing.s)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(height: AppSpacing.xs), Text(label, textAlign: TextAlign.center)]),
                ),
              ),
            ],
          ]),
        ]),
      );
}

Future<void> _open(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => sheet);

class _CardDesigner extends ConsumerStatefulWidget {
  /// With neither, it designs the total card.
  const _CardDesigner({this.account, this.newKind});

  /// The account being restyled.
  final Account? account;

  /// The kind of account being added.
  final AccountKind? newKind;

  @override
  ConsumerState<_CardDesigner> createState() => _CardDesignerState();
}

class _CardDesignerState extends ConsumerState<_CardDesigner> {
  late final Account? _account = widget.account;
  late final AccountKind? _newKind = widget.newKind;
  late final CardLook? _start = _newKind == null ? null : startingSwatch(_newKind, '').look(_newKind == AccountKind.cash ? CardFinish.leather : CardFinish.brushed);
  late int? _color = _account?.look.color ?? _start?.color ?? ref.read(totalCardLookProvider).value?.color;
  late int? _ink = _account?.look.ink ?? _start?.ink;
  late CardFinish _finish = _account?.look.finish ?? _start?.finish ?? ref.read(totalCardLookProvider).value?.finish ?? CardFinish.brushed;
  late final _nickname = TextEditingController(text: _account?.nickname);
  final _provider = TextEditingController();
  final _balance = TextEditingController();
  late String _name = _newKind == AccountKind.cash ? 'Cash' : '';
  bool _tried = false;

  AccountKind? get _kind => _account?.kind ?? _newKind;
  bool get _isCash => _kind == AccountKind.cash;
  bool get _isTotal => _kind == null;

  /// A bank or e-wallet being added still needs its name.
  bool get _asksProvider => _newKind != null && _newKind != AccountKind.cash;

  @override
  void initState() {
    super.initState();
    // The preview shows the balance as it is typed.
    _balance.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nickname.dispose();
    _provider.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _choose(String provider) => setState(() {
        _name = provider;
        _provider.text = provider;
        final swatch = startingSwatch(_newKind!, provider);
        _color = swatch.color;
        _ink = swatch.ink;
      });

  void _pick(CardSwatch? swatch) => setState(() {
        _color = swatch?.color;
        _ink = swatch?.ink;
      });

  Future<void> _save() async {
    final repo = ref.read(accountRepositoryProvider);
    if (_newKind case final kind?) {
      setState(() => _tried = true);
      if (_name.trim().isEmpty) return;
      await repo.addAccount(AccountDraft(
        kind: kind,
        name: _name,
        nickname: _nickname.text,
        balance: RinggitCentsFormatter.parse(_balance.text),
        look: CardLook(color: _color!, ink: _ink, finish: _finish),
      ));
    } else if (_account case final account?) {
      await repo.updateAccount(account.copyWith(nickname: () => _nickname.text, look: CardLook(color: _color!, ink: _ink, finish: _finish)));
    } else {
      await repo.saveTotalLook(TotalCardLook(color: _color, finish: _finish));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _newKind;
    final account = kind == null
        ? _account
        : Account(
            id: 0,
            kind: kind,
            name: _name.trim().isEmpty ? (kind == AccountKind.bank ? 'Your bank' : 'Your e-wallet') : _name.trim(),
            openingBalance: 0,
            balance: RinggitCentsFormatter.parse(_balance.text),
            look: CardLook(color: _color!, ink: _ink, finish: _finish),
          );
    final swatches = _isCash ? leatherSwatches : cardSwatches;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isTotal ? 'Total card' : kind == null ? 'Edit card' : 'Add ${kind == AccountKind.cash ? 'cash' : kind == AccountKind.bank ? 'a bank account' : 'an e-wallet'}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            if (_isTotal) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Only how it looks. It always shows every account together.', style: TextStyle(color: context.colors.muted)),
            ],
            // Room above the preview for a wallet's bills.
            SizedBox(height: _isCash ? AppSpacing.xxxl : AppSpacing.l),
            if (account == null)
              TotalCard(
                look: TotalCardLook(color: _color, finish: _finish),
                balance: ref.watch(balanceProvider).value,
                accounts: ref.watch(accountsProvider).value ?? const [],
              )
            else
              AccountCard(account: account.copyWith(nickname: () => _nickname.text.trim().isEmpty ? null : _nickname.text.trim(), look: CardLook(color: _color!, ink: _ink, finish: _finish))),
            if (_asksProvider) ...[
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: _provider,
                textCapitalization: TextCapitalization.words,
                onChanged: (v) => setState(() => _name = v),
                decoration: InputDecoration(
                  labelText: kind == AccountKind.bank ? 'Which bank?' : 'Which e-wallet?',
                  hintText: 'Search, or type its name',
                  errorText: _tried && _name.trim().isEmpty ? 'Choose one, or type its name' : null,
                ),
              ),
              _ProviderList(kind: kind!, query: _provider.text, chosen: _name, onChoose: _choose),
            ],
            if (!_isCash) ...[
              const SizedBox(height: AppSpacing.l),
              const _Label('Finish'),
              Wrap(spacing: AppSpacing.s, children: [
                for (final f in cardFinishes)
                  ChoiceChip(label: Text(finishLabel(f)), selected: _finish == f, onSelected: (_) => setState(() => _finish = f)),
              ]),
            ],
            const SizedBox(height: AppSpacing.l),
            _Label(_isCash ? 'Leather' : 'Colour'),
            Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
              if (_isTotal) _Swatch(name: 'Match the app', selected: _color == null, onTap: () => _pick(null)),
              for (final s in swatches) _Swatch(name: s.name, color: Color(s.color), selected: _color == s.color && _ink == s.ink, onTap: () => _pick(s)),
            ]),
            if (!_isTotal) ...[
              const SizedBox(height: AppSpacing.l),
              TextField(
                controller: _nickname,
                maxLength: 24,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Nickname (optional)', hintText: 'e.g. Savings', counterText: ''),
              ),
            ],
            if (kind != null) ...[
              const SizedBox(height: AppSpacing.m),
              MoneyField(
                controller: _balance,
                label: 'How much is in it now',
                hint: 'e.g. 1,250.00',
                helper: 'Leave it empty for RM0.00.',
                textInputAction: TextInputAction.done,
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(_isTotal ? 'Save total card' : kind == null ? 'Save card' : 'Add account')),
          ],
        ),
      ),
    );
  }
}

/// Up to five providers matching what has been typed, and the typed name
/// itself when it matches none. Hidden once one is chosen.
class _ProviderList extends StatelessWidget {
  const _ProviderList({required this.kind, required this.query, required this.chosen, required this.onChoose});

  final AccountKind kind;
  final String query;
  final String chosen;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final typed = query.trim();
    final matches = providersMatching(kind, typed);
    if (matches.contains(chosen) && chosen == typed) return const SizedBox.shrink();
    final exact = matches.any((m) => m.toLowerCase() == typed.toLowerCase());
    return Column(children: [
      for (final p in matches.take(5)) ListTile(dense: true, title: Text(p), onTap: () => onChoose(p)),
      if (typed.isNotEmpty && !exact) ListTile(dense: true, leading: const Icon(Icons.add), title: Text('Use “$typed”'), onTap: () => onChoose(typed)),
    ]);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.s),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.colors.muted)),
      );
}

/// One colour to pick, 48 dp to tap. Without a colour it is "Match the
/// app", drawn half light and half dark.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.selected, required this.onTap, this.color});

  final String name;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkResponse(
          onTap: onTap,
          radius: 26,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  gradient: color == null ? LinearGradient(colors: [c.ink, c.ink, c.background, c.background], stops: const [0, 0.5, 0.5, 1]) : null,
                  border: Border.all(color: selected ? c.primary : c.line, width: selected ? 3 : 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
