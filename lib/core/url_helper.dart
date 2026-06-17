import 'constants.dart';

class UrlHelper {
  static String normalizeBaseUrl(
    String input, {
    String fallbackPort = ApiConstants.defaultPort,
  }) {
    var value = input.trim();
    if (value.isEmpty) {
      throw const FormatException('Server address cannot be empty.');
    }

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed == null || parsed.host.trim().isEmpty) {
      throw const FormatException(
        'Enter a valid IP address, hostname, or URL.',
      );
    }

    final port = parsed.hasPort ? parsed.port : int.parse(fallbackPort);
    final normalized = parsed.replace(
      path: '',
      query: null,
      fragment: null,
      port: port,
    );
    return normalized.toString().replaceAll(RegExp(r'/+$'), '');
  }
}
