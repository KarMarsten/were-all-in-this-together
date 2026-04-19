import 'package:were_all_in_this_together/features/providers/presentation/url_opener.dart';

/// Test double for [UrlOpener] that records every request so detail-screen
/// tests can assert the tap actions hit the right entry point with the
/// right payload — without touching the real `url_launcher` plugin.
class RecordingUrlOpener implements UrlOpener {
  final List<String> telCalls = <String>[];
  final List<({String phone, String? body})> smsCalls =
      <({String phone, String? body})>[];
  final List<String> webCalls = <String>[];
  final List<String> mapCalls = <String>[];

  /// Controls whether the recorded call reports success to the caller.
  /// Flip to `false` in tests that want to exercise the "could not open"
  /// snackbar path.
  bool succeed = true;

  @override
  Future<bool> openTel(String phone) async {
    telCalls.add(phone);
    return succeed;
  }

  @override
  Future<bool> openSms(String phone, {String? body}) async {
    smsCalls.add((phone: phone, body: body));
    return succeed;
  }

  @override
  Future<bool> openWeb(String url) async {
    webCalls.add(url);
    return succeed;
  }

  @override
  Future<bool> openMap(String address) async {
    mapCalls.add(address);
    return succeed;
  }
}
