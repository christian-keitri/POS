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
