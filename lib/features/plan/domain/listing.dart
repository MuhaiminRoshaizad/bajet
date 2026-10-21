/// What the user saw when they last looked at a goal's listing.
enum ListingCheck { up, sold }

/// The web page of the thing a goal is saving for, such as a Marketplace
/// post, and what it showed when the user last looked. bajet never reads
/// the page itself: the user opens it and says.
class Listing {
  const Listing(this.url, {this.check, this.checkedOn});

  final Uri url;

  /// Null until the user has looked.
  final ListingCheck? check;
  final DateTime? checkedOn;

  /// What the preview calls it: Marketplace for a Facebook Marketplace
  /// link, otherwise the site's own address without its www.
  String get title {
    final host = url.host.toLowerCase().replaceFirst(RegExp(r'^(www|m|web)\.'), '');
    if (host == 'facebook.com' && url.path.startsWith('/marketplace')) return 'Marketplace listing';
    return '$host listing';
  }

  @override
  bool operator ==(Object other) => other is Listing && other.url == url && other.check == check && other.checkedOn == checkedOn;

  @override
  int get hashCode => Object.hash(url, check, checkedOn);
}

/// The link in [text] when it is a web address, trimmed; otherwise null.
/// Only http and https are kept, so nothing else can be handed to another
/// app.
Uri? parseListingUrl(String text) {
  final uri = Uri.tryParse(text.trim());
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) return null;
  return uri;
}
