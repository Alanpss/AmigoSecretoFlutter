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

### Workflow manual de staging

O arquivo `.github/workflows/deploy-staging.yml` prepara uma publicação manual e separada da CI. Antes de habilitá-lo, configure no GitHub um Environment `staging` com revisores obrigatórios e estas variáveis de ambiente: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOYER_SERVICE_ACCOUNT`, `CLOUD_RUN_RUNTIME_SERVICE_ACCOUNT`, `ARTIFACT_REGISTRY_REPOSITORY`, `CLOUD_RUN_SERVICE`, `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_AUTH_DOMAIN` e `PUBLIC_BASE_URL`. A chave Firebase Web identifica o app cliente e acaba embutida no bundle Web; não coloque credenciais de serviço nessas variáveis.

O workflow só aceita o projeto identificado como staging, exige a entrada manual `yes`, autentica o deploy com Workload Identity Federation, envia a imagem da API ao Artifact Registry, atualiza o Cloud Run configurado e depois publica Web e regras no Firebase Hosting/Firestore daquele projeto. O serviço Cloud Run fica acessível pela internet para receber revelações e chamadas do app; a API valida ID token e propriedade do evento nas ações administrativas. Configure o service account de execução com o menor papel Firestore necessário e restrinja a federação ao repositório/branch. A etapa não instala credenciais JSON e nenhuma configuração de produção está incluída.

O workflow executa smoke checks HTTP para `/health` da API e a raiz do Hosting após publicar. Para reversão, selecione uma versão anterior no histórico de Hosting e direcione o tráfego Cloud Run para uma revisão anterior pelo console do Google Cloud; verifique de novo a URL pública e a saúde da API.

Esse workflow é apenas preparação versionada: não foi executado. Criar recursos, conceder IAM, configurar um projeto, billing, domínio ou fazer qualquer deploy requer autorização específica e revisão da configuração do projeto antes da primeira execução.
