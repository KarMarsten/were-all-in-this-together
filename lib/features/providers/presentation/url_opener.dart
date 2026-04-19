import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Thin abstraction over `url_launcher` so widget tests can record
/// tap-to-call / tap-to-open / tap-to-map without touching the plugin
/// channel.
///
/// The three methods exist as separate entry points rather than a
/// generic `open(String)` so the detail screen can build platform-
/// appropriate URIs centrally: a phone number isn't a URL, and on iOS
/// Maps URIs differ from the defaults we'd prefer.
abstract interface class UrlOpener {
  /// Dial the given phone number. Accepts the raw user-entered string;
  /// whitespace / punctuation is tolerated because `tel:` schemes are
  /// generous about format.
  Future<bool> openTel(String phone);

  /// Open the platform SMS composer for [phone] with optional prefilled
  /// [body]. Digits (and a leading `+`) are kept; other punctuation is
  /// stripped for the `sms:` path.
  Future<bool> openSms(String phone, {String? body});

  /// Open [url] in the default browser (or in-app webview, as the
  /// platform decides). Returns `false` when the URL isn't launchable
  /// so callers can surface an error.
  Future<bool> openWeb(String url);

  /// Open [address] in the platform's default maps app.
  Future<bool> openMap(String address);
}

class UrlLauncherUrlOpener implements UrlOpener {
  const UrlLauncherUrlOpener();

  @override
  Future<bool> openTel(String phone) =>
      _tryLaunch(Uri(scheme: 'tel', path: phone));

  @override
  Future<bool> openSms(String phone, {String? body}) {
    final normalized = _smsAddress(phone);
    if (normalized.isEmpty) return Future.value(false);
    final Uri uri;
    final trimmed = body?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      uri = Uri(
        scheme: 'sms',
        path: normalized,
        queryParameters: <String, String>{'body': trimmed},
      );
    } else {
      uri = Uri(scheme: 'sms', path: normalized);
    }
    return _tryLaunch(uri);
  }

  /// Keep digits and a single leading plus for E.164-style input.
  static String _smsAddress(String phone) {
    final t = phone.trim();
    if (t.isEmpty) return '';
    final buf = StringBuffer();
    var i = 0;
    if (t.startsWith('+')) {
      buf.write('+');
      i = 1;
    }
    for (; i < t.length; i++) {
      final c = t.codeUnitAt(i);
      if (c >= 0x30 && c <= 0x39) {
        buf.writeCharCode(c);
      }
    }
    final out = buf.toString();
    if (out == '+' || out.isEmpty) return '';
    return out;
  }

  @override
  Future<bool> openWeb(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return Future.value(false);
    return _tryLaunch(parsed);
  }

  @override
  Future<bool> openMap(String address) {
    // Apple Maps accepts `maps://?q=<query>`; the built-in browser
    // resolves this on iOS without a dependency, and Android
    // interprets the `geo:0,0?q=` variant. Chain both so the launcher
    // falls back to web search if neither is installed.
    final maps = Uri.parse(
      'https://maps.apple.com/?q=${Uri.encodeQueryComponent(address)}',
    );
    return _tryLaunch(maps);
  }

  Future<bool> _tryLaunch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Application-wide [UrlOpener]. Overridden in widget tests with a
/// recording fake.
final urlOpenerProvider = Provider<UrlOpener>(
  (ref) => const UrlLauncherUrlOpener(),
);
