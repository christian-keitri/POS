/// Base URL for the POS API.
/// Production: set via --dart-define=API_BASE_URL=https://your-api.com when building.
/// Development: defaults to localhost.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:3000',
);

/// Full URL for a product image path returned by the API.
String productImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  final base = apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/';
  return '${base}uploads/$imagePath';
}

/// Returns a user-friendly message for API/connection errors.
/// Use when catching errors from ApiService so users see how to fix connection issues.
String apiErrorMessage(Object error) {
  final msg = error.toString().toLowerCase();
  final isConnection = msg.contains('connection') ||
      msg.contains('failed host lookup') ||
      msg.contains('network is unreachable') ||
      msg.contains('socket') ||
      msg.contains('connection refused') ||
      msg.contains('connection reset');
  if (isConnection) {
    return 'Cannot reach the server at $apiBaseUrl.\n\n'
        '• Make sure the POS server is running (e.g. node server or npm start).\n'
        '• To use a different URL, set API_BASE_URL when building:\n'
        '  flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000';
  }
  return error.toString();
}
