/// Base URL for the POS API. Use your machine's IP if testing on a real device.
const String apiBaseUrl = 'http://127.0.0.1:3000';

/// Full URL for a product image path returned by the API.
String productImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) return '';
  final base = apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/';
  return '${base}uploads/$imagePath';
}
