import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../ledger/presentation/ledger_providers.dart';
import '../domain/account_models.dart';
import 'account_providers.dart';
import 'card_face.dart';
import 'card_palette.dart';

/// Changes how [account]'s card looks: its finish, colour and nickname. Its
/// balance changes only through what is logged.
Future<void> showCardDesigner(BuildContext context, Account account) => _open(context, _CardDesigner(account: account));

/// Changes how the total card looks.
Future<void> showTotalCardDesigner(BuildContext context) => _open(context, const _CardDesigner());

Future<void> _open(BuildContext context, Widget sheet) =>
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => sheet);

class _CardDesigner extends ConsumerStatefulWidget {
  /// Null designs the total card.
  const _CardDesigner({this.account});

  final Account? account;

  @override
  ConsumerState<_CardDesigner> createState() => _CardDesignerState();
}

class _CardDesignerState extends ConsumerState<_CardDesigner> {
  late final Account? _account = widget.account;
  late int? _color = _account?.look.color ?? ref.read(totalCardLookProvider).value?.color;
  late int? _ink = _account?.look.ink;
  late CardFinish _finish = _account?.look.finish ?? ref.read(totalCardLookProvider).value?.finish ?? CardFinish.brushed;
  late final _nickname = TextEditingController(text: _account?.nickname);

  bool get _isCash => _account?.kind == AccountKind.cash;
  bool get _isTotal => _account == null;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _pick(CardSwatch? swatch) => setState(() {
        _color = swatch?.color;
        _ink = swatch?.ink;
      });

  Future<void> _save() async {
    final repo = ref.read(accountRepositoryProvider);
    if (_account case final account?) {
      await repo.updateAccount(account.copyWith(nickname: () => _nickname.text, look: CardLook(color: _color!, ink: _ink, finish: _finish)));
    } else {
      await repo.saveTotalLook(TotalCardLook(color: _color, finish: _finish));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final account = _account;
    final swatches = _isCash ? leatherSwatches : cardSwatches;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_isTotal ? 'Total card' : 'Edit card', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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
            const SizedBox(height: AppSpacing.xl),
            FilledButton(onPressed: _save, child: Text(_isTotal ? 'Save total card' : 'Save card')),
          ],
        ),
      ),
    );
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
