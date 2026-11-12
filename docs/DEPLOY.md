# Preparar publicação Web

Este guia descreve como preparar o artefato estático do Flutter Web. A configuração automatizada com Docker/CI está planejada na Fase 8. Este documento não configura credenciais nem publica o aplicativo; criação de recursos e deploy real exigem autorização explícita.

## 1. Gerar e revisar o artefato

Na raiz do repositório:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

O artefato fica em `build/web/`. Faça a revisão final desse diretório e confirme que não contém backups, bancos locais, dados pessoais ou segredos.

## 2. Requisitos do servidor estático

- Servir `build/web/` por HTTPS.
- Usar `index.html` como fallback para rotas da aplicação (por exemplo, `/events` e `/settings`) quando o caminho solicitado não for um arquivo existente.
- Se o app for hospedado num subcaminho, reconstruir com o `--base-href` correspondente e testar a URL completa antes de publicar.
- Servir `manifest.json`, ícones e arquivos JavaScript/WASM referenciados pelo `index.html` sem reescrever seus caminhos.
- Evitar cache prolongado para `index.html` e `manifest.json`; os assets com hash podem receber cache longo conforme a política do provedor.
- Configurar o domínio para responder à origem esperada. A persistência usa IndexedDB vinculado à origem; trocar domínio ou protocolo não transfere os dados locais.

## 3. Verificação antes de abrir ao público

1. Confirmar com o responsável pelo projeto o provedor, domínio e subcaminho.
2. Publicar primeiro num ambiente de prévia privado, se o provedor oferecer essa opção.
3. Abrir a raiz e recarregar diretamente rotas profundas; nenhuma delas deve retornar erro 404 do servidor.
4. Verificar manifesto, ícones, HTTPS, layout responsivo, backup/importação e o fluxo de sorteio com dados fictícios.
5. Confirmar que nenhum dado de teste foi embutido no artefato e que a origem publicada é a correta.
6. Antes da publicação pública, obter autorização explícita. Não incluir dados reais de eventos no pacote; cada organizador deve criar ou importar os próprios dados localmente.

O modo local não possui backend nem sincronização. Publicá-lo não hospeda eventos ou backups, e cada navegador mantém dados separados por origem. Backups contêm telefones e resultados e devem ser guardados fora do site, em local seguro. O modo online usa serviço Cloud Run/Firebase e ainda não foi publicado; a configuração e o deploy desse serviço exigem autorização e uma revisão separadas.

## 4. Automação planejada na Fase 8

O objetivo registrado no plano é usar Docker Compose para desenvolvimento e testes locais com API, Flutter Web e Firebase Emulators. Para produção, o Flutter Web será publicado no Firebase Hosting e a imagem Dart no Cloud Run. O Firebase de produção continua gerenciado pelo provedor; Docker não o empacota como um serviço local. Requisitos de projeto, Authentication Google, Firestore, IAM, domínio, segredos do CI e reversão estão descritos como entregas planejadas em `docs/PLANO_IMPLEMENTACAO.md`, seção 11. Nenhum deploy é realizado por este roteiro.
