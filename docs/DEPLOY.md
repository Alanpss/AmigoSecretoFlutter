# Preparar Firebase e publicação Web

Este guia cobre a configuração do login Google real, Firebase Hosting, Firestore e API Cloud Run antes da publicação. O usuário criou o projeto `amigo-secreto-blacks`, registrou o app Web, criou o site Hosting e o banco Firestore. O provedor Google está habilitado, os domínios `localhost`, `amigo-secreto-blacks.firebaseapp.com` e `amigo-secreto-blacks.web.app` estão autorizados, e o usuário confirmou o login Google real no build local. Cloud Run, o fluxo completo de eventos online e qualquer deploy seguem pendentes.

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

## 4. Preparação do projeto Firebase e Google Authentication

Use um projeto separado para produção. A criação do projeto, ativação de billing e recursos em nuvem podem gerar custos e precisam ser concluídas pelo proprietário da conta Google.

1. No Firebase Console, crie ou selecione o projeto e confirme o ID do projeto. No Cloud Run, Firebase Hosting e no serviço Dart, use o mesmo projeto.
2. Crie o site padrão do Firebase Hosting antes de registrar o app Web. Para projetos novos, o site padrão pode não ser criado automaticamente. O domínio `authDomain` da configuração Firebase Web vem desse site.
3. Registre um app Web Firebase e guarde estes valores da configuração do app: `apiKey`, `appId`, `messagingSenderId`, `projectId` e `authDomain`. Eles identificam o app cliente e são incorporados ao JavaScript do site; a chave Web não é uma credencial de servidor. Use o `authDomain` informado pelo próprio app, pois a ID do site Hosting pode diferir do ID do projeto.
4. Em **Authentication → Sign-in method**, habilite **Google** e escolha o e-mail de suporte. Em **Authentication → Settings → Authorized domains**, cadastre os domínios exatos usados no app publicado, incluindo o domínio Hosting (`*.web.app`) e o domínio personalizado, se houver. O `authDomain` deve corresponder à configuração do app Web.
5. Crie o banco Cloud Firestore na localização desejada e publique as regras versionadas com o workflow. As regras do cliente negam todo acesso às coleções privadas; a API acessa Firestore usando sua identidade Cloud Run.
6. Para domínio personalizado, configure primeiro o domínio no Hosting, cadastre-o em Authorized domains e use o `authDomain` adequado à estratégia escolhida. Mantenha HTTPS. O fluxo atual usa `signInWithPopup` do Firebase Auth.

A ordem site Hosting → app Web evita registrar uma configuração com `authDomain` incorreto. Consulte a documentação oficial sobre [Google sign-in para Web](https://firebase.google.com/docs/auth/web/google-signin) e [site padrão do Firebase Hosting](https://firebase.google.com/docs/hosting/default-site).

## 5. Configuração do Cloud Run e CI

O objetivo registrado no plano é usar Docker Compose para desenvolvimento e testes locais com API, Flutter Web e Firebase Emulators. Para produção, o Flutter Web será publicado no Firebase Hosting e a imagem Dart no Cloud Run. O Firebase de produção continua gerenciado pelo provedor; Docker não o empacota como um serviço local. Requisitos de projeto, Authentication Google, Firestore, IAM, domínio, segredos do CI e reversão estão descritos como entregas planejadas em `docs/PLANO_IMPLEMENTACAO.md`, seção 11. Nenhum deploy é realizado por este roteiro.

### Preparação manual de um projeto de staging isolado

O projeto `amigo-secreto-blacks` fica reservado para produção. O workflow rejeita esse ID para evitar que uma execução de staging substitua Hosting ou regras de Firestore de produção. Crie um projeto Firebase/Google Cloud separado, por exemplo `amigo-secreto-blacks-staging` (se o ID estiver disponível), usando sua própria conta no Console.

1. No Firebase Console, use o seletor de projeto → **Adicionar projeto**. Anote o ID realmente criado; ele será usado tanto em Firebase quanto em Google Cloud.
2. No projeto de staging, crie o site padrão do Hosting, registre um app Web, habilite Google Authentication e autorize o domínio `.web.app` do staging. Crie o banco `(default)` em modo de produção. Antes de escolher a localização do Firestore, confira a localização do banco de produção: localização de banco não pode ser alterada depois da criação; mantenha a mesma região operacional sempre que possível.
3. Cloud Run e Artifact Registry podem gerar cobrança. Confira a [precificação do Cloud Run](https://cloud.google.com/run/pricing) e do [Artifact Registry](https://cloud.google.com/artifact-registry/pricing) antes de vincular billing. Um orçamento de alertas avisa sobre gastos, mas não limita automaticamente o consumo; consulte [limites de orçamento](https://docs.cloud.google.com/billing/docs/how-to/budgets).
4. No Google Cloud Console, selecione o projeto de staging e habilite as APIs Cloud Run, Artifact Registry, IAM, IAM Service Account Credentials, Security Token Service, Firebase Hosting e Firebase Rules. Firestore/Firebase podem já ter habilitado algumas delas.
5. Crie um repositório Docker no Artifact Registry na região escolhida para a API, por exemplo `amigo-secreto-staging`.
6. Crie a conta de serviço de execução `online-draw-staging-runtime` e conceda a ela `Cloud Datastore User` (`roles/datastore.user`) no projeto de staging. Essa é a identidade que a API usa para ler e gravar no Firestore; não gere chave JSON.
7. Crie a conta de serviço de deploy `github-staging-deployer`. Dê a ela, **somente no projeto de staging**, `Cloud Run Admin` (`roles/run.admin`), `Firebase Hosting Admin` (`roles/firebasehosting.admin`), `Firebase Rules Admin` (`roles/firebaserules.admin`), `API Keys Viewer` (`roles/serviceusage.apiKeysViewer`) e `Service Usage Consumer` (`roles/serviceusage.serviceUsageConsumer`). Conceda `Artifact Registry Writer` (`roles/artifactregistry.writer`) no repositório criado e `Service Account User` (`roles/iam.serviceAccountUser`) apenas na conta de serviço runtime. `Cloud Run Admin` é necessário porque o workflow cria uma API pública para os links individuais; consulte as [permissões Cloud Run](https://docs.cloud.google.com/run/docs/securing/managing-access), [roles Firebase](https://firebase.google.com/docs/projects/iam/roles-predefined-product) e [roles do Artifact Registry](https://docs.cloud.google.com/artifact-registry/docs/access-control).
8. Configure Workload Identity Federation, sem chave de serviço:
   - Em **IAM e administrador → Workload Identity Federation**, crie o pool `github-actions` e um provedor OIDC para GitHub Actions (`https://token.actions.githubusercontent.com/`).
   - Mapeie os atributos `google.subject=assertion.sub`, `attribute.repository_id=assertion.repository_id`, `attribute.repository_owner_id=assertion.repository_owner_id` e `attribute.ref=assertion.ref`.
   - Restrinja a condição a este repositório e à branch principal: `assertion.repository_id == '1444917641' && assertion.repository_owner_id == '63379011' && assertion.ref == 'refs/heads/main'`. Os IDs numéricos reduzem o risco de confiar somente em nomes de repositório/organização que poderiam ser reutilizados; siga a [documentação WIF para pipelines GitHub](https://docs.cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines).
   - Na conta `github-staging-deployer`, conceda `Workload Identity User` (`roles/iam.workloadIdentityUser`) ao principal federado `principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/attribute.repository_id/1444917641`, substituindo `PROJECT_NUMBER` pelo número do projeto de staging.
9. No GitHub, abra **Settings → Environments → New environment**, crie `staging`, limite deployments à branch `main` e configure revisor obrigatório quando a modalidade do repositório oferecer essa proteção. O repositório atual é público; consulte as [proteções de ambiente do GitHub](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments).
10. Cadastre no Environment `staging` as variáveis listadas abaixo. `GCP_WORKLOAD_IDENTITY_PROVIDER` deve ter o nome completo `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions/providers/github`; `GCP_DEPLOYER_SERVICE_ACCOUNT` é o e-mail da conta criada. Os dados de configuração Firebase Web são públicos e não substituem as regras IAM/Firestore.

Não execute o workflow após criar a infraestrutura sem revisar project ID, URL e variáveis. A execução é manual e publica os artefatos e regras no projeto configurado.

O projeto informado pelo GitHub é `Alanpss/AmigoSecretoFlutter` (repository ID `1444917641`, owner ID `63379011`). Esses IDs estão usados na condição WIF acima; se o repositório mudar, atualize a condição e o mapeamento.

### Workflow manual de staging

O arquivo `.github/workflows/deploy-staging.yml` prepara uma publicação manual e separada da CI. Antes de habilitá-lo, configure no GitHub um Environment `staging` com revisores obrigatórios e estas variáveis: `GCP_PROJECT_ID`, `GCP_REGION`, `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOYER_SERVICE_ACCOUNT`, `CLOUD_RUN_RUNTIME_SERVICE_ACCOUNT`, `ARTIFACT_REGISTRY_REPOSITORY`, `CLOUD_RUN_SERVICE`, `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_AUTH_DOMAIN` e `PUBLIC_BASE_URL`. Use os valores do app Web real, nunca os valores `demo-*`. A chave Firebase Web identifica o app cliente e fica visível no bundle Web; não coloque credenciais de serviço nessas variáveis.

O workflow só aceita o projeto identificado como staging, exige a entrada manual `yes`, autentica o deploy com Workload Identity Federation, envia a imagem da API ao Artifact Registry, atualiza o Cloud Run e publica Web e regras no Firebase Hosting/Firestore daquele projeto. O serviço Cloud Run fica público para receber revelações e chamadas do app; a API valida o ID token do Firebase e a propriedade do evento nas ações administrativas. Use uma conta de serviço de execução dedicada com `roles/datastore.user` no projeto Firestore; restrinja a federação ao repositório e à branch `main`. A CLI Firebase usa Application Default Credentials da federação; não crie nem commite chave JSON de serviço. Consulte [identidade de serviço do Cloud Run](https://docs.cloud.google.com/run/docs/configuring/services/service-identity), [permissões Firestore](https://firebase.google.com/docs/firestore/security/iam) e [autenticação CI da Firebase CLI](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems).

O workflow executa smoke checks HTTP para `/health` da API e a raiz do Hosting após publicar. Para reversão, selecione uma versão anterior no histórico de Hosting e direcione o tráfego Cloud Run para uma revisão anterior pelo console do Google Cloud; verifique de novo a URL pública e a saúde da API.

## 6. Verificação antes da produção

1. Publique primeiro em staging com dados fictícios. Confirme que o login abre o Google real e retorna ao domínio Hosting, que o estado de autenticação persiste após recarga e que o serviço recebe o ID token.
2. Crie, sorteie, revele, revogue e exclua um evento fictício. Confirme que a tela administrativa não mostra os pares, os links revogados falham e regras Firestore bloqueiam leitura anônima.
3. Verifique no Firebase Authentication os domínios autorizados e no Cloud Run a identidade de execução. Confirme que a revisão Cloud Run não tem `FIREBASE_AUTH_EMULATOR_HOST` e que o build Web foi produzido com `USE_FIREBASE_EMULATORS=false`.
4. Confirme saúde em `/health`, HTTPS, rotas Flutter após recarga, logs sem dados pessoais/tokens e procedimento de reversão.
5. Só então configure o ambiente de produção separado e solicite autorização explícita antes de executar qualquer publicação pública.

O workflow de staging é apenas preparação versionada e ainda não foi executado. O projeto Firebase e o Firestore existem; Google Authentication e os domínios principais estão configurados e o login real funcionou no build local. Billing, recursos Cloud Run, IAM/WIF e validação ponta a ponta do modo online continuam pendentes; produção e abertura pública permanecem bloqueadas até essa configuração e autorização específica.
