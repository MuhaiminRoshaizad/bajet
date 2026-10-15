import '../domain/account_models.dart';

/// A colour a card can be. The palette is the app's own, so a card can be
/// near a bank's colour without being the bank's design.
class CardSwatch {
  const CardSwatch(this.name, this.color, {this.ink});

  final String name;
  final int color;

  /// A text colour that goes with it, such as gold on black.
  final int? ink;

  CardLook look(CardFinish finish) => CardLook(color: color, ink: ink, finish: finish);
}

const cardSwatches = [
  CardSwatch('Crimson', 0xFFC0262D),
  CardSwatch('Brick', 0xFF9C3B22),
  CardSwatch('Amber', 0xFFE8A317),
  CardSwatch('Sunflower', 0xFFF2C230),
  CardSwatch('Olive', 0xFF6B7A2A),
  CardSwatch('Forest', 0xFF2F7A57),
  CardSwatch('Teal', 0xFF00877F),
  CardSwatch('Sky', 0xFF3D8FD1),
  CardSwatch('Ocean', 0xFF0D55C0),
  CardSwatch('Navy', 0xFF1C2F5E),
  CardSwatch('Slate', 0xFF4A5866),
  CardSwatch('Graphite', 0xFF2B3036),
  CardSwatch('Black and gold', 0xFF151515, ink: 0xFFE6C674),
  CardSwatch('Silver', 0xFFB9C0C7),
  CardSwatch('Champagne', 0xFFCDB88A),
  CardSwatch('Rose gold', 0xFFC98F7A),
];

/// Cash is a wallet, so it comes in leathers.
const leatherSwatches = [
  CardSwatch('Tan', 0xFFA8693A),
  CardSwatch('Brown', 0xFF6B3F24),
  CardSwatch('Chestnut', 0xFF8A3A22),
  CardSwatch('Oxblood', 0xFF5E1D22),
  CardSwatch('Black', 0xFF1D1B1A),
  CardSwatch('Navy', 0xFF1F2C45),
  CardSwatch('Olive', 0xFF4F5530),
  CardSwatch('Grey', 0xFF55585C),
];

/// The finishes a card can have; leather is only ever the wallet's.
const cardFinishes = [CardFinish.brushed, CardFinish.matte, CardFinish.gloss];

String finishLabel(CardFinish finish) => switch (finish) {
      CardFinish.brushed => 'Brushed metal',
      CardFinish.matte => 'Matte',
      CardFinish.gloss => 'Gloss',
      CardFinish.leather => 'Leather',
    };

/// The swatch a new account starts on: near a provider's own colour when it
/// has a well-known one, slate otherwise, brown leather for cash. The owner
/// can change it straight away.
CardSwatch startingSwatch(AccountKind kind, String provider) {
  if (kind == AccountKind.cash) return leatherSwatches[1];
  final name = _nearProvider[provider] ?? 'Slate';
  return cardSwatches.firstWhere((s) => s.name == name);
}

const _nearProvider = {
  'Maybank': 'Sunflower',
  'MAE by Maybank': 'Sunflower',
  'CIMB': 'Crimson',
  'Public Bank': 'Crimson',
  'RHB': 'Navy',
  'Hong Leong Bank': 'Navy',
  'Bank Islam': 'Black and gold',
  'BSN': 'Ocean',
  'GXBank': 'Graphite',
  "Touch 'n Go eWallet": 'Ocean',
  'Setel': 'Teal',
  'GrabPay': 'Forest',
  'ShopeePay': 'Brick',
};
