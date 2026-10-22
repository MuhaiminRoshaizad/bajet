import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/validation/ringgit_cents_formatter.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/done_bar.dart';
import '../../../core/widgets/money_field.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/account_models.dart';
import '../domain/photo_colours.dart';
import 'account_providers.dart';
import 'card_face.dart';
import 'card_palette.dart';
import 'delete_account.dart';
import 'photo_match_screen.dart';
import 'provider_picker.dart';

/// Changes how [account]'s card looks: its finish, colour and nickname. Its
/// balance changes only through what is logged. Returns the user's choice
/// when they asked to delete the account instead; the caller deletes it once
/// it has closed whatever showed the card.
Future<DeleteChoice?> showCardDesigner(BuildContext context, Account account) =>
    showModalBottomSheet<DeleteChoice>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => _CardDesigner(account: account));

/// Changes how the total card looks.
Future<void> showTotalCardDesigner(BuildContext context) => _open(context, const _CardDesigner());

/// Asks what kind of account to add, then opens it in the designer with what
/// it holds now.
Future<void> showAddAccount(BuildContext context) async {
  final kind = await showModalBottomSheet<AccountKind>(context: context, useSafeArea: true, builder: (_) => const _KindChooser());
  if (kind != null && context.mounted) await showNewAccount(context, kind);
}

/// Opens a new account of [kind] in the designer.
Future<void> showNewAccount(BuildContext context, AccountKind kind) => _open(context, _CardDesigner(newKind: kind));

class _KindChooser extends StatelessWidget {
  const _KindChooser();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Add an account', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.l),
          AccountKindTiles(onPick: (kind) => Navigator.of(context).pop(kind)),
        ]),
      );
}

/// Cash, a bank account or an e-wallet, as three large tiles.
class AccountKindTiles extends StatelessWidget {
  const AccountKindTiles({super.key, required this.onPick});

  final ValueChanged<AccountKind> onPick;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final (kind, label, icon) in const [
          (AccountKind.cash, 'Cash', Icons.payments_outlined),
          (AccountKind.bank, 'Bank account', Icons.account_balance_outlined),
          (AccountKind.ewallet, 'E-wallet', Icons.phone_iphone_outlined),
        ]) ...[
          if (kind != AccountKind.cash) const SizedBox(width: AppSpacing.s),
          Expanded(
            child: OutlinedButton(
              onPressed: () => onPick(kind),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 96), padding: const EdgeInsets.all(AppSpacing.s)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(height: AppSpacing.xs), Text(label, textAlign: TextAlign.center)]),
            ),
          ),
        ],
      ]);
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
  late final CardLook? _start = _newKind == null ? null : startingSwatch(_newKind, '').look(_newKind == AccountKind.cash ? CardFinish.leather : CardFinish.matte);
  late int? _color = _account?.look.color ?? _start?.color ?? ref.read(totalCardLookProvider).value?.color;
  late int? _ink = _account?.look.ink ?? _start?.ink;
  late CardFinish _finish = _account?.look.finish ?? _start?.finish ?? ref.read(totalCardLookProvider).value?.finish ?? CardFinish.matte;
  late final _nickname = TextEditingController(text: _account?.nickname);
  late final _provider = TextEditingController(text: _account?.name);
  final _balance = TextEditingController();
  late String _name = _account?.name ?? (_newKind == AccountKind.cash ? 'Cash' : '');

  bool _tried = false;

  /// How far the preview is turned by a finger dragged across it.
  double _tilt = 0;

  AccountKind? get _kind => _account?.kind ?? _newKind;
  bool get _isCash => _kind == AccountKind.cash;
  bool get _isTotal => _kind == null;

  /// A bank or e-wallet names its provider; an upgrade's "Main account" is
  /// renamed here to the bank it really is.
  bool get _asksProvider => !_isTotal && !_isCash;

  @override
  void initState() {
    super.initState();
    // The preview shows the balance as it is typed, and a provider's name
    // whether it is picked or typed.
    _balance.addListener(() => setState(() {}));
    _provider.addListener(() {
      if (_provider.text != _name) setState(() => _name = _provider.text);
    });
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
        // A new card starts near the provider's colour; one being edited
        // keeps the colour the user gave it.
        if (_newKind case final kind?) {
          final swatch = startingSwatch(kind, provider);
          _color = swatch.color;
          _ink = swatch.ink;
        }
      });

  void _pick(CardSwatch? swatch) => setState(() {
        _color = swatch?.color;
        _ink = swatch?.ink;
      });

  Future<void> _match() async {
    final source = await showModalBottomSheet<PhotoSource>(context: context, useSafeArea: true, builder: (_) => const _PhotoSourceChooser());
    if (source == null || !mounted) return;
    final photo = await ref.read(photoColoursProvider).pick(source);
    if (photo == null || !mounted) return;
    final colour = await showPhotoMatch(context, photo);
    if (colour == null || !mounted) return;
    setState(() {
      _color = colour;
      _ink = null;
    });
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(accountRepositoryProvider);
    final nickname = _nickname.text.trim();
    final called = nickname.isEmpty ? _name.trim() : nickname;
    if (_newKind case final kind?) {
      setState(() => _tried = true);
      if (_name.trim().isEmpty) return;
      final id = await repo.addAccount(AccountDraft(
        kind: kind,
        name: _name,
        nickname: _nickname.text,
        balance: RinggitCentsFormatter.parse(_balance.text),
        look: CardLook(color: _color!, ink: _ink, finish: _finish),
      ));
      if (mounted) Navigator.of(context).pop();
      showBar(messenger, 'Added $called', undo: () => repo.deleteAccount(id));
    } else if (_account case final account?) {
      setState(() => _tried = true);
      if (_name.trim().isEmpty) return;
      await repo.updateAccount(account.copyWith(name: _name, nickname: () => _nickname.text, look: CardLook(color: _color!, ink: _ink, finish: _finish)));
      if (mounted) Navigator.of(context).pop();
      showBar(messenger, "Saved $called's card", undo: () => repo.updateAccount(account));
    } else {
      final before = ref.read(totalCardLookProvider).value;
      await repo.saveTotalLook(TotalCardLook(color: _color, finish: _finish));
      if (mounted) Navigator.of(context).pop();
      showBar(messenger, 'Saved the total card', undo: before == null ? null : () => repo.saveTotalLook(before));
    }
  }

  /// Delete, below Save. The last account stays, since there must always be
  /// one to log to.
  List<Widget> _delete(Account account) {
    final all = ref.watch(accountsProvider).value ?? const <Account>[];
    final last = all.length < 2;
    return [
      const SizedBox(height: AppSpacing.s),
      DeleteButton(label: 'Delete account', onPressed: last ? null : () => _askDelete(account, all)),
      if (last) ...[
        const SizedBox(height: AppSpacing.xs),
        Text("It's your only account. Add another before deleting this one.", textAlign: TextAlign.center, style: TextStyle(color: context.colors.muted, fontSize: 12)),
      ],
    ];
  }

  Future<void> _askDelete(Account account, List<Account> all) async {
    final choice = await askDeleteAccount(context, ref.read(accountRepositoryProvider), account, all);
    if (choice != null && mounted) Navigator.of(context).pop(choice);
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
    // In the order it is filled in: which one, what is in it, its nickname,
    // then how it looks. Add stays pinned below, always in reach.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.l),
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
                // Dragging a finger across the preview turns it, to see how a
                // mirror or pearl finish catches the light.
                LayoutBuilder(
                  builder: (context, box) => GestureDetector(
                    onHorizontalDragUpdate: (d) => setState(() => _tilt = (d.localPosition.dx / box.maxWidth * 2 - 1).clamp(-1.0, 1.0)),
                    child: account == null
                        ? TotalCard(
                            look: TotalCardLook(color: _color, finish: _finish),
                            balance: ref.watch(balanceProvider).value,
                            accounts: ref.watch(accountsProvider).value ?? const [],
                            tilt: _tilt,
                          )
                        : AccountCard(
                            account: account.copyWith(
                              name: _name.trim().isEmpty ? null : _name.trim(),
                              nickname: () => _nickname.text.trim().isEmpty ? null : _nickname.text.trim(),
                              look: CardLook(color: _color!, ink: _ink, finish: _finish),
                            ),
                            tilt: _tilt,
                          ),
                  ),
                ),
                if (_asksProvider) ...[
                  const SizedBox(height: AppSpacing.l),
                  ProviderPicker(
                    kind: _kind!,
                    controller: _provider,
                    onChoose: _choose,
                    errorText: _tried && _name.trim().isEmpty ? 'Choose one, or search for its name' : null,
                  ),
                ],
                if (kind != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  MoneyField(
                    controller: _balance,
                    label: 'How much is in it now',
                    hint: 'e.g. 1,250.00',
                    helper: 'Leave it empty for RM0.00.',
                    textInputAction: TextInputAction.next,
                  ),
                ],
                if (!_isTotal) ...[
                  const SizedBox(height: AppSpacing.m),
                  TextField(
                    autofillHints: null,
                    controller: _nickname,
                    maxLength: 24,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Nickname (optional)', hintText: 'e.g. Savings', counterText: ''),
                  ),
                ],
                const SizedBox(height: AppSpacing.l),
                const _Label('Finish'),
                Wrap(spacing: AppSpacing.s, runSpacing: AppSpacing.xs, children: [
                  for (final f in _isCash ? walletFinishes : cardFinishes)
                    ChoiceChip(label: Text(finishLabel(f)), selected: _finish == f, onSelected: (_) => setState(() => _finish = f)),
                ]),
                const SizedBox(height: AppSpacing.l),
                const _Label('Colour'),
                Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                  if (_isTotal) _Swatch(name: 'Match the app', selected: _color == null, onTap: () => _pick(null)),
                  for (final s in swatches) _Swatch(name: s.name, color: Color(s.color), selected: _color == s.color && _ink == s.ink, onTap: () => _pick(s)),
                ]),
                const SizedBox(height: AppSpacing.s),
                Row(children: [
                  TextButton.icon(
                    onPressed: _match,
                    icon: const Icon(Icons.colorize_outlined),
                    label: Text(_isTotal ? 'Match a photo' : _isCash ? 'Match my wallet' : 'Match my card'),
                  ),
                  Expanded(child: Text("The photo isn't kept.", style: TextStyle(color: context.colors.muted, fontSize: 12))),
                ]),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.s, AppSpacing.xl, AppSpacing.l),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            FilledButton(onPressed: _save, child: Text(_isTotal ? 'Save total card' : kind == null ? 'Save card' : 'Add account')),
            if (_account case final editing?) ..._delete(editing),
          ]),
        ),
      ]),
    );
  }
}

/// Where the photo comes from, as two large buttons.
class _PhotoSourceChooser extends StatelessWidget {
  const _PhotoSourceChooser();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Match the colour', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text("Take or choose a photo of it. Only the colour you pick is saved; the photo isn't kept.", style: TextStyle(color: context.colors.muted)),
          const SizedBox(height: AppSpacing.l),
          Row(children: [
            for (final (source, label, icon) in const [
              (PhotoSource.camera, 'Take a photo', Icons.photo_camera_outlined),
              (PhotoSource.gallery, 'Choose a photo', Icons.photo_library_outlined),
            ]) ...[
              if (source == PhotoSource.gallery) const SizedBox(width: AppSpacing.s),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(source),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 96), padding: const EdgeInsets.all(AppSpacing.s)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon), const SizedBox(height: AppSpacing.xs), Text(label, textAlign: TextAlign.center)]),
                ),
              ),
            ],
          ]),
        ]),
      );
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
