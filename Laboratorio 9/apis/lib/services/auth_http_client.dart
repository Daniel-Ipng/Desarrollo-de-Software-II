import 'package:http/http.dart' as http;

/// Cliente HTTP que agrega el token Bearer a TODAS las peticiones.
/// Uso: ApiService(client: AuthHttpClient(token: 'tu-token'))
class AuthHttpClient extends http.BaseClient {
  final String token;
  final http.Client _inner;

  AuthHttpClient({required this.token, http.Client? inner})
      : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
