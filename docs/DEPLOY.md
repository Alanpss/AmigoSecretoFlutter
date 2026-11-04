# Preparar publicação Web

Este guia descreve como preparar o artefato estático do Flutter Web. Ele não escolhe um provedor, não configura credenciais e não publica o aplicativo. A publicação depende de uma decisão e autorização explícitas.

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

O aplicativo não possui backend nem sincronização. Publicá-lo não hospeda eventos ou backups, e cada navegador mantém dados separados por origem. Backups contêm telefones e resultados e devem ser guardados fora do site, em local seguro.
