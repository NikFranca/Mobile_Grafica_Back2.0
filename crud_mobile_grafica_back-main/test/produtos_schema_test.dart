import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

import '../routes/api/produtos/[id].dart' as produto;
import '../routes/api/produtos/index.dart' as produtos;

class _Connection extends Mock implements Connection {}

Result _result(List<List<Object?>> values) {
  final schema = ResultSchema([]);
  return Result(
    rows: values.map((row) => ResultRow(values: row, schema: schema)).toList(),
    affectedRows: values.length,
    schema: schema,
  );
}

void main() {
  const id = '7e399bde-3c22-4ca3-9153-54abc9eaf8ee';
  const payload = {
    'nome': 'Cartão de visita',
    'descricao': 'Papel couché',
    'preco': 25.5,
    'imagemUrl': 'https://example.test/cartao.png',
    'categoria': 'Papelaria',
  };

  final connection = _Connection();
  late Result databaseResult;
  Map<String, Object?>? parameters;
  late HttpServer server;
  late HttpClient client;
  late Uri baseUrl;

  setUpAll(() async {
    final router = Router()
      ..all('/api/produtos', produtos.onRequest)
      ..all('/api/produtos/<id>', produto.onRequest);
    server = await serve(
      router.call.use(provider<Connection?>((_) => connection)),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    baseUrl = Uri.parse('http://127.0.0.1:${server.port}');
    client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    addTearDown(() => client.close(force: true));
  });

  setUp(() {
    reset(connection);
    databaseResult = _result([]);
    parameters = null;
    when(
      () => connection.execute(any(), parameters: any(named: 'parameters')),
    ).thenAnswer((invocation) async {
      parameters =
          invocation.namedArguments[#parameters] as Map<String, Object?>?;
      return databaseResult;
    });
  });

  Future<({int statusCode, Object? body})> request(
    String method,
    String path, {
    Map<String, Object?>? body,
  }) async {
    final outgoing = await client.openUrl(method, baseUrl.resolve(path));
    outgoing.headers.contentType = ContentType.json;
    if (body != null) outgoing.write(jsonEncode(body));
    final response = await outgoing.close().timeout(const Duration(seconds: 5));
    return (
      statusCode: response.statusCode,
      body: jsonDecode(await response.transform(utf8.decoder).join()),
    );
  }

  test('lists UUID products with their existing image and category', () async {
    databaseResult = _result([
      [
        id,
        'Cartão de visita',
        'Papel couché',
        '25.50',
        payload['imagemUrl'],
        'Papelaria',
      ],
    ]);

    final response = await request('GET', '/api/produtos');

    expect(response.statusCode, 200);
    expect(response.body, [
      {'id': id, ...payload},
    ]);
  });

  test('lists a product without an image as null', () async {
    databaseResult = _result([
      [id, 'Cartão de visita', 'Papel couché', '25.50', null, 'Papelaria'],
    ]);

    final response = await request('GET', '/api/produtos');

    expect(response.statusCode, 200);
    final body = response.body! as List<dynamic>;
    final item = body.single as Map<String, dynamic>;
    expect(item['imagemUrl'], isNull);
  });

  test('creates a product with a UUID and its required category', () async {
    databaseResult = _result([
      [id],
    ]);

    final response = await request('POST', '/api/produtos', body: payload);

    expect(response.statusCode, 201);
    final body = response.body! as Map<String, dynamic>;
    expect(body['id'], id);
    expect(body['produto'], {'id': id, ...payload});
    expect(parameters?['categoria'], 'Papelaria');
    expect(parameters?['imagemUrl'], payload['imagemUrl']);
  });

  test('updates an existing UUID product and its category', () async {
    databaseResult = _result([
      [id],
    ]);

    final response = await request('PUT', '/api/produtos/$id', body: payload);

    expect(response.statusCode, 200);
    expect((parameters!['id']! as TypedValue).value, id);
    expect(parameters?['categoria'], 'Papelaria');
  });

  test('allows updates that preserve the existing category', () async {
    databaseResult = _result([
      [id],
    ]);
    final update = {...payload}..remove('categoria');

    final response = await request('PUT', '/api/produtos/$id', body: update);

    expect(response.statusCode, 200);
    expect(parameters?['categoria'], isNull);
  });

  test('deletes an existing UUID product', () async {
    databaseResult = _result([
      [id],
    ]);

    final response = await request('DELETE', '/api/produtos/$id');

    expect(response.statusCode, 200);
    expect((parameters!['id']! as TypedValue).value, id);
  });

  test('rejects numeric product IDs before accessing the database', () async {
    final response = await request('DELETE', '/api/produtos/123');

    expect(response.statusCode, 400);
    verifyNever(
      () => connection.execute(any(), parameters: any(named: 'parameters')),
    );
  });

  test('reports missing UUID products for update and deletion', () async {
    for (final method in ['PUT', 'DELETE']) {
      final response = await request(
        method,
        '/api/produtos/$id',
        body: method == 'PUT' ? payload : null,
      );

      expect(response.statusCode, 404);
      final body = response.body! as Map<String, dynamic>;
      expect(body['erro'], 'Produto não encontrado.');
    }
  });
}
