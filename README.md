# AmigoSecretoFlutter

Aplicativo Flutter para organizar eventos de amigo secreto, gerenciar participantes e grupos e realizar sorteios que respeitam todas as restrições configuradas.

> **Estado:** Fases 1–6 aceitas pelo usuário. O modo online oferece API Dart, autenticação Firebase, armazenamento Firestore via REST, grupos e revelação por links individuais; fluxo e testes foram validados localmente com os Emulators. Nenhum projeto cloud foi configurado nem publicado. Consulte [`docs/PROGRESSO.md`](docs/PROGRESSO.md) para detalhes e limitações.

## Descrição para o GitHub

> Aplicativo Flutter local-first para organizar amigo secreto, aplicar restrições de grupos e salvar sorteios com resultados ocultos e revelação individual.

## Sobre o projeto

O AmigoSecretoFlutter é um projeto de portfólio e estudo de desenvolvimento de aplicativos com Flutter. A experiência é voltada a um organizador, em português do Brasil. O modo local não usa backend. O modo online foi validado localmente com Firebase Emulator, mas ainda não tem projeto real configurado nem foi publicado.

O projeto dá atenção especial à integridade do sorteio: restrições de grupos não são removidas silenciosamente, os resultados são persistidos antes de qualquer etapa de envio e ficam ocultos até a revelação individual.

### Implementado

- Aplicativo Web responsivo, com interface em português do Brasil.
- Modo de evento online com sorteio no servidor e links individuais, validado localmente com Firebase Emulator; ainda não publicado.
- Cadastro de eventos, pessoas, participantes, responsáveis e grupos.
- Busca, filtros e revisão das condições do evento.
- Motor Dart puro com matching bipartido, diagnóstico e amostragem uniforme entre sorteios válidos.
- Persistência local transacional, proteção por revisão, bloqueio de edição após o sorteio e invalidação com histórico preservado.
- Resultados ocultos por padrão, com revelação individual.
- Editor de modelo com variáveis validadas e prévia com dados fictícios.
- Fila de entregas com cópia, link `wa.me`, confirmação manual e filtro de pendências; a abertura é testada com launcher simulado.
- Exportação e importação de backup JSON versionado, com prévia, validação de referências e substituição transacional.
- Aviso para exportar após o sorteio e atalho para backup; a tela de falha do banco também oferece restauração de um arquivo validado.

### Em desenvolvimento

- Investigar emojis exibidos como caracteres de substituição após o redirecionamento do link `wa.me`; nenhum envio real foi feito.

O plano completo e os critérios de aceite estão em [`docs/PLANO_IMPLEMENTACAO.md`](docs/PLANO_IMPLEMENTACAO.md).

## Requisitos para desenvolvimento

- Flutter **3.47.9 stable** ou compatível com o SDK Dart declarado em `pubspec.yaml`.
- Git.
- Chrome ou Edge para executar e conferir o aplicativo Web.

> A versão de Flutter usada na verificação atual está registrada em [`docs/AMBIENTE.md`](docs/AMBIENTE.md). O projeto não exige Android Studio nem Android SDK para o fluxo Web.

## Configuração local

Clone o repositório e entre na pasta do projeto:

```bash
git clone https://github.com/Alanpss/AmigoSecretoFlutter.git
cd AmigoSecretoFlutter
```

Instale as dependências:

```bash
flutter pub get
```

Execute no Chrome:

```bash
flutter run -d chrome --web-port 8080
```

Se o Chrome não estiver configurado como dispositivo Flutter, use o servidor Web:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Abra o endereço informado pelo Flutter. Use a mesma origem e porta ao retomar o desenvolvimento: no Web, os dados locais ficam no IndexedDB associado à origem do navegador.

## Verificações antes de enviar alterações

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

O teste de integração cobre o fluxo de evento, participante, grupo e persistência no Web. Para executá-lo no Chrome:

```bash
flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart
```

Não registre no Git dados reais de participantes, resultados de sorteios, telefones, bancos locais, backups ou segredos. O `.gitignore` cobre artefatos comuns de build, bancos locais e backups.

## Arquitetura

O código separa a interface, o domínio e a persistência por funcionalidade. A lógica do sorteio não depende de widgets ou de serviços externos.

```text
lib/
  app/             composição, tema, rotas e providers
  core/            banco, migrações e erros compartilhados
  features/
    events/        eventos e revisão
    participants/  pessoas, participantes e responsáveis
    groups/        grupos e restrições
    draw/          matching compartilhado, persistência e apresentação do sorteio
    delivery/      modelos, links e acompanhamento manual das entregas
    settings/      configurações
    backup/        serialização, validação, arquivos e restauração
  shared/          layout e widgets reutilizáveis
test/              testes de domínio, dados e interface
docs/                 contexto, requisitos, arquitetura, plano e progresso
packages/draw_engine/ motor de sorteio Dart puro compartilhado
server/               domínio inicial do serviço online em Dart
```

**Tecnologias principais:** Flutter/Dart, Riverpod, `go_router` e Sembast; IndexedDB é usado para persistência local no Web. O pacote Dart puro do sorteio é compartilhado com o serviço HTTP em `server/`; o modo online usa Firebase Authentication e Firestore. As versões resolvidas estão nos arquivos `pubspec.lock` correspondentes.

### Configurar modo online (desenvolvimento local)

O modo local não precisa dessas configurações. Para experimentar o modo online, instale Firebase CLI e Java (necessários para os emuladores), depois, na raiz do repositório, inicie os emuladores:

```powershell
firebase emulators:start --only auth,firestore --project demo-amigosecreto
```

Em outro terminal, inicie o serviço Dart apontando para os emuladores. `demo-key` é um valor fictício aceito somente pelo Auth Emulator:

```powershell
Set-Location .\server
$env:GOOGLE_CLOUD_PROJECT = 'demo-amigosecreto'
$env:FIREBASE_WEB_API_KEY = 'demo-key'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:PUBLIC_BASE_URL = 'http://127.0.0.1:8081'
$env:PORT = '8090'
dart pub get
dart run bin/server.dart
```

No modo Emulator, o servidor usa o token local especial `owner` para simular a identidade administrativa do Cloud Run. Essa credencial só é selecionada quando `FIRESTORE_EMULATOR_HOST` está definido; nunca a use fora dos emuladores.

Em outro terminal, a partir da raiz do repositório, execute o Flutter Web com os valores de Firebase fornecidos pelo projeto de desenvolvimento ou pelo Auth Emulator:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081 --dart-define=FIREBASE_API_KEY=demo-key --dart-define=FIREBASE_APP_ID=demo-app --dart-define=FIREBASE_MESSAGING_SENDER_ID=demo-sender --dart-define=FIREBASE_PROJECT_ID=demo-amigosecreto --dart-define=ONLINE_DRAW_API_BASE_URL=http://localhost:8090 --dart-define=USE_FIREBASE_EMULATORS=true
```

Abra `http://127.0.0.1:8081` no Chrome. Emissor de link e navegador devem usar o mesmo host; nesta configuração, use `127.0.0.1` e não `localhost`.

No formulário online, os grupos são configurados separadamente dos eventos locais: escolha o tipo, marque os participantes e indique se a restrição está ativa. Após um sorteio, “Refazer sorteio e invalidar links atuais” pede confirmação e gera uma nova revisão; os links antigos deixam de funcionar. O organizador precisa entrar para gerenciar o evento, mas participantes abrem seus links sem login.

Os dados e IDs acima são fictícios. Para autenticação Google real, registre o domínio de teste em Firebase Authentication e substitua as opções pelos valores do app Web. Nunca use dados reais nos emuladores nem commite chaves, tokens ou arquivos de credenciais. O projeto Firebase, configuração definitiva, custos e deploy ficam fora desta etapa. Consulte [`docs/AMBIENTE.md`](docs/AMBIENTE.md) e [`docs/DEPLOY.md`](docs/DEPLOY.md).

## Desenvolvimento assistido por IA

O aplicativo **não usa IA durante a execução**. Ferramentas de IA são usadas como apoio ao desenvolvimento e devem seguir as mesmas regras de revisão e qualidade do restante do código.

- [`AGENTS.md`](AGENTS.md) define o fluxo obrigatório para agentes: leitura da documentação, respeito à fase autorizada, mudanças pequenas, testes e atualização do progresso.
- Regras de sorteio e persistência devem permanecer em Dart testável, independente da interface.
- Sugestões geradas por IA precisam ser verificadas contra os requisitos e testes; uma resposta do modelo não substitui validação.
- Exemplos, testes e demonstrações usam dados fictícios. Não inserir dados pessoais, tokens ou backups em prompts, logs ou commits.
- Decisões de produto e arquitetura devem ser registradas nos documentos ou ADRs correspondentes.

## Documentação do projeto

| Documento | Conteúdo |
| --- | --- |
| [`docs/CONTEXTO.md`](docs/CONTEXTO.md) | Objetivo, escopo, premissas e privacidade |
| [`docs/REQUISITOS.md`](docs/REQUISITOS.md) | Regras do domínio e critérios de aceite |
| [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) | Camadas, dados, algoritmos e fluxos |
| [`docs/PLANO_IMPLEMENTACAO.md`](docs/PLANO_IMPLEMENTACAO.md) | Fases, escopo e portões de aceite |
| [`docs/PROGRESSO.md`](docs/PROGRESSO.md) | Estado real, verificações e próximo passo |
| [`docs/DEPLOY.md`](docs/DEPLOY.md) | Preparação do artefato Web e requisitos de hospedagem estática; não publicado |
| [`docs/AMBIENTE.md`](docs/AMBIENTE.md) | Ferramentas e configuração de desenvolvimento |
| [`docs/TESTES.md`](docs/TESTES.md) | Estratégia, cenários e comandos |
| [`docs/decisions/`](docs/decisions/) | Registros das decisões arquiteturais (ADRs) |

## Privacidade e limitações

- Eventos locais ficam no navegador. No modo online, o servidor guarda resultados e hashes de links; o rascunho de participantes e os links gerados ficam localmente no mesmo navegador para retomada e não entram no backup local. Limpar os dados do site pode apagar esse rascunho. O organizador ou qualquer pessoa que obtenha um link bearer ainda poderá abrir aquele resultado.
- O armazenamento Web não é criptografado. Limpar os dados do navegador ou mudar de origem pode remover o acesso aos eventos.
- Telefones, responsáveis e resultados são dados pessoais. Use dados fictícios em desenvolvimento e guarde backups não criptografados em locais seguros.
- Abrir o WhatsApp não comprova envio, entrega ou leitura. O projeto não automatiza o WhatsApp.

## Licença

Ainda não foi definida uma licença para reutilização ou distribuição. A ausência de arquivo `LICENSE` não concede permissões adicionais de uso.
