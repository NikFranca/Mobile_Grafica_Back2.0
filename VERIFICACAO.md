# Execução e verificação da API

O projeto Dart Frog está em `crud_mobile_grafica_back-main`.
Use Dart 3.13 ou superior, menor que 4.0: o `pubspec.lock` exige essa versão,
apesar do requisito menos restritivo no `pubspec.yaml`.

## Preparação

Com o SDK Dart disponível no `PATH`:

```sh
cd crud_mobile_grafica_back-main
dart pub get --enforce-lockfile
dart pub global activate dart_frog_cli 1.2.14
# Inclua o diretório bin do PUB_CACHE no PATH para usar dart_frog.
```

No ambiente de nuvem preparado nesta sessão:

```sh
export PUB_CACHE=/workspace/.cloud-cache/pub
export PATH="/workspace/.cloud-tools/dart-sdk/bin:$PUB_CACHE/bin:$PATH"
cd /workspace/Mobile_Grafica_Back2.0/crud_mobile_grafica_back-main
```

Configure `SUPABASE_DB_URL` nas variáveis seguras de execução ou em um `.env`
local, usando `.env.example` como referência. No campo de valor da interface,
insira apenas a URL em uma única linha, sem nome de variável, aspas, comandos
ou texto adicional. Nunca versione a URL com credenciais. Codifique caracteres
reservados da senha como componentes de URL.

O backend usa PostgreSQL nativo com SSL; acesso HTTPS ao Supabase não substitui
uma rota TCP até o banco. A conexão direta do Supabase também pode exigir
conectividade IPv6, conforme a configuração do projeto. Confirme a compatibilidade
da rede antes de escolher conexão direta ou pooler.

As rotas esperam as tabelas `produto` (`id` inteiro autogerado, `nome`,
`descricao`, `preco`, `imagem_url`) e `administradores` (`id` UUID, `nome`,
`email`, `cpf`, `senha`). O código espera unicidade de e-mail e CPF e senhas
com hash BCrypt. O repositório ainda não fornece migrations; esta descrição
não substitui a validação do esquema real.

## Testes e inicialização

```sh
dart test
dart analyze
dart_frog build
dart build/bin/server.dart
```

Para desenvolvimento com recarga automática:

```sh
dart_frog dev --hostname 0.0.0.0 --port 8080
```

Os testes de rotas não usam um banco real. Eles verificam validação de entrada,
métodos HTTP e respostas de indisponibilidade do banco. Não comprovam login
com credenciais reais nem persistência.

Com o servidor em execução, uma verificação somente leitura do banco é:

```sh
curl --fail-with-body http://127.0.0.1:8080/api/produtos
```

O resultado esperado com banco e esquema corretos é HTTP 200 com um array JSON.
HTTP 500 indica falha e não comprova prontidão. Não use operações de cadastro,
atualização ou exclusão em um banco de produção para testar o ambiente.

## Resultado verificado em 31/10/2026

- SDK Dart 3.13.7 instalado com verificação SHA-256 do arquivo oficial.
- Dependências instaladas com `--enforce-lockfile`, sem alterar o lockfile.
- 15 testes HTTP de rotas passaram em `dart test test/routes_test.dart
  --reporter expanded`; a análise estática do arquivo de testes não encontrou
  problemas.
- `dart_frog build` concluído e servidor compilado iniciado.
- `dart analyze` concluído com 49 informações de lint existentes, sem erros
  ou avisos de compilação.
- HTTP: login e cadastro vazios retornaram 400; GET no login retornou 405;
  produto vazio retornou 400; PATCH na coleção de produtos retornou 405.
- GET de produtos retornou 500 com mensagem de banco indisponível. O log
  confirmou URL inválida na variável de execução; a conexão real não foi
  estabelecida e as operações com banco permanecem sem validação.

O runtime atual também não declara VPN ou permissões TCP externas. Corrigir
o conteúdo da variável não comprova, por si só, acesso de rede ao PostgreSQL.
Essas limitações do ambiente precisam ser resolvidas para validar a integração.

Antes de expor a API, revise a autenticação das mutações de produtos: as rotas
atuais não exigem uma sessão autenticada. Esta verificação não alterou as
regras de autenticação nem a lógica da aplicação.
