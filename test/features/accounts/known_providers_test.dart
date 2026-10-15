import 'package:bajet/features/accounts/domain/account_models.dart';
import 'package:bajet/features/accounts/domain/known_providers.dart';
import 'package:bajet/features/accounts/presentation/card_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('providers match on any part of the name, ignoring case', () {
    expect(providersMatching(AccountKind.bank, 'BANK').take(3), ['Maybank', 'Public Bank', 'Hong Leong Bank']);
    expect(providersMatching(AccountKind.ewallet, 'pay'), ['ShopeePay', 'GrabPay', 'BigPay']);
    expect(providersMatching(AccountKind.cash, ''), isEmpty);
  });

  test('a new card starts near a known provider, slate otherwise, brown leather for cash', () {
    expect(startingSwatch(AccountKind.bank, 'CIMB').name, 'Crimson');
    expect(startingSwatch(AccountKind.ewallet, 'Office card').name, 'Slate');
    expect(startingSwatch(AccountKind.cash, '').name, 'Brown');
  });
}
