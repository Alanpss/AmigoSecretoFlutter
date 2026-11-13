# Progresso

**Última atualização:** 2026-11-13
**Fase atual:** Fase 8 — Ambiente Docker e automação de publicação **autorizada, em andamento**
**Fase anterior:** Fase 7 — Cópia e gestão de eventos online **aceita pelo usuário em 2026-11-12; commit `b5b9b68`**
**Implementação:** Fases 1–7 aceitas; preparação Docker/CI da Fase 8 em andamento
**Instalações realizadas:** Flutter 3.47.9 stable no escopo do usuário

Este documento é a fonte de verdade para o **estado real do trabalho** e para o ponto exato de retomada. Em caso de divergência com outros documentos, vale o que está registrado aqui; o conflito deve ser resolvido antes de continuar.

## 1. Situação em uma frase

As Fases 1 a 7 foram aceitas pelo usuário, com limitações de verificação registradas. A Fase 7 foi concluída após implementar cópias entre modos, gestão de vários eventos online e validar os fluxos pendentes manualmente no Chrome.

## 2. Situação por fase

| Fase | Situação | Evidência | Próxima ação |
| --- | --- | --- | --- |
| 0 — Planejamento | Concluída | Documentos listados na seção 5 | Nenhuma |
| 1 — Ambiente e fundação | Concluída | Seções 6 a 9 | Nenhuma |
| 2 — Cadastro e organização | Concluída | Critérios e verificações nas seções 16 e 17 | Nenhuma |
| 3 — Sorteio e integridade | Aceita | Testes automatizados passaram; usuário confirmou revisão manual de teclado, foco, leitor de tela e contraste | Nenhuma |
| 4 — WhatsApp e entregas | Liberada para transição pelo usuário | Link aberto manualmente com contato fictício; nenhum envio feito. Após redirecionamento do WhatsApp, emojis apareceram como caractere de substituição; investigar antes de considerar essa experiência validada | Verificar o comportamento em navegador compatível e corrigir se reproduzível no URI gerado pelo app |
| 5 — Acabamento e backup | Aceita pelo usuário em 2026-11-05 | O usuário confirmou “tudo certo” e autorizou a próxima fase após abrir a versão release no Chrome. Testes automatizados, análise, formatação e build aprovados. A automação não validou Edge/leitor de tela/zoom manual | Nenhuma; limitações de verificação registradas |
| 6 — Sorteio online e links individuais | Aceita pelo usuário em 2026-11-12 | Testes automatizados Emulator/Flutter passaram; usuário confirmou no Chrome grupos/restrições, repetição, invalidação de links antigos, token inválido e sorteio impossível | Nenhuma; deploy e projeto real seguem sem autorização |
| 7 — Cópia e gestão de eventos online | Aceita pelo usuário em 2026-11-12 | Testes automatizados e validações manuais Chrome confirmadas pelo usuário, incluindo múltiplos eventos, cópias, saída, cancelamento e exclusão com invalidação de links | Nenhuma |
| 8 — Ambiente Docker e automação de publicação | Autorizada em 2026-11-12; parcial/em andamento | Compose, builds, serviços e perfis de teste Flutter/API passaram localmente; seção 41 | Validar login/persistência pela interface no Chrome e execução do CI no GitHub |

## 3. Ponto exato de retomada

Fases 6 e 7 aceitas em 2026-11-12 após confirmações do usuário sobre os cenários manuais pendentes no Chrome. A Fase 7 foi commitada em `b5b9b68`. O usuário autorizou iniciar a Fase 8 após esse commit. Nenhum projeto cloud foi criado, nenhum deploy feito e nenhuma mensagem real enviada.

## 4. Escopo entregue na Fase 1

| Item | Situação |
| --- | --- |
| Flutter SDK 3.47.9 stable instalado no perfil do usuário | Concluído |
| `PATH` de usuário com `...\flutter\bin` | Concluído |
| `flutter doctor -v`, `flutter devices` e `flutter config --enable-web` | Executados |
| Projeto Flutter Web criado sem sobrescrever a documentação | Concluído |
| Dependências da fase (Riverpod, go_router, Sembast, path_provider, intl, localizações) | Adicionadas |
| Tema Material 3 e localização pt-BR | Concluído |
| Rotas `/` e `/settings` com shell responsivo | Concluído |
| Abertura do banco antes da interface, `schemaVersion = 1` | Concluído |
| Tela de falha do banco com “Tentar novamente” | Concluído |
| Testes de fumaça, layout compacto, banco e falha do banco | 6 testes passando |
| `flutter analyze` e `dart format` | Limpos |
| `flutter build web --release` | Concluído |
| Verificação manual de execução e persistência no navegador | Concluída, com ressalva de automação registrada na seção 10 |

Fora do escopo desta fase e **não implementados**: sorteio; geração/entrega de mensagens; WhatsApp; backup; Android; backend; autenticação; publicação.

## 5. O que foi produzido na Fase 0

| Arquivo | Conteúdo | Fonte de verdade para |
| --- | --- | --- |
| `README.md` | Visão geral, plataforma recomendada, mapa da documentação, privacidade e próximos passos | Entrada do projeto |
| `AGENTS.md` | Regras de leitura, fases, mudanças, verificação, segurança e domínio | Processo de trabalho de agentes de IA |
| `docs/CONTEXTO.md` | Escopo, premissas, decisões consolidadas, limitações e privacidade | Escopo do produto |
| `docs/REQUISITOS.md` | Requisitos funcionais, regras de negócio, critérios de aceite e casos limite | Comportamento funcional |
| `docs/ARQUITETURA.md` | Plataforma, camadas, estado, navegação, persistência, modelo, algoritmo e fluxos | Estrutura e decisões técnicas |
| `docs/PLANO_IMPLEMENTACAO.md` | Fases 0–5, escopo, checklists, arquivos, critérios, testes, riscos e portões | Sequência de implementação |
| `docs/PROGRESSO.md` | Este estado real e ponto de retomada | Estado do trabalho |
| `docs/AMBIENTE.md` | Ferramentas detectadas, instalação, verificação e diagnóstico | Ambiente e dependências |
| `docs/TESTES.md` | Estratégia, cenários obrigatórios, dados fictícios e comandos | Verificação |
| `docs/decisions/` | ADRs 001–005 e índice | Justificativa das decisões |

## 6. Ambiente de referência em 2026-11-03

| Item | Resultado |
| --- | --- |
| Sistema | Windows 11 Home Single Language, versão 10.0.26300, 64 bits |
| Conta | Perfil de usuário sem privilégios administrativos |
| Flutter | **3.47.9 stable**, em `%USERPROFILE%\development\flutter` |
| Dart | **3.13.7** (incluído no Flutter) |
| DevTools | 2.60.0 |
| Revisão do framework | `c197ca5199` |
| Revisão do engine | `89c39edfdf` |
| `PATH` do usuário | Contém `%USERPROFILE%\development\flutter\bin` |
| Dispositivos detectados | Windows desktop, Chrome 156.0.8078.80, Edge 156.0.4314.58 |
| Android SDK / Studio | Ausentes; fora do MVP desta fase |
| Visual Studio (desktop) | Ausente; fora do escopo |
| Git | 2.49.0.windows.1 |
| VS Code | 1.144.1 |

O ZIP oficial baixado tinha 1.849,6 MB e o SHA-256 conferiu com o valor oficial `d8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e` antes da extração.

**Diretório do projeto:** raiz do clone deste repositório. Os comandos deste documento devem ser executados a partir dela; nenhum caminho específico do computador é necessário.

## 7. Dependências resolvidas

| Pacote | Versão resolvida | Uso na Fase 1 |
| --- | --- | --- |
| `flutter_riverpod` | 3.4.3 | Estado e injeção do banco |
| `go_router` | 18.1.2 | Rotas `/` e `/settings` |
| `sembast` | 3.10.0 | Banco local |
| `sembast_web` | 2.4.6+1 | Banco no IndexedDB (Web) |
| `path_provider` | 2.1.6 | Diretório do banco em plataformas com sistema de arquivos |
| `intl` | 0.20.3 | Formatação pt-BR nas próximas fases |
| `flutter_localizations` | SDK | Textos Material em pt-BR |
| `flutter_lints` | 6.0.0 (dev) | Lint |

O `pubspec.lock` foi gerado e deve ser versionado. O `pubspec.yaml` foi limpo apenas na descrição do projeto; comentários padrão do `flutter create` permanecem.

## 8. Estrutura de código criada

```text
lib/main.dart
lib/app/app.dart
lib/app/bootstrap.dart
lib/app/providers.dart
lib/app/router.dart
lib/app/theme.dart
lib/core/database/app_database.dart
lib/core/database/database_factory.dart
lib/core/database/database_factory_io.dart
lib/core/database/database_factory_stub.dart
lib/core/database/database_factory_web.dart
lib/core/database/migrations.dart
lib/core/errors/app_error.dart
lib/features/events/presentation/events_home_page.dart
lib/features/settings/presentation/settings_page.dart
lib/shared/layout/app_shell.dart
lib/shared/widgets/empty_state.dart
lib/shared/widgets/not_found_page.dart
test/app/app_smoke_test.dart
test/app/database_failure_test.dart
test/core/database/app_database_test.dart
```

Decisões de implementação relevantes:

- `bootstrap()` abre e migra o banco **antes** de `runApp`; falhas mostram `DatabaseFailureApp`, sem apagar dados.
- O banco é injetado por `ProviderScope` via `appDatabaseProvider`; testes usam `databaseFactoryMemory`.
- A fábrica de banco usa importação condicional (`io` → arquivo; `js_interop` → IndexedDB) e um stub seguro para plataformas não suportadas.
- O shell usa `NavigationBar` abaixo de 600 px e `NavigationRail` a partir de 600 px.
- A rota desconhecida exibe `NotFoundPage` com retorno para `/`.
- A interface está inteiramente em pt-BR e o `MaterialApp` fixa `Locale('pt', 'BR')`.

## 9. Verificações executadas na Fase 1

| Verificação | Comando/método | Resultado |
| --- | --- | --- |
| Versão do SDK | `flutter --version` | Flutter 3.47.9 stable; Dart 3.13.7; DevTools 2.60.0 |
| Diagnóstico | `flutter doctor -v` | Flutter e Windows OK; Android e Visual Studio ausentes (esperado) |
| Web habilitada | `flutter config --enable-web` | `enable-web` = `true` |
| Dispositivos | `flutter devices` | Windows, Chrome 156.0.8078.80 e Edge 156.0.4314.58 |
| Dependências | `flutter pub get` (via `pub add`) | Resolvidas; lock gerado |
| Formatação | `dart format .` | 21 arquivos, 0 alterações na última execução |
| Análise estática | `flutter analyze` | **No issues found!** |
| Testes | `flutter test` | **6 testes passando** |
| Build de produção | `flutter build web --release` | Concluído; aviso de dry run Wasm e tree-shaking de fontes |
| Execução em desenvolvimento | `flutter run -d web-server --web-port 8080` | App servido; bootstrap abriu o banco |
| Execução no Chrome | `flutter run -d chrome --web-port 8081` | Serviço de depuração conectado; app iniciou |
| Persistência | IndexedDB via DevTools/CDP | Base `amigo_secreto`; `meta.schemaVersion = 1`; `createdAt` mantido após recarregar |
| Renderização visual | Chrome headless + CDP, build release | Layout desktop (1280×900) e compacto (390×844) corretos, sem erros de console |

Detalhes dos testes (6 casos):

- `test/app/app_smoke_test.dart`: estado vazio + navegação para Configurações; uso de `NavigationBar` em tela compacta.
- `test/core/database/app_database_test.dart`: versão e metadados idempotentes; transação com erro não grava nada.
- `test/app/database_failure_test.dart`: tela segura quando o banco falha; ação “Tentar novamente” dispara a nova tentativa.

## 10. Limitações e ressalvas conhecidas

- **Screenshot no navegador embutido:** a aba automatizada não dispara `requestAnimationFrame` quando a janela do aplicativo desktop não está visível, então o Flutter não pinta quadros nessa aba e o screenshot nativo falha com “Screenshot needs a visible tab”. A verificação visual foi feita no mesmo build com Chrome headless via CDP, que renderizou corretamente. Isso é limitação do ambiente de automação, não do aplicativo.
- **Desvio de porta na execução manual:** o critério citava `flutter run -d chrome --web-port 8080`; a porta 8080 já estava ocupada pelo servidor web de desenvolvimento, então o Chrome foi executado na porta 8081. A origem 8080 foi validada com `-d web-server`, e a persistência do IndexedDB foi confirmada nela.
- **Rotas profundas em hospedagem estática:** o servidor estático simples usado na verificação devolveu 404 para `/settings`. A hospedagem da Fase 5 deve configurar fallback de SPA para `index.html`; o roteamento interno do `go_router` funciona no app.
- **Tema:** a verificação visual ocorreu com o tema escuro (preferência do navegador headless); o tema claro usa a mesma estrutura e os testes de widget não dependem de cor.
- **Armazenamento Web:** IndexedDB é vinculado à origem. Limpar dados do navegador apaga a organização; o backup só existe a partir da Fase 5.

## 11. Decisões consolidadas

- Plataforma inicial: **Flutter Web (PWA)**, com Android como evolução posterior.
- Sem backend no MVP.
- Persistência local com **Sembast** (`sembast_web` na Web).
- Estado com **Riverpod** sem code generation; navegação com **go_router**.
- Modelo **Pessoa reutilizável + Participante por evento**.
- Responsável é uma pessoa referenciada diretamente, sem cadeia e sem criar restrição.
- Restrições são a união de grupos com restrição ativa.
- Sorteio por matching bipartido completo + amostragem uniforme entre soluções válidas.
- WhatsApp por link universal `wa.me`, com confirmação manual do organizador.
- Backup JSON versionado, sem criptografia, tratado como sensível.

Detalhes e justificativas: `docs/CONTEXTO.md`, `docs/ARQUITETURA.md` e `docs/decisions/`.

## 12. Pendências e decisões que bloqueiam fases

| Pendência | Bloqueia | Padrão recomendado | Situação |
| --- | --- | --- | --- |
| Definir se Android entra no MVP | Fase 3 em diante | Fora do MVP | Aguardando; não bloqueia Web |
| Autorização da Fase 3 | Fase 3 | Pedido “pode implementar a próxima” após aceite da Fase 2 | **Autorizada em 2026-11-03** |
| Definir hospedagem/publicação e fallback de SPA | Fase 5 | Só com autorização | Aguardando |
| Confirmar limite de 200 participantes ativos | Fase 3 | 200 | Premissa |
| Confirmar exclusão definitiva de evento | Fase 2 | Exclusão com confirmação | Premissa adotada |
| Confirmar backup sem senha | Fase 5 | Aceitável com aviso | Premissa |

## 13. Riscos e observações

- **Instalação:** a sessão não é administrativa. O SDK está no perfil do usuário; não mover para `C:\Program Files`.
- **Atualização do SDK:** não atualizar no meio de uma fase sem autorização e registro.
- **Armazenamento Web:** IndexedDB é vinculado à origem e pode ser limpo. O backup será a única recuperação.
- **WhatsApp:** abrir a conversa não comprova envio; não haverá automação não oficial.
- **Dados reais:** nenhum dado pessoal real foi usado. Exemplos e testes devem continuar fictícios.
- **Repositório raiz:** há alterações não relacionadas; não revertê-las nem apagá-las.
- **Publicação:** nenhum deploy, commit ou envio de mensagem foi realizado.

## 14. Próxima ação

A Fase 7 foi aceita e commitada em `b5b9b68`. A Fase 8 está autorizada e em andamento. Compose, builds, serviços e testes conteinerizados passaram localmente; faltam fluxo Web via Chrome e execução do CI no GitHub. Não acionar o workflow de staging nem publicar sem autorização/configuração específica do projeto.

## 15. Histórico

| Data | Evento | Resultado |
| --- | --- | --- |
| 2026-11-03 | Inventário do ambiente e revisão da documentação oficial | Ferramentas ausentes identificadas; versões de referência confirmadas |
| 2026-11-03 | Criação da documentação de planejamento | Fase 0 concluída; nenhuma instalação ou código |
| 2026-11-03 | Autorização da Fase 1 pelo usuário | Instalação e criação do esqueleto liberadas |
| 2026-11-03 | Instalação do Flutter 3.47.9 com verificação SHA-256 | SDK extraído no perfil do usuário; `PATH` atualizado |
| 2026-11-03 | Criação do projeto Flutter Web e implementação do esqueleto | Tema, rotas, banco, shell e testes criados |
| 2026-11-03 | Verificações finais da Fase 1 | 6 testes, análise limpa, build release e renderização Web confirmados |
| 2026-11-03 | Autorização para continuar a implementação | Fase 2 liberada pelo pedido do usuário |
| 2026-11-03 | Aceite da Fase 2 e autorização da próxima | Critérios verificados; Fase 3 autorizada pelo usuário |
| 2026-11-03 | Implementação principal da Fase 3 | Motor, persistência atômica e telas implementados; testes automatizados e fluxo visual manual verificados; aceite de acessibilidade pendente |
| 2026-11-03 | Implementação parcial da Fase 4 | Editor, links, fila e confirmação manual implementados; testes automatizados e build aprovados; revisão manual de navegador ainda pendente |

## 16. Fase 2 — implementação e aceite

O código contém modelos e repositórios para eventos, pessoas, participantes e grupos; migração do schema 1 para 2; rotas e formulários em pt-BR; resolução direta de responsável; criação inline de contato/grupo; busca, filtros, confirmações e revisão básica de pendências. Os critérios da fase foram aceitos após testes e validações manuais. O detalhe está em `docs/PLANO_IMPLEMENTACAO.md`, seção 5.

Os testes cobrem criação de evento/participante/grupo, migração 1→2, transações, validações, responsáveis, unicidade, revisão e preservação de dados ao criar grupo inline. Busca/filtro, aviso duplicado, contato responsável, persistência após recarga e layouts foram conferidos manualmente. Uma tentativa automatizada isolada de busca/filtro ficou presa no `pumpAndSettle`; foi retirada após a mesma função passar na verificação manual.

## 17. Verificações desta continuação

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Formatação | `dart format .` | 64 arquivos; 0 alterações na rodada final |
| Formatação final | `dart format --output=none --set-exit-if-changed .` | 64 arquivos; 0 alterações |
| Análise | `flutter analyze` | Sem issues |
| Testes | `flutter test` | 36 testes passaram |
| Build Web release | `flutter run -d web-server --release --web-port 8787` | Build concluído em 85,2 s; servidor local usado para validação manual |

**Intercorrências:** as tentativas de automatizar o formulário de duplicidade e a busca/filtro com testes isolados de widget ficaram presas no harness durante `pumpAndSettle`; não foi possível atribuir causa ao app. A suíte final de 36 testes passou. Os mesmos fluxos foram verificados manualmente no navegador local.

**Verificações manuais adicionais:** criado evento e participantes fictícios em `http://127.0.0.1:8787`; o evento, responsáveis, telefones, situação e participantes permaneceram após recarregar. Busca por apelido, filtro de inativos, aviso de nome/telefone duplicados e salvamento após a confirmação foram demonstrados. O responsável externo foi resolvido pelo telefone direto. A interface foi conferida em viewport 360×800 e desktop. Não foram usados dados pessoais reais.

## 18. Fase 3 — implementação em andamento

**Escopo implementado nesta continuação:** algoritmo puro Hopcroft–Karp e amostragem uniforme por caminhos alternados; diagnóstico sem relaxamento automático; migração do schema 2 para 3; persistência transacional de draw, assignments e deliveries; snapshots do dono, sorteado, destinatário, telefone, mensagem e data; verificação de `pairingRevision`; idempotência para retry com o mesmo ID; bloqueio de alterações nos repositórios de participantes, pessoas e grupos; invalidação com preservação do histórico; rota e tela com confirmação e revelação individual.

**Preparação do repositório:** README reorganizado para GitHub com descrição curta, requisitos, configuração, comandos, arquitetura, estado real, política de desenvolvimento assistido por IA e limitações; caminhos de máquina e identificador da conta local foram generalizados na documentação. O `pubspec.yaml` agora descreve apenas recursos já implementados. O repositório Git independente foi inicializado e publicado no remoto `origin`; o commit inicial `0383fad` está em `main` e a cópia local estava limpa após o push.

**Verificações executadas:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Formatação | `dart format .` | 73 arquivos; 1 arquivo formatado |
| Formatação final | `dart format --output=none --set-exit-if-changed .` | 73 arquivos; sem alterações |
| Análise | `flutter analyze` | Sem issues |
| Testes | `flutter test` | 45 testes passaram |
| Build | `flutter build web --release` | Concluído; build Web gerado; compilação em 71,5 s |
| Casos focados | `flutter test test/features/draw test/core/database/app_database_test.dart` | 12 testes passaram |

**Verificação manual do fluxo em 360×800:** em origem local temporária, criados evento e três participantes com nomes fictícios; a revisão permitiu o sorteio e explicou que os contatos ausentes geram entrega manual; confirmação explícita gravou resultado; os três resultados estavam ocultos; revelar um cartão mostrou apenas seu destinatário; recarregar a rota manteve o mesmo sorteio e tornou a ocultá-lo novamente; tentar editar participante mostrou bloqueio e atalho para a tela de sorteio; a invalidação exibiu contagens (zero conversas abertas e zero envios confirmados) e voltou a habilitar novo sorteio. Não houve envio externo. O servidor local foi encerrado ao fim da verificação.

**Situação naquele ponto:** ainda faltavam testes estáveis da UI e revisão de acessibilidade. A seção 19 acrescentou a cobertura automatizada; a revisão manual foi concluída e aceita pelo usuário na seção 20.

### Verificação e preparação para publicação em 2026-11-03

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Formatação | `dart format .` | 73 arquivos; nenhuma alteração |
| Formatação final | `dart format --output=none --set-exit-if-changed .` | Sem alterações |
| Análise | `flutter analyze` | Sem issues |
| Testes unitários e de widget | `flutter test` | 45 testes passaram |
| Integração (comando genérico) | `flutter test integration_test` | Não executou: há mais de um dispositivo e o comando exige seleção explícita |
| Integração Web (Chrome) | `flutter test integration_test -d chrome` | Não suportado pelo runner: dispositivos Web não são aceitos nesse modo |
| Integração Windows | `flutter test integration_test -d windows` | Não executou: o projeto não tem plataforma Windows configurada |
| Integração Web (driver) | `flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart` | Aguardou conexão do serviço de depuração por cerca de um minuto; encerrado sem resultado. Comando atualizado no README e neste documento para nova tentativa em ambiente com Chrome/driver disponível |
| Build Web release | `flutter build web --release` | Concluído em 74,5 s; build gerado |
| Publicação Git | `git push -u origin main` | Concluído; `origin/main` confirmado em `0383fad` |

Os telefones exibidos nos testes, exemplos e dicas da interface usam faixas fictícias de teste. A execução do fluxo de integração permanece pendente e não deve ser reportada como aprovada. A publicação do repositório foi concluída; o desenvolvimento retomou a Fase 3 na seção seguinte.

## 19. Continuação da Fase 3 — tela de resultado e acessibilidade

**Alterações:** os botões de revelar/ocultar agora têm rótulos semânticos que identificam o participante e área mínima de 48×48 px. Os botões de ação da tela e das confirmações usam altura mínima de 48 px. A revelação continua individual; o texto visível identifica o conteúdo como resultado. Foram adicionados testes de widget para resultado oculto por padrão, revelação de um único cartão, rótulo semântico, alvo de toque e viewport 360×800 com escala de texto 2.0. Outro teste confirma que a tela identifica pelo nome o participante sem opção válida. Testes de domínio cobrem esse diagnóstico e demonstram saída com mais de um ciclo.

**Verificações executadas em 2026-11-03:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Formatação | `dart format --output=none --set-exit-if-changed .` | 74 arquivos; sem alterações após a formatação |
| Análise | `flutter analyze` | Sem issues |
| Testes focados | `flutter test test/features/draw` | 13 testes passaram |
| Suíte completa | `flutter test` | 50 testes passaram |
| Build Web release | `flutter build web --release` | Concluído; compilação em 95,1 s |

**Pendente naquele ponto:** revisão manual de teclado, ordem de foco, leitor de tela e contraste. A seção 20 registra a conclusão dessa revisão e o aceite da Fase 3.

## 20. Aceite da Fase 3 e autorização da Fase 4

Em 2026-11-03, o usuário confirmou que a revisão manual solicitada para teclado, ordem de foco, leitor de tela e contraste ocorreu sem problemas e autorizou o início da próxima fase. A Fase 3 fica aceita. O runner de integração Web permaneceu sem resultado por limitação do ambiente, registrada na seção 18; os testes unitários/widget, a persistência e os fluxos observáveis foram verificados por meios automatizados e manuais.

A Fase 4 está autorizada. Seu escopo segue a seção 7 de `docs/PLANO_IMPLEMENTACAO.md` e o ADR-004: modelo de mensagem validado, destinatário direto, link universal `wa.me`, fila e confirmação manual. Não enviar automaticamente, não usar automação não oficial e não iniciar backup. A próxima ação de implementação está descrita na seção 3.

## 21. Fase 4 — implementação parcial

**Implementado:** parser Dart puro com variáveis permitidas, chaves validadas e limite de 2.000 code points; prévia fictícia; reutilização da normalização E.164 e do resolvedor direto de responsável; URI `wa.me` codificada; launcher injetável com `url_launcher`; fila por entrega individual; abrir, reabrir, copiar, filtrar e confirmar; entrega sem contato para ação manual; transições persistidas; editor que oferece atualizar só pendentes; validação do modelo também na criação/edição do evento.

**Verificações executadas em 2026-11-03:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Dependências | `flutter pub get` | Concluído; `url_launcher 6.3.3` resolvido e lock atualizado |
| Formatação | `dart format --output=none --set-exit-if-changed .` | 85 arquivos; sem alterações |
| Análise | `flutter analyze` | `No issues found!` |
| Testes focados | `flutter test test/features/delivery test/features/participants/domain/phone_number_test.dart test/features/participants/domain/guardian_resolver_test.dart test/features/draw/data/draw_repository_test.dart` | 34 testes passaram |
| Suíte completa | `flutter test` | 73 testes passaram |
| Build Web release | `flutter build web --release` | Concluído em 80,2 s; saída em `build/web` |

**Cobertura acrescentada:** sucesso/falha do launcher fake, status aberto sem confirmação, cópia sem alterar status, filtro de pendentes, confirmação manual sem telefone, telefone/link/modelo e atualização transacional somente de pendentes. Um teste do repositório de sorteio verifica entregas e mensagens individuais para três participantes que compartilham o mesmo responsável.

**Pendente:** verificar visualmente editor e fila no Chrome/Edge em viewport compacto e desktop; testar que o link abre o destino com texto preenchido usando somente telefone fictício, sem enviar a mensagem; conferir cópia e navegação. A tentativa de automação do navegador foi interrompida antes de interagir porque não foi possível identificar com segurança a URL da aba já aberta; nenhum dado foi inserido e nenhuma conversa foi aberta. O teste de integração Web continua pendente pela limitação de Chromedriver já registrada na seção 18. A Fase 4 permanece parcial e a Fase 5 não foi iniciada nem autorizada.

## 22. Autorização da Fase 5

Em 2026-11-03, o usuário pediu para implementar a próxima fase. A Fase 5 fica autorizada e é o escopo atual. A Fase 4 foi liberada para transição por essa solicitação; sua conferência visual de click-to-chat permanece explicitamente não demonstrada e será mantida como limitação, sem afirmar que houve teste manual.

## 23. Fase 5 — backup, recuperação e acabamento

**Implementado:** backup JSON UTF-8 versão 1 com todos os stores, IDs/chaves preservados, limite de 10 MB, validação de esquema e relações, prévia, confirmação explícita e substituição em uma transação. Exportação sugere nome com data e não inclui dados pessoais no nome. A tela de backup avisa sobre telefones/resultados e a tela de resultado recomenda exportar. A tela de falha do banco oferece restauração de arquivo validado antes de tentar abrir novamente. Exclusão de evento agora remove sorteios, atribuições e entregas relacionadas na mesma transação para evitar referências órfãs. `.gitignore` cobre arquivos de backup. O manifesto mantém os ícones PWA existentes e descreve o app local-first.

**Verificações executadas em 2026-11-03 e 2026-11-04:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Dependências | `flutter pub get` | Concluído; `file_picker 13.3.2` e `file_picker_web 4.2.0` resolvidos |
| Formatação final | `dart format --output=none --set-exit-if-changed .` | 93 arquivos; 0 alterações |
| Análise | `flutter analyze` | `No issues found!` |
| Testes focados | `flutter test test/features/backup test/features/events/data/event_repository_test.dart` | 13 testes passaram |
| Regressão completa | `flutter test` | 82 testes passaram |
| Desempenho do sorteio | Teste `sorteia 200 participantes ativos` em `test/features/draw/domain/draw_engine_test.dart` | Pareamento válido de 200 pessoas; duração isolada ainda não medida, então o critério de desempenho permanece pendente |
| Build Web release | `flutter build web --release` | Concluído em 76,8 s; build gerado em `build/web` |
| Execução local | `flutter run -d web-server --release --web-hostname 127.0.0.1 --web-port 8787` | Servidor release iniciado; título “Amigo Secreto” carregou no navegador integrado |
| Artefatos servidos | GET `/`, `/manifest.json`, `/icons/Icon-maskable-512.png` em `http://127.0.0.1:8787` | Todos responderam HTTP 200; HEAD não é suportado pelo servidor Flutter |
| Exportação Web | Chrome integrado, origem local isolada, backup vazio | Download iniciado e mensagem corrigida para orientar a conferir downloads; não foi interpretado como cancelamento |
| Importação Web | Chrome integrado, arquivo fictício vazio e fixture com 200 participantes | Prévia validada, confirmação explícita apresentada e importação concluída |
| Layout e navegação | Chrome integrado; 360×800, 768×1024 e 1280×900; fluxo fictício | Sem corte dos controles principais; ordem por teclado observada no grupo de semântica |
| Sorteio em release | Chrome integrado, 1280×900, fixture de 200 participantes | Tela de sorteio disponível em aproximadamente 1,06 s após navegação; uma medição, não benchmark estatístico |
| Link click-to-chat | Chrome integrado, telefone fictício | Abriu a página oficial `api.whatsapp.com` com telefone e texto preenchido; nenhum botão de envio foi acionado. Após o redirecionamento, emojis foram exibidos como `�` |
| Teste automatizado de contraste | `flutter test test/app/theme_accessibility_test.dart` | Pares principais da paleta clara/escura atendem contraste 4,5:1 |
| Restauração pela tela de falha | `flutter test test/app/database_failure_test.dart --reporter expanded` | 3 testes passaram; restauração e tentativa de reabrir exercitadas com dependências injetadas |
| Fixture de desempenho | `flutter test test/tools/draw_performance_fixture_test.dart --reporter expanded` | 1 teste passou; gera arquivo fictício em `%TEMP%\amigo-secreto-backup-test-200.json` |
| Formatação final | `dart format --output=none --set-exit-if-changed .` | 95 arquivos; 0 alterações |
| Análise final | `flutter analyze` | `No issues found!` |
| Regressão final | `flutter test` | 87 testes passaram |
| Tentativa de integração | `flutter test integration_test` | Falhou porque há mais de um dispositivo conectado; tentativa com `-d chrome` informa que Web não é suportado por esse comando |
| Driver de integração Web | `flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart` | Compilou/iniciou Chrome, mas ficou sem progresso após “Waiting for connection from debug service on Chrome”; interrompido após mais de 3 min. Fluxo não considerado aprovado |
| Build Web release final | `flutter build web --release` | Concluído em 108,6 s; saída em `build/web`; aviso informativo de dry-run Wasm e tree-shaking de fontes |
| Guia de publicação | Revisão documental | `docs/DEPLOY.md` descreve o artefato, fallback de rotas, HTTPS e verificações; nenhum provedor foi escolhido nem publicação realizada |

**Ainda não verificado manualmente:** Edge; leitor de tela real (Narrator/NVDA); zoom do navegador em 200%; teste físico de alvos de toque. O teste automatizado de contraste usa os pares principais da paleta e não substitui inspeção visual completa. A abertura do click-to-chat foi demonstrada com dado fictício, mas a exibição de emojis após o redirecionamento ficou incorreta; o URI inicial do app estava percent-encoded em UTF-8, então a origem da conversão precisa ser isolada antes de alterar a implementação. A Fase 5 permanece **parcial**. Não foi feito deploy nem envio real.

**Intercorrências e impacto:** a primeira checagem de formatação detectou apenas `test/tools/draw_performance_fixture_test.dart`; o arquivo foi formatado e a checagem repetida passou. A primeira análise encontrou importações desnecessárias e um `print` no helper; todos foram removidos e a análise repetida passou. O teste de restauração usa banco Sembast em memória, cujo conteúdo se perde ao fechar; por isso o widget verifica o fluxo de restauração e retry, enquanto preservação de dados importados segue coberta pelos testes do serviço de backup. O runner de integração Web não concluiu no ambiente: `flutter test integration_test -d chrome` declara Web não suportado e `flutter drive` permaneceu aguardando a conexão do serviço de depuração; o fluxo não é contabilizado como executado.

**Ponto exato de retomada:** Fase 5 aceita pelo usuário em 2026-11-05; suas limitações de verificação independente estão registradas abaixo. Continuação ativa na Fase 6.

## 24. Continuação da revisão da Fase 5 — 2026-11-05

**Verificações desta sessão:** `flutter devices` detectou Windows, Chrome e Edge. `flutter test test/tools/draw_performance_fixture_test.dart --reporter expanded` passou (1 teste; fixture exclusivamente fictícia). `flutter run -d web-server --release --web-hostname 127.0.0.1 --web-port 8793` compilou o app; a tela vazia foi inspecionada em viewport 360×800 e os controles e textos permaneceram visíveis, sem corte aparente. O servidor temporário foi encerrado.

**Limitação de evidência:** `flutter run -d edge --release --web-port 8794` compilou, mas falhou ao iniciar o Edge após três tentativas. A tentativa de revisão com automação do computador foi interrompida antes de navegar para o app no Edge. A tecla de zoom não produziu uma mudança observável no navegador integrado; portanto, zoom manual em 200% não foi verificado pelo agente. O Narrator está instalado (`C:\Windows\system32\Narrator.exe`), mas não foi executado. Em seguida, o usuário informou “tudo certo” e autorizou encerrar F5 e iniciar F6; registramos o aceite do usuário, sem transformar as limitações do agente em testes executados.

**Próximo passo histórico:** retomar as limitações acima se for necessária uma comprovação independente em Edge, leitor de tela ou zoom manual.

**Tentativa no Chrome em 2026-11-05:** `flutter run -d chrome --release --web-port 8795` compilou o app e abriu a janela “Amigo Secreto - Google Chrome”. A automação não conseguiu determinar a URL atual da janela no Windows; backup, zoom e leitor de tela não foram verificados pelo agente nessa tentativa. Depois, o usuário confirmou a revisão e aceitou a Fase 5. A origem local usou armazenamento novo e não recebeu dados reais.

## 25. Autorização e início da Fase 6 — 2026-11-05

O usuário autorizou encerrar a Fase 5 e iniciar a próxima fase após abrir o app no Chrome em `http://localhost:8795/#/settings`, informando “tudo certo”. Registramos o aceite do usuário. Limitação de evidência: a automação não conseguiu inspecionar a janela Chrome, nem validar independentemente Edge, Narrator ou zoom manual; isso permanece como limitação de verificação, sem invalidar a autorização expressa do usuário.

A Fase 6 implementará um modo de evento online separado dos eventos locais. O sorteio será calculado no serviço Dart e seus pares nunca retornarão à área do organizador; cada link público terá acesso somente ao resultado associado ao token. Login Google protege a área do organizador. O envio pelo WhatsApp continuará manual. Nenhuma conta de nuvem será criada e nenhum deploy será feito nesta fase sem autorização específica.

**Primeiro passo planejado:** extrair o motor de sorteio e seus modelos para um pacote Dart puro compartilhado pelo Flutter e pelo serviço, e criar serviço de domínio testável. Essa primeira entrega está concluída abaixo.

## 26. Fase 6 — primeira entrega: motor compartilhado e serviço de domínio

**Implementado:** `packages/draw_engine` contém o algoritmo, matching e modelos Dart puros. O app Flutter importa o pacote mantendo os imports de domínio atuais via exports. `server/` é um pacote Dart independente com `OnlineDrawService`, interface de armazenamento, tokens bearer de 256 bits gerados com `Random.secure`, armazenamento por hash SHA-256, DTO do organizador sem campos de resultado, revelação individual, validação de participantes e revogação. Os links usam fragmento `#/reveal/<token>`.

**Verificações executadas em 2026-11-05:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Dependências Flutter | `flutter pub get` | Resolvido pacote local `draw_engine` |
| Testes do motor | `flutter test test/features/draw/domain/draw_engine_test.dart` | 8 testes passaram, incluindo 200 participantes, restrições e uniformidade |
| Testes de domínio do serviço | `dart pub get` e `dart test` em `server/` | 2 testes passaram: links não expõem pares, token inválido e revogação |
| Análise do serviço | `dart analyze` em `server/` | Sem issues |
| Regressão Flutter | `flutter test` | 87 testes passaram |
| Análise Flutter | `flutter analyze` | Sem issues |
| Formatação | `dart format --output=none --set-exit-if-changed .` | 102 arquivos; 0 alterações |
| Build Web | `flutter build web --release` | Concluído em 124,1 s; avisos informativos Wasm dry-run e tree-shaking |
| Diff | `git diff --check` | Sem erros de whitespace |

**Intercorrências:** a primeira execução dos testes do serviço falhou porque o teste não importava o pacote que declara `DrawRequest`; o import foi corrigido e os 2 testes passaram. A primeira análise Flutter reportou 4 issues de estilo; construtor e imports foram ajustados, e a análise repetida passou. Nenhum dado real foi usado.

**Limites desta entrega:** ainda não há servidor HTTP, autenticação Google, persistência Firestore, regras de segurança, UI de evento online nem Firebase Emulator. O serviço de domínio usa armazenamento injetado; não pode receber tráfego de produção.

**Próximo passo exato:** implementar API HTTP local e testar seu contrato, adicionar verificação de ID token Firebase e adaptador Firestore pelo Emulator. Só depois integrar a UI; nenhuma criação de projeto cloud ou publicação sem autorização.

## 27. Continuação da Fase 6 — API, Firebase e primeira UI

**Implementado nesta continuação:**

- API HTTP Dart em `server/`: sorteio autenticado por evento, revelação pública individual e revogação restrita ao organizador dono do evento. Respostas do organizador incluem somente participante, destinatário, telefone opcional e URL; respostas públicas incluem somente participante e destinatário sorteado.
- Validação Firebase ID token via Firebase Authentication account lookup; autenticação inválida recebe 401, evento alheio recebe 403 e tokens inválidos/revogados recebem 404 sem detalhes.
- `FirestoreOnlineDrawStore` usando REST, com hash de token como ID de documento, gravação em lote atômica, precondição de `updateTime` e avanço de `pairingRevision`. Token de acesso de produção vem da identidade de serviço do Cloud Run.
- `firebase.json`, `firestore.rules` (nega todo acesso via cliente), e `server/Dockerfile` para preparar a hospedagem e o serviço sem criar projeto nem publicar.
- Flutter tem entrada separada de evento online, login Google, formulário de participantes/destinatário/WhatsApp/grupos, ação manual para abrir o WhatsApp, botão de revogar com confirmação e rota de revelação. Opções Firebase e URL da API são `--dart-define`; sem elas a parte local segue disponível.
- README e documentos de ambiente/arquitetura atualizados com comandos locais e privacidade.

**Verificações executadas nesta continuação:**

| Verificação | Comando | Resultado |
| --- | --- | --- |
| Análise Flutter | `flutter analyze` | Sem issues |
| Testes Flutter | `flutter test` | 87 testes passaram |
| Formatação | `dart format --output=none --set-exit-if-changed .` | 112 arquivos, 0 alterações |
| Build Web | `flutter build web --release` | Concluído em 125,9 s; avisos informativos Wasm dry-run e tree-shaking |
| Análise do servidor | `dart analyze` em `server/` | Sem issues |
| Testes do servidor | `dart test` em `server/` | 6 testes passaram: API HTTP, Firestore REST simulado e 200 participantes |
| Binário do servidor | `dart compile exe bin/server.dart -o $env:TEMP\online-draw-server-check.exe` | Compilado; executável temporário removido depois da verificação |
| Diff | `git diff --check` | Sem erros; Git só avisou normalização LF/CRLF em arquivos alterados |

Firebase CLI e Java não estão disponíveis no ambiente; nenhum Firebase Emulator foi iniciado. Nenhuma chamada a projeto cloud foi feita. A primeira análise Flutter encontrou issues de estilo/layout e o teste inicial do adaptador detectou contagem de requests errada no próprio teste; tudo foi corrigido antes da execução final acima.

**Limitações e próximo passo exato:** o armazenamento foi validado contra HTTP simulado, ainda não contra o Firestore Emulator; login Google/Hosting também depende de projeto Firebase local ou demo e não foi verificado no navegador. Repetir análise/testes/build do app, corrigir falhas e executar Emulator (Auth e Firestore), cenário ponta a ponta e revisão Chrome. Confirmar que grupos, limites, HTTP responses e erros funcionam no fluxo visual. Fase 6 permanece parcial; não criar projeto Google nem fazer deploy sem autorização específica.

## 28. Pedido de transição após a Fase 6 — 2026-11-11

O usuário pediu para iniciar a próxima fase. A transição não foi feita porque a Fase 6 continua parcial pelos critérios da seção 9 e não existe escopo/critério de aceite definido para uma Fase 7. O próximo trabalho autorizado permanece fechar a verificação da Fase 6 com Firebase Emulator e fluxo no Chrome, sem criar projeto cloud ou fazer deploy. Depois do aceite da Fase 6, definir e autorizar a próxima fase no plano antes de implementá-la.

## 29. Correção do rascunho do modo online — 2026-11-11

O usuário informou que participantes adicionados pareciam não salvar. A análise confirmou que o formulário online guardava os campos somente nos controladores da tela até concluir o sorteio; sair da rota ou recarregar descartava o rascunho. O cadastro de participante local continua persistindo pela sua própria camada Sembast.

**Correção:** adicionado o store local `onlineDrafts`, com salvamento automático do nome, participantes, destinatários, telefones, texto dos grupos e, após o sorteio, links/revogações. A tela restaura o rascunho ao reabrir na mesma origem/dispositivo. Esse store não foi adicionado à lista explícita do `BackupService`, portanto backup JSON não contém links bearer. Rascunhos não sincronizam entre dispositivos e limpar os dados do site os remove. Corrigida também a porta de API no README: API 8090, Firestore Emulator 8080 e Flutter Web 8081.

**Verificação executada:** `flutter analyze` sem issues; `flutter test` com 88 testes passando, incluindo teste de restauração do rascunho e exclusão do backup; `flutter build web --release` concluído em 82,1 s; `dart format --output=none --set-exit-if-changed .` sem mudanças. O Emulator/browser continuam pendentes conforme seção 27.

## 30. Preparação do roteiro de validação do Emulator — 2026-11-11

Ao detalhar a validação, foi identificado que o servidor usava chamadas Firestore sem credencial no Emulator, mas `firestore.rules` nega todo acesso do cliente. `server/bin/server.dart` agora usa o token local `owner` somente quando `FIRESTORE_EMULATOR_HOST` está configurado; fora do Emulator continua usando o token metadata do Cloud Run. O roteiro passo a passo foi adicionado em `docs/TESTES.md`, incluindo leitura REST anônima esperada como 403. Firebase CLI/JDK e Emulator não estão disponíveis aqui, então esse caminho ainda precisa ser executado pelo usuário.

**Verificações após o ajuste:** `dart analyze` sem issues em `server/`; `dart test` com 6 testes passando; `dart format --output=none --set-exit-if-changed .` sem alterações; `git diff --check` limpo (avisos apenas de normalização CRLF do Git). Permanecem pendentes o fluxo real no Emulator/Chrome, teste automatizado de regras e teste de concorrência/lote Firestore com 200 resultados.

## 31. Validação manual do fluxo de links no Firebase Emulator — 2026-11-12

O usuário iniciou Auth e Firestore Emulator com o projeto fictício `demo-amigosecreto`, executou `dart analyze` (sem issues) e `dart test` no serviço (6 testes passaram), e iniciou a API local na porta 8090. O Flutter não conseguiu iniciar o Chrome com o dispositivo `chrome`; com `-d web-server --web-hostname 127.0.0.1 --web-port 8081`, o usuário abriu o app manualmente no Chrome.

**Validação manual confirmada pelo usuário:** login Google simulado pelo Auth Emulator com identidade fictícia; geração de links; cada link abriu somente seu resultado em janela anônima, sem login; reabertura manteve o resultado; revogação bloqueou o link; botão WhatsApp preparou somente o link e nenhuma mensagem foi enviada. O link gerado inicialmente com `localhost` não abriu nesse servidor ligado a IPv4 `127.0.0.1`; usar `http://127.0.0.1:8081` como `PUBLIC_BASE_URL` e abrir sempre essa mesma origem resolveu o teste. O roteiro em `docs/TESTES.md` foi ajustado para registrar essa configuração e o fallback de navegador realmente usado.

**Testes automatizados adicionados e executados nesta sessão:** `dart analyze` em `server/` sem issues; `dart test` em `server/` com as variáveis do Emulator configuradas: 9 testes passaram, incluindo negação de leitura/escrita anônimas pelas regras, lote real de 200 resultados e conflito concorrente de `pairingRevision` com apenas um vencedor. O novo teste é ignorado quando `FIRESTORE_EMULATOR_HOST` não está configurado. A suíte inicialmente falhou ao carregar o teste por avaliar o host nulo antes de aplicar o `skip`; a inicialização foi corrigida e a execução repetida passou.

**Estado:** implementação e critérios automatizados do Firestore estão verificados localmente, mas a Fase 6 ainda não está aceita. Permanecem pendentes na interface do Chrome o token inventado e o sorteio impossível (três participantes no mesmo grupo restrito). Nenhum recurso cloud foi criado, deploy realizado ou mensagem enviada.

## 32. Ajustes da experiência online — 2026-11-12

O usuário informou que não conseguiu configurar os grupos online e que a tela não permitia cancelar/refazer o sorteio. A inspeção confirmou que o serviço já aplicava os grupos recebidos, mas a tela exigia texto manual no formato `nome: pessoa, pessoa`, sem edição de tipo ou restrição, desabilitava o botão após gerar links e sempre enviava `pairingRevision = 1`.

**Implementado:** a tela agora permite criar grupos do tipo Família/Casal/Outro, escolher participantes, ativar ou desativar a restrição e salvar esses dados no rascunho local. As restrições ativas são enviadas ao mesmo motor Dart usado pelo modo local. Grupos online são separados dos grupos de eventos locais. Depois de um sorteio, alterações mostram aviso e a ação “Refazer sorteio e invalidar links atuais” pede confirmação. A nova chamada avança a revisão; o commit do Firestore substitui resultados e remove hashes antigos atomicamente. A tela informa que somente o organizador precisa entrar; cada link individual continua sem exigir login. Respostas `draw_impossible` agora produzem orientação para rever grupos/participantes.

**Verificações executadas:** `flutter analyze` sem issues; `flutter test` com 88 testes passando; `flutter build web --release` concluído em 70,0 s; `dart analyze` em `server/` sem issues; `dart test test/firestore_emulator_integration_test.dart --reporter expanded` com 3 testes passando no Emulator, incluindo avanço de revisão e ausência dos resultados anteriores; `dart format` no novo arquivo de teste sem alterações pendentes.

**Pendente:** revisão manual no Chrome desta nova tela e do fluxo de refazer; também token inventado e sorteio impossível no formulário. A ferramenta de controle do navegador não conseguiu confirmar com segurança a URL da janela Chrome e encerrou a inspeção; nenhuma interação foi feita. O usuário pode atualizar o app em execução com `r` no terminal do Flutter e continuar em `http://127.0.0.1:8081`. Nenhum recurso cloud foi criado, deploy realizado ou mensagem real enviada.

## 33. Decisão de conversão entre modos — 2026-11-12

O usuário confirmou que conversão local ↔ online será uma cópia, preservando o evento de origem. Registrei em ADR-007: copiar cadastro, contatos/destinatários e grupos após revisão; gerar um sorteio novo no modo de destino; nunca transportar os pares existentes; não revogar links da origem silenciosamente. A conversão online → local depende dos dados cadastrais disponíveis no rascunho local e não recuperará pares do servidor.

Essa decisão não amplia a Fase 6 ativa. A implementação requer uma fase futura com critérios de aceite para prévia, confirmação do envio de dados pessoais local → servidor, duplicidades e disponibilidade do rascunho na conversão online → local. Nenhum código de conversão ou recurso externo foi criado nesta entrega documental.

## 34. Aceite da Fase 6 — 2026-11-12

O usuário informou que realizou e aprovou as quatro validações manuais pendentes: configuração de grupos e restrições no online, refazer o sorteio invalidando os links da revisão anterior, resposta segura para token inventado e bloqueio amigável de um sorteio impossível sem gerar links. Com as validações principais já confirmadas anteriormente e a suíte automatizada passando, o usuário autorizou concluir a Fase 6.

**Evidências automatizadas registradas nesta fase:** Flutter `analyze` sem issues; `flutter test` com 88 testes; build Web release concluído; `dart analyze` sem issues em `server/`; suíte do servidor com 9 testes passando contra o Firestore Emulator, incluindo regras de acesso, lote de 200 resultados e concorrência de revisão; formatação verificada em 115 arquivos sem alterações; `git diff --check` sem erros (avisos de normalização LF/CRLF do Git).

**Resultado:** Fase 6 aceita pelo usuário. A experiência online continua localmente validada com emuladores; projeto Firebase real, domínio e deploy não foram configurados nem publicados, conforme escopo. O próximo passo é definir e autorizar uma fase futura; ADR-007 registra a conversão como cópia preservando a origem e criando um novo sorteio.

## 35. Início da Fase 7 — 2026-11-12

O usuário autorizou iniciar a próxima fase. O escopo foi definido no plano como cópia local ↔ online, conforme ADR-007, sem publicação. A ação “Copiar para evento online” mostra prévia e confirmação, preserva a origem e deve criar um rascunho online independente. Dados só são enviados ao serviço após confirmação específica do envio e do sorteio.

Implementada ação de copiar o rascunho online para novo evento local. A gravação é uma transação Sembast, cria novas identidades, preserva participantes ativos/inativos, destinatários e grupos, e ignora eventuais chaves de links/atribuições presentes no mapa de entrada. A cópia fica sem sorteio e não revoga nem altera a origem. Destinatários repetidos dentro da cópia podem compartilhar uma identidade; cadastros locais anteriores nunca são mesclados automaticamente. O modo online atual não dispõe de campo separado para data ou apelido, então esses campos não são preserváveis em local → online. Na direção local → online, uma segunda confirmação, anterior à requisição, autoriza o envio dos nomes/contatos; cancelar deixa o rascunho pendente e intacto.

**Verificações executadas:** `flutter analyze` sem issues; `flutter test` com 90 testes passando; teste específico da persistência de cópia com 2 cenários passando; `dart format --output=none --set-exit-if-changed .` verificou 117 arquivos sem mudanças; `flutter build web --release` concluído; no servidor, `dart analyze` sem issues e `dart test` com 6 aprovados e 3 testes do Emulator ignorados porque `FIRESTORE_EMULATOR_HOST` não estava definido; `git diff --check` sem erros (avisos de normalização LF/CRLF).

**Estado:** Fase 7 parcial, não aceita. Ainda falta revisar no Chrome os diálogos de prévia/cancelamento, cópia de evento local sorteado, proteção dos links ao tentar substituir rascunho e a cópia online → local mantendo a origem acessível. Também falta cobertura automatizada direta da prévia/cancelamento e erro de rascunho ausente. Nenhum deploy, envio WhatsApp ou acesso a serviço Firebase real foi feito.

## 36. Planejamento da Fase 8 — 2026-11-12

O usuário pediu registrar como próxima fase uma melhoria de ambiente com Docker e automação para preparar o projeto para Firebase. O plano agora inclui Compose local para Flutter Web, API Dart e Auth/Firestore Emulators; build repetível; pipeline de CI; configuração de Hosting/Firestore e entrega da API no Cloud Run; documentação de requisitos iniciais de projeto, IAM, Authentication, domínio e reversão.

Ficou registrado que Firebase de produção é serviço gerenciado, não um serviço Firebase hospedado pelo Docker Compose. Os artefatos serão construídos/publicados separadamente: Web no Hosting e API no Cloud Run. A Fase 8 está apenas planejada, aguardando a conclusão/aceite da Fase 7 e autorização para implementação. Criação de projeto real, cobrança, aplicação de infraestrutura e deploy continuam fora do escopo autorizado.

## 37. Diagnóstico de sorteio e vários eventos online — 2026-11-12

O usuário relatou erro genérico ao criar sorteio online tanto de evento novo quanto de cópia local, e pediu criar/gerenciar múltiplos eventos e recuperar o anterior após reiniciar. A orientação curta de dois terminais omitiu a API Dart; o sorteio precisa do terceiro terminal (API na porta 8090). Além disso, o Flutter usava `localhost:8090` enquanto o servidor estava configurado para IPv4; o comando agora usa `127.0.0.1:8090`. Essas são causas prováveis do erro reportado; falta o usuário retestar com a API ativa.

O armazenamento anterior usava uma única chave local `current` e não havia tela de lista; isso impedia criar e reabrir eventos online independentes. A Fase 7 foi ampliada a pedido do usuário para suportar vários rascunhos por ID, listar/reabrir eventos, preservar links de cada um e migrar o registro legado `current`. Os dados continuam locais à origem/perfil do navegador; não são sincronizados nem recuperáveis do Firestore em outro dispositivo.

**Implementado nesta continuação:** repositório multi-rascunho; migração do antigo registro; nova tela lista de eventos online e rotas para criar/abrir por ID; cópia local → online cria evento separado; botões retornam à lista; cliente e tela distinguem API indisponível, 400, 401, 403, 409 e 500 com mensagens orientativas; documentação e comandos agora indicam três terminais e o endereço `127.0.0.1`.

**Verificações desta continuação:** testes do repositório de rascunhos com 3 cenários passaram, incluindo dois eventos sem sobrescrever links e migração de `current`; `flutter analyze` sem issues; `flutter test` com 92 testes passando; `dart format --output=none --set-exit-if-changed .` verificou 118 arquivos sem alterações; `flutter build web --release` concluído em 77,7 s; `dart analyze` no servidor sem issues; `dart test` com 6 aprovados e 3 testes do Emulator ignorados por ausência de `FIRESTORE_EMULATOR_HOST`; `git diff --check` sem erros, com avisos Git de normalização LF/CRLF.

**Pendente:** teste manual no Chrome com API ativa e parada; criação/reabertura de múltiplos eventos; conversões e preservação de links. A causa do erro original ainda é provável, não confirmada pelo usuário; a execução anterior de dois terminais realmente não iniciava a API, e a URL foi alinhada para IPv4 `127.0.0.1`. Fase 7 permanece parcial; sem Firebase real, deploy ou WhatsApp.

## 38. Correção de saída e exclusão de eventos online — 2026-11-12

O usuário relatou que “Sair” não atualizava a sessão e que não havia como cancelar/excluir um evento online. A tela lia `FirebaseAuth.currentUser` apenas durante o build, sem observar alterações posteriores; a lista de eventos também não oferecia exclusão.

**Implementado:** a tela agora observa `authStateChanges`, aguarda `signOut` e atualiza o estado para oferecer novo login. A lista de eventos tem ação de exclusão com confirmação destrutiva. Para rascunho não enviado ao servidor, remove apenas o ID escolhido do IndexedDB. Para sorteio existente ou tentativa que possa ter criado registro remoto, exige login, pede à API a exclusão autenticada do documento do evento e dos resultados referenciados; o servidor usa um único commit condicionado ao `updateTime` e verifica a propriedade. O rascunho local só é removido após sucesso remoto. API inacessível, falta de sessão e falta de acesso mantêm o rascunho e mostram orientação. Cancelar o diálogo não altera dados. A exclusão é definitiva e os links daquele evento deixam de funcionar.

**Verificações executadas:** `dart format --output=none --set-exit-if-changed .` verificou 118 arquivos sem mudanças; `flutter analyze` sem issues; `flutter test` com 92 testes passando; `flutter build web --release` concluído em 120,5 s (avisos informativos de dry-run Wasm e tree-shaking); `dart analyze` no servidor sem issues; `dart test` com 8 testes passando e 3 testes de integração ignorados por ausência de `FIRESTORE_EMULATOR_HOST`; testes novos cobrem autorização da exclusão pela API, invalidação de todos os links, commit Firestore atômico e isolamento ao excluir um rascunho local. `git diff --check` passou sem erros; Git emitiu apenas avisos de normalização LF/CRLF. Nenhuma publicação ou uso de Firebase real foi realizado.

**Pendente à época desta alteração:** conferir no Chrome com Auth/Firestore Emulators o logout, cancelamento e confirmação da exclusão; os testes automatizados não substituem essa validação visual/ponta a ponta. A pendência foi resolvida pelo usuário conforme registrado na seção 39.

## 39. Aceite da Fase 7 — 2026-11-12

O usuário informou que concluiu todas as validações que faltavam e que tudo funcionou. Isso confirma os fluxos manuais no Chrome documentados nas seções 14 e 18 de `docs/TESTES.md`, incluindo retomada e isolamento de eventos online, conversão/cancelamento, desligamento da API, saída da conta e exclusão confirmada/cancelada com invalidação dos links do evento excluído.

As verificações automatizadas da implementação mais recente foram registradas na seção 38: 92 testes Flutter, 8 testes do servidor, análises Flutter/Dart sem issues, formatação verificada e build Web release concluído. Três testes de integração do Firestore foram ignorados na execução local mais recente porque o Emulator não estava configurado; as validações manuais do usuário usaram os emuladores conforme o fluxo combinado. Não houve criação de Firebase de produção, deploy, commit/push ou envio real de WhatsApp.

**Resultado:** Fase 7 aceita e commitada em `b5b9b68`. A Fase 8 (Docker e automação para Firebase/Cloud Run) foi autorizada pelo usuário depois do commit e iniciou nesta continuação.

## 40. Início da Fase 8 — Docker e automação — 2026-11-12

Após o aceite manual da Fase 7, o usuário pediu atualizar a fase, fazer o commit e iniciar a próxima após ele. A Fase 7 foi commitada em `b5b9b68` (`feat: complete phase 7 online event management`); em seguida o usuário autorizou a Fase 8. Não houve push.

**Implementado até aqui:** `compose.yaml` define Web, API Dart e Firebase Auth/Firestore Emulators, com volumes de dados/cache e portas publicadas só em `127.0.0.1`; `firebase.docker.json` altera apenas os hosts de bind necessários dentro do stack. `docker/Dockerfile.web` baixa Flutter 3.47.9 do arquivo oficial e valida seu SHA-256; `server/Dockerfile` fixa Dart 3.13.7, compila serviço e expõe `/health`, com runtime Debian Trixie compatível; `docker/Dockerfile.emulators` fixa Firebase CLI 15.36.0 e usa Node 22/JDK 21. `.env.example`, `.gitignore` e `.dockerignore` definem valores de demo e protegem env/credenciais. `verify.yml` automatiza config, checks, testes Emulator, build e smoke test; `deploy-staging.yml` é workflow separado, manual, restrito à branch `main`, Environment `staging`, confirmação `yes` e WIF. README e docs incluem setup e reversão.

**Verificações locais executadas:** análise sintática passou para `compose.yaml`, os dois workflows GitHub e os dois JSON Firebase; `dart format --output=none --set-exit-if-changed .` verificou 118 arquivos sem alterações; `flutter analyze` sem issues; `flutter test` com 92 testes passando; `dart analyze` sem issues no serviço; `dart test` com 9 testes passando e 3 testes Firestore Emulator ignorados por `FIRESTORE_EMULATOR_HOST` ausente; novo teste da API verifica `/health` sem autenticação. Na revisão final, `git diff --check` terminou sem erros; o Git emitiu apenas avisos de normalização LF/CRLF.

**Tentativa adicional de validação (2026-11-12):** `docker --version`, `docker compose version` e `docker info` falharam porque o comando `docker` não existe no PATH; os caminhos padrão do Docker Desktop também não contêm o executável e Podman está ausente. `java -version` também falhou, então não há como iniciar Firebase Emulator neste ambiente. Validações no host concluídas: `dart format --output=none --set-exit-if-changed .` (118 arquivos, 0 alterados), `flutter analyze` sem issues, `flutter test` com 92 testes passando, `flutter build web --release` concluído em 71,7 s, `dart analyze` sem issues no servidor e `dart test` com 9 testes passando; 3 testes do Firestore Emulator foram ignorados por `FIRESTORE_EMULATOR_HOST` ausente. `git diff --check` terminou sem erros, com avisos Git de normalização LF/CRLF. Continuam pendentes `docker compose config`, builds de imagens, subida do Compose, health checks reais e os três testes de integração do Firestore. Workflow de staging não foi acionado; nenhum projeto, billing, recurso cloud, imagem ou deploy foi criado.

**Estado à época:** Fase 8 parcial e em andamento, com Docker ainda indisponível. A validação foi retomada quando o usuário informou a instalação; resultados atuais e próximo passo estão registrados na seção 41. Staging só poderá ser acionado depois de configurar/revisar o Environment e WIF e autorizar o deploy ao projeto de staging.

## 41. Validação conteinerizada da Fase 8 — 2026-11-13

O usuário informou que instalou Docker, então a validação pendente foi retomada. Docker 29.9.3 e Docker Compose 5.7.0 foram detectados; `docker info` conectou ao Engine. `Copy-Item .env.example .env` criou a configuração local ignorada pelo Git, e `docker compose config` passou.

Os primeiros builds encontraram três problemas reais e foram corrigidos antes de considerar qualquer resultado final: (1) Git bloqueava o checkout Flutter extraído em `/opt/flutter` por ownership; a imagem agora marca somente esse diretório como `safe.directory`; (2) Firebase CLI 15.36.0 rejeitou Java 17 e exigiu Java 21, então a imagem de Emulator passou para `node:22-trixie-slim` com `openjdk-21-jre-headless`; (3) o perfil `flutter-tests` usava shell login, que limpava o `PATH`, e o analyze precisava das dependências Dart do servidor, enquanto o contexto copiava `.dart_tool` local; Compose agora usa `sh -c`, `.dockerignore` exclui `.dart_tool` recursivamente e a imagem Flutter executa `dart pub get` em `server/`.

**Resultados finais:** `docker compose up --build --detach` concluiu; `docker compose ps` mostrou Web, API e Emulators `healthy`. `/health` respondeu `{"status":"ok"}`; Web, Auth Emulator e Firestore Emulator responderam HTTP 200. `docker compose --profile test run --build --rm flutter-tests` passou: `dart format --output=none --set-exit-if-changed .` (118 arquivos, 0 alterados), `flutter analyze` sem issues, `flutter test` com 92 testes e `flutter build web --release` concluído em 93,7 s. `docker compose --profile test run --build --rm api-tests` passou com 12 testes: os 9 testes HTTP/unidade e os 3 testes Firestore Emulator foram executados e passaram (regras anônimas, 200 resultados e concorrência de revisão). Nenhum teste do Emulator foi ignorado nessa execução.

**Pendências:** a inspeção visual/interativa do fluxo Web no Chrome não foi possível porque a ferramenta de automação encerrou a ação ao não conseguir determinar com confiança a URL atual do navegador. Web HTTP 200 e testes de API não substituem validar login no Auth Emulator, gravação pelo fluxo Web e persistência após recarga no Chrome. O workflow CI ainda não foi executado no GitHub e o deploy de staging não foi acionado. Não houve publicação nem envio WhatsApp.

**Estado:** Fase 8 permanece parcial. Próxima ação: executar no Chrome o fluxo descrito na seção 19 de `docs/TESTES.md` (login fictício, criação de sorteio e recarga para confirmar persistência) e validar o workflow de CI quando houver um PR/push autorizado. Staging exige configuração prévia de Environment/WIF e autorização específica. Docker Compose mantém o stack local ativo nas portas 8081, 8090, 9099, 8080 e 4000; `docker compose down` encerra os serviços sem apagar os volumes.
