# Progresso

**Última atualização:** 2026-11-04
**Fase atual:** Fase 5 — Backup e acabamento **em andamento**
**Próxima fase:** Nenhuma fase planejada após a Fase 5
**Implementação:** Fases 1–3 aceitas; Fase 4 liberada pelo usuário para transição; Fase 5 autorizada explicitamente
**Instalações realizadas:** Flutter 3.47.9 stable no escopo do usuário

Este documento é a fonte de verdade para o **estado real do trabalho** e para o ponto exato de retomada. Em caso de divergência com outros documentos, vale o que está registrado aqui; o conflito deve ser resolvido antes de continuar.

## 1. Situação em uma frase

As Fases 1 a 3 estão concluídas. A implementação da Fase 5 cobre backup, recuperação, aviso após sorteio e regressão automatizada; ainda faltam conferências manuais de navegador e acessibilidade. O click-to-chat manual da Fase 4 também segue não demonstrado.

## 2. Situação por fase

| Fase | Situação | Evidência | Próxima ação |
| --- | --- | --- | --- |
| 0 — Planejamento | Concluída | Documentos listados na seção 5 | Nenhuma |
| 1 — Ambiente e fundação | Concluída | Seções 6 a 9 | Nenhuma |
| 2 — Cadastro e organização | Concluída | Critérios e verificações nas seções 16 e 17 | Nenhuma |
| 3 — Sorteio e integridade | Aceita | Testes automatizados passaram; usuário confirmou revisão manual de teclado, foco, leitor de tela e contraste | Nenhuma |
| 4 — WhatsApp e entregas | Liberada para transição pelo usuário | Link aberto manualmente com contato fictício; nenhum envio feito. Após redirecionamento do WhatsApp, emojis apareceram como caractere de substituição; investigar antes de considerar essa experiência validada | Verificar o comportamento em navegador compatível e corrigir se reproduzível no URI gerado pelo app |
| 5 — Acabamento e backup | Parcial | Fluxos de backup executados em navegador isolado; 200 participantes renderizados em build release; testes, análise, formatação e build aprovados. Revisão de leitor de tela e zoom do navegador ainda pendentes | Validar leitor de tela e zoom 200%; repetir arquivo em Edge; fechar a pendência visual de emojis do link da Fase 4 |

## 3. Ponto exato de retomada

O usuário autorizou a Fase 5 em 2026-11-03 ao pedir a implementação da próxima fase. Em 2026-11-04, o navegador abriu o link click-to-chat com telefone fictício, mas a página do WhatsApp exibiu emojis como caracteres de substituição depois do redirecionamento; nenhum envio foi feito. Na Fase 5, exportação e importação foram exercitadas em origem local isolada, e foi medida a renderização do sorteio de 200 participantes. O próximo passo é a revisão manual de leitor de tela/zoom 200% e a verificação em Edge. Publicação e envio real continuam fora do escopo.

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

Concluir a revisão manual da Fase 4 no navegador com evento, participantes e telefone fictícios; confirmar editor, filtro, cópia e redirecionamento click-to-chat sem enviar a mensagem. Registrar navegador/viewport e resultado. Corrigir problemas encontrados e repetir análise, testes, formatação e build. Não iniciar backup ou publicação.

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

**Ponto exato de retomada:** executar revisão manual com Narrator ou NVDA, zoom do navegador a 200% e o fluxo de arquivo no Edge. Depois, investigar a conversão dos emojis no redirecionamento click-to-chat, mantendo telefone fictício e sem enviar a mensagem. Não publicar nem usar dados reais.
