import 'account_models.dart';

/// Banks and e-wallets to pick from, by name only: the banks, Islamic banks,
/// digital banks and e-money issuers on Bank Negara Malaysia's lists
/// (checked 15/10/2026), the most used first. Anything else can be typed.
const knownProviders = {
  AccountKind.bank: [
    'Maybank', 'CIMB', 'Public Bank', 'RHB', 'Hong Leong Bank', 'Bank Islam', 'BSN', 'AmBank', 'Bank Rakyat', 'GXBank', //
    'Affin Bank', 'Alliance Bank', 'UOB', 'OCBC', 'HSBC', 'Standard Chartered', 'Bank Muamalat', 'MBSB Bank', 'Al Rajhi Bank',
    'Kuwait Finance House', 'Agrobank', 'Boost Bank', 'AEON Bank', 'KAF Digital Bank', 'Ryt Bank',
  ],
  AccountKind.ewallet: ["Touch 'n Go eWallet", 'MAE by Maybank', 'ShopeePay', 'Setel', 'GrabPay', 'Boost', 'BigPay', 'MyEG'],
};

/// [kind]'s providers whose names contain [query], ignoring case.
List<String> providersMatching(AccountKind kind, String query) {
  final q = query.trim().toLowerCase();
  return [for (final p in knownProviders[kind] ?? const <String>[]) if (p.toLowerCase().contains(q)) p];
}
