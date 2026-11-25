/// Mengecek apakah [value] adalah URL lengkap yang akan diterima `URLField`
/// Django: skema `http`/`https`, tanpa spasi, dan host berupa nama domain
/// (mengandung titik) atau `localhost`.
bool isValidHttpUrl(String value) {
  if (value.contains(' ')) return false;
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;
  final host = uri.host;
  if (host.isEmpty) return false;
  if (host == 'localhost') return true;
  return host.contains('.') && !host.startsWith('.') && !host.endsWith('.');
}
