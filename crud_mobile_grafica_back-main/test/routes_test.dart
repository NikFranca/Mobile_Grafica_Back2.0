import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/api/admin/cadastrar.dart' as cadastro;
import '../routes/api/admin/login.dart' as login;
import '../routes/api/produtos/index.dart' as produtos;

typedef _Result = ({
  int statusCode,
  Map<String, dynamic> body,
  HttpHeaders headers,
});

void main() {
  late HttpServer server;
  late HttpClient client;
  late Uri baseUrl;

  setUpAll(() async {
    final router = Router()
      ..all('/api/admin/login', login.onRequest)
      ..all('/api/admin/cadastrar', cadastro.onRequest)
      ..all('/api/produtos', produtos.onRequest);

    // Exercise the real handlers over HTTP, without loading the middleware
    // that opens the externally configured database connection.
    server = await serve(
      router.call.use(provider<Connection?>((_) => null)),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    baseUrl = Uri.parse('http://127.0.0.1:${server.port}');
    client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    addTearDown(() => client.close(force: true));
  });

  Future<_Result> request(
    String method,
    String path, {
    Object? body,
    String? rawBody,
  }) async {
    final outgoing = await client.openUrl(method, baseUrl.resolve(path));
    outgoing.headers.contentType = ContentType.json;
    if (rawBody != null) {
      outgoing.write(rawBody);
    } else if (body != null) {
      outgoing.write(jsonEncode(body));
    }
    final response = await outgoing.close().timeout(const Duration(seconds: 5));
    final decoded = jsonDecode(await response.transform(utf8.decoder).join());
    return (
      statusCode: response.statusCode,
      body: decoded as Map<String, dynamic>,
      headers: response.headers,
    );
  }

  group('Login', () {
    test('accepts only POST', () async {
      final result = await request('GET', '/api/admin/login');
      _expectError(result, 405, 'Método não permitido.');
    });

    test('requires email and password', () async {
      final result = await request('POST', '/api/admin/login', body: {});
      _expectError(
        result,
        400,
        'E-mail e senha são obrigatórios para o login!',
      );
    });

    test('rejects malformed JSON', () async {
      final result = await request('POST', '/api/admin/login', rawBody: '{');
      _expectError(result, 400, 'JSON inválido.');
    });

    test('rejects invalid email before accessing the database', () async {
      final result = await request(
        'POST',
        '/api/admin/login',
        body: {'email': 'invalid', 'senha': 'test-password'},
      );
      _expectError(result, 400, 'E-mail inválido!');
    });
  });

  group('Administrator registration', () {
    const validPayload = {
      'nome': 'Administrador Teste',
      'email': 'admin@example.test',
      // Synthetic CPF used only to exercise check-digit validation.
      'cpf': '52998224725',
      'senha': 'test-password',
      'confirmarSenha': 'test-password',
    };

    test('requires all registration fields', () async {
      final result = await request('POST', '/api/admin/cadastrar', body: {});
      _expectError(result, 400, 'Todos os campos são obrigatórios!');
    });

    test('rejects a CPF containing repeated digits', () async {
      final result = await request(
        'POST',
        '/api/admin/cadastrar',
        body: {...validPayload, 'cpf': '11111111111'},
      );
      _expectError(result, 400, 'CPF inválido!');
    });

    test('rejects mismatched passwords after validating the CPF', () async {
      final result = await request(
        'POST',
        '/api/admin/cadastrar',
        body: {...validPayload, 'confirmarSenha': 'different-password'},
      );
      _expectError(result, 400, 'As senhas não coincidem!');
    });
  });

  group('Products', () {
    const validPayload = {
      'nome': 'Cartão de visita',
      'descricao': 'Papel couché',
      'preco': 25.5,
    };

    test('advertises supported methods', () async {
      final result = await request('PATCH', '/api/produtos');
      _expectError(result, 405, 'Método não permitido.');
      expect(result.headers.value(HttpHeaders.allowHeader), 'GET, POST');
    });

    test('rejects non-object JSON', () async {
      final result = await request('POST', '/api/produtos', body: []);
      _expectError(result, 400, 'Formato de dados inválido!');
    });

    test('requires a nonempty description', () async {
      final result = await request(
        'POST',
        '/api/produtos',
        body: {...validPayload, 'descricao': '   '},
      );
      _expectError(result, 400, 'A descrição do produto é obrigatória!');
    });

    test('rejects zero, negative, and nonfinite prices', () async {
      for (final price in [0, -1, 'NaN', 'Infinity']) {
        final result = await request(
          'POST',
          '/api/produtos',
          body: {...validPayload, 'preco': price},
        );
        _expectError(result, 400, 'O preço deve ser um número maior que zero!');
      }
    });

    test('requires an image URL to be text', () async {
      final result = await request(
        'POST',
        '/api/produtos',
        body: {...validPayload, 'imagemUrl': 123},
      );
      _expectError(result, 400, 'A URL da imagem deve ser um texto!');
    });

    test('reports unavailable database when listing products', () async {
      final result = await request('GET', '/api/produtos');
      _expectError(result, 500, 'Conexão com o banco de dados indisponível.');
    });

    test(
      'reports unavailable database for an otherwise valid product',
      () async {
        final result = await request(
          'POST',
          '/api/produtos',
          body: validPayload,
        );
        _expectError(result, 500, 'Conexão com o banco de dados indisponível.');
      },
    );
  });

  test('valid login payload reports unavailable database', () async {
    final result = await request(
      'POST',
      '/api/admin/login',
      body: {'email': 'admin@example.test', 'senha': 'test-password'},
    );
    _expectError(result, 500, 'Conexão com o banco de dados indisponível.');
  });
}

void _expectError(_Result result, int statusCode, String message) {
  expect(result.statusCode, statusCode);
  expect(result.body, {'sucesso': false, 'mensagem': message});
  expect(result.headers.contentType?.mimeType, 'application/json');
}
