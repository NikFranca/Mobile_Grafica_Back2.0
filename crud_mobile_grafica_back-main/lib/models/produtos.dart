class Produto {
  // Identificador único do produto
  final String? id;

  // Nome do produto
  final String nome;

  // Descrição do produto
  final String descricao;

  // Preço do produto
  final double preco;

  // URL da imagem (opcional)
  final String? imagemUrl;

  /// Categoria opcional na atualização e obrigatória no cadastro.
  final String? categoria;

  // Construtor da classe Produto
  const Produto({
    required this.nome,
    required this.descricao,
    required this.preco,
    this.id,
    this.imagemUrl,
    this.categoria,
  });

  // ==========================================
  // CONVERTER JSON PARA OBJETO PRODUTO
  // ==========================================

  factory Produto.fromJson(Map<String, dynamic> json) {
    // Recupera e valida o ID
    String? idProduto;

    if (json['id'] != null) {
      final idInformado = json['id'];
      if (idInformado is! String || !idValido(idInformado.trim())) {
        throw const FormatException(
          'ID do produto inválido!',
        );
      }
      idProduto = idInformado.trim();
    }

    // Recupera e valida o nome
    final nomeInformado = json['nome'];

    if (nomeInformado is! String || nomeInformado.trim().isEmpty) {
      throw const FormatException(
        'O nome do produto é obrigatório!',
      );
    }

    final nomeProduto = nomeInformado.trim();

    // Recupera e valida a descrição
    final descricaoInformada = json['descricao'];

    if (descricaoInformada is! String || descricaoInformada.trim().isEmpty) {
      throw const FormatException(
        'A descrição do produto é obrigatória!',
      );
    }

    final descricaoProduto = descricaoInformada.trim();

    // Recupera e converte o preço
    final precoInformado = json['preco'];

    final double? precoProduto = precoInformado is num
        ? precoInformado.toDouble()
        : precoInformado is String
        ? double.tryParse(precoInformado.trim())
        : null;

    // Verifica se o preço é válido
    if (precoProduto == null || !precoProduto.isFinite || precoProduto <= 0) {
      throw const FormatException(
        'O preço deve ser maior que zero!',
      );
    }

    // Recupera a URL da imagem
    // Mantém os nomes de imagem aceitos pela API.
    final imagemInformada =
        json['imagemUrl'] ?? json['imagem_url'] ?? json['imagem'];

    if (imagemInformada != null && imagemInformada is! String) {
      throw const FormatException(
        'A URL da imagem deve ser um texto!',
      );
    }

    final String? imagemProduto =
        imagemInformada is String && imagemInformada.trim().isNotEmpty
        ? imagemInformada.trim()
        : null;

    final categoriaInformada = json['categoria'];
    if (categoriaInformada != null &&
        (categoriaInformada is! String || categoriaInformada.trim().isEmpty)) {
      throw const FormatException(
        'A categoria do produto deve ser um texto não vazio!',
      );
    }

    // Retorna o objeto Produto
    return Produto(
      id: idProduto,
      nome: nomeProduto,
      descricao: descricaoProduto,
      preco: precoProduto,
      imagemUrl: imagemProduto,
      categoria: (categoriaInformada as String?)?.trim(),
    );
  }

  /// Aceita identificadores UUID usados pela tabela de produtos.
  static bool idValido(String id) => RegExp(
    r'^[0-9a-fA-F]{8}-(?:[0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$',
  ).hasMatch(id);

  // ==========================================
  // CONVERTER OBJETO PRODUTO PARA JSON
  // ==========================================

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagemUrl': imagemUrl,
      if (categoria != null) 'categoria': categoria,
    };
  }

  // ==========================================
  // CONVERTER OBJETO PARA O POSTGRESQL
  // ==========================================

  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'imagem': imagemUrl,
      if (categoria != null) 'categoria': categoria,
    };
  }

  // ==========================================
  // CRIAR CÓPIA DO PRODUTO
  // ==========================================

  Produto copyWith({
    String? id,
    String? nome,
    String? descricao,
    double? preco,
    String? imagemUrl,
    String? categoria,
  }) {
    return Produto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      preco: preco ?? this.preco,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      categoria: categoria ?? this.categoria,
    );
  }

  // ==========================================
  // REPRESENTAÇÃO DO PRODUTO EM TEXTO
  // ==========================================

  @override
  String toString() {
    return 'Produto('
        'id: $id, '
        'nome: $nome, '
        'descricao: $descricao, '
        'preco: $preco, '
        'imagemUrl: $imagemUrl, '
        'categoria: $categoria'
        ')';
  }
}
