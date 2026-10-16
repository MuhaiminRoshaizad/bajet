import 'account_models.dart';

/// Banks and e-wallets to pick from, by name only: the banks, Islamic banks,
/// digital banks and e-money issuers on Bank Negara Malaysia's lists
/// (checked 15/10/2026), grouped, the most used first. Anything else can be
/// typed.
const providerGroups = {
  AccountKind.bank: [
    ('Most used', ['Maybank', 'CIMB', 'Public Bank', 'RHB', 'Hong Leong Bank', 'Bank Islam', 'BSN', 'AmBank', 'Bank Rakyat']),
    ('Digital banks', ['GXBank', 'Boost Bank', 'AEON Bank', 'KAF Digital Bank', 'Ryt Bank']),
    (
      'Other banks',
      [
        'Affin Bank', 'Alliance Bank', 'UOB', 'OCBC', 'HSBC', 'Standard Chartered', 'Bank Muamalat', 'MBSB Bank', 'Al Rajhi Bank', //
        'Kuwait Finance House', 'Agrobank',
      ],
    ),
  ],
  AccountKind.ewallet: [
    ('E-wallets', ["Touch 'n Go eWallet", 'MAE by Maybank', 'ShopeePay', 'Setel', 'GrabPay', 'Boost', 'BigPay', 'MyEG']),
  ],
};

/// [kind]'s providers whose names contain [query], ignoring case, in the
/// order they are listed.
List<String> providersMatching(AccountKind kind, String query) {
  final q = query.trim().toLowerCase();
  return [
    for (final (_, names) in providerGroups[kind] ?? const <(String, List<String>)>[])
      for (final p in names)
        if (p.toLowerCase().contains(q)) p,
  ];
}
