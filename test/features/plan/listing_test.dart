import 'package:bajet/features/plan/domain/listing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only a web address is kept as a listing link, trimmed', () {
    expect(parseListingUrl('  https://www.facebook.com/marketplace/item/1/ '), Uri.parse('https://www.facebook.com/marketplace/item/1/'));
    expect(parseListingUrl('http://example.com/a'), Uri.parse('http://example.com/a'));
    for (final bad in ['', 'macbook 3200 still ok?', 'facebook.com/marketplace', 'javascript:alert(1)', 'intent://x', 'file:///sdcard/a', 'https://']) {
      expect(parseListingUrl(bad), isNull, reason: bad);
    }
  });

  test('a listing is named after its site, Marketplace for a Facebook Marketplace link', () {
    String title(String url) => Listing(Uri.parse(url)).title;
    expect(title('https://www.facebook.com/marketplace/item/1/'), 'Marketplace listing');
    expect(title('https://m.facebook.com/marketplace/item/1'), 'Marketplace listing');
    expect(title('https://www.facebook.com/groups/1'), 'facebook.com listing');
    expect(title('https://shopee.com.my/item/2'), 'shopee.com.my listing');
    expect(title('https://www.mudah.my/x'), 'mudah.my listing');
  });
}
