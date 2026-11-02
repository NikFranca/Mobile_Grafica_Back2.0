A conexão com PostgreSQL já funciona. Esta correção alinha produtos ao esquema
existente: coluna `imagem`, identificadores UUID e `categoria` obrigatória no cadastro.
A API mantém o campo `imagemUrl` no JSON.

1. Abra a branch desta correção no GitHub e use **Code > Download ZIP**.
2. Extraia o ZIP. Dentro da pasta extraída, abra `crud_mobile_grafica_back-main`.
3. Faça uma cópia de segurança dos arquivos locais que serão substituídos.
4. Copie os arquivos abaixo para a mesma posição no projeto que você já executa:

   - `lib/models/produtos.dart`
   - `routes/api/produtos/index.dart`
   - `routes/api/produtos/[id].dart`
   - `test/routes_test.dart`
   - `test/produtos_schema_test.dart`

5. Mantenha o seu `.env` local com a conexão que já funcionou. Ele deve ficar na
   pasta que contém `pubspec.yaml`. Guarde credenciais fora do repositório.
6. Pare o servidor com Ctrl+C e, no PowerShell dentro dessa pasta, execute:

   ```powershell
   $env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
   dart pub get --enforce-lockfile
   dart test
   dart_frog dev
   ```

7. Deixe o servidor aberto e teste em outro PowerShell:

   ```powershell
   curl.exe -i "http://localhost:8080/api/produtos"
   ```

O resultado esperado é HTTP 200 com uma lista JSON. Use `curl.exe` no
PowerShell para chamar o curl; `curl` pode ser um apelido de `Invoke-WebRequest`.

O cadastro de produto precisa incluir `categoria`. Exemplo de corpo JSON:

```json
{
  "nome": "Cartão de visita",
  "descricao": "Papel couché",
  "preco": 25.5,
  "imagemUrl": "https://example.com/cartao.png",
  "categoria": "Papelaria"
}
```

A imagem é opcional. Atualização e exclusão usam o UUID retornado pela listagem
no caminho `/api/produtos/UUID`. O front-end deve tratar `id` como `String`.
Na atualização por PUT, omitir `categoria` preserva a categoria atual.

Validação: 24 testes aprovados, análise estática sem erros ou avisos de compilação
e build de produção gerado com sucesso. A consulta equivalente à listagem foi
validada no banco. As operações de escrita foram testadas com banco simulado;
o teste no Windows verifica o servidor conectado à sua configuração local.

Esta correção cobre as rotas de produtos. Login e cadastro de administradores
precisam de sua própria validação de integração.
