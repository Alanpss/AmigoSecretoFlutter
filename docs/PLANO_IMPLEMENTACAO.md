# Plano de implementação

Este documento é a fonte de verdade para a **sequência de implementação**, o escopo de cada fase e os critérios para avançar. Regras de comportamento estão em `docs/REQUISITOS.md`; decisões técnicas, em `docs/ARQUITETURA.md` e nos ADRs.

## 1. Regras do processo

- A fase atual e o ponto de retomada ficam em `docs/PROGRESSO.md`.
- **Nenhuma fase começa sem autorização explícita do usuário.** Uma fase concluída não autoriza a seguinte.
- Trabalhar apenas no escopo da fase autorizada. Se uma necessidade pertencer a outra fase, registrar o impedimento e pedir autorização.
- Cada fase termina com um **portão de aceite**: critérios observáveis demonstrados, testes executados e documentação atualizada.
- Se algum critério não for atendido, a fase é declarada **parcial**; não é permitido declarar conclusão falsa.
- Não há estimativa de prazo neste plano. O esforço é relativo e será recalibrado com os resultados reais.
- O MVP é a soma das Fases 1 a 5. Publicação, deploy e envio de mensagens reais exigem autorização separada.

## 2. Visão geral

| Fase | Objetivo | Entrega principal | Depende de | Situação |
| --- | --- | --- | --- | --- |
| 0 | Planejar sem implementar | Documentação, decisões e ambiente mapeado | — | Concluída em 2026-11-03 |
| 1 | Preparar ambiente e fundação | Flutter instalado, projeto Web executável, banco e navegação básicos | Fase 0 + confirmação da plataforma | Concluída em 2026-11-03 |
| 2 | Cadastro e organização | Eventos, pessoas, participantes, responsáveis e grupos funcionando | Fase 1 | Bloqueada |
| 3 | Sorteio e integridade | Sorteio válido, persistido, retomável, bloqueável e invalidável | Fase 2 aceita; autorização do usuário em 2026-11-03 | Aceita em 2026-11-03 |
| 4 | WhatsApp e acompanhamento | Mensagens, links, fila e estados de envio | Fase 3 aceita; autorização do usuário em 2026-11-03 | Em andamento |
| 5 | Acabamento e recuperação | Backup, acessibilidade, responsividade, regressão e build final | Fase 4 | Bloqueada |

## 3. Fase 0 — Planejamento (concluída)

**Objetivo:** definir escopo, regras, arquitetura, ambiente, fases e critérios antes de instalar qualquer ferramenta.

**Entregas:**

- `README.md` e `AGENTS.md`;
- `docs/CONTEXTO.md`, `docs/REQUISITOS.md`, `docs/ARQUITETURA.md`;
- `docs/PLANO_IMPLEMENTACAO.md`, `docs/PROGRESSO.md`, `docs/AMBIENTE.md`, `docs/TESTES.md`;
- ADRs em `docs/decisions/`.

**Checklist:**

- [x] Inventariar sistema, disco, Git, navegadores, VS Code e ausência de Flutter/Dart/Java/Android.
- [x] Consultar documentação oficial do Flutter, das dependências e do WhatsApp.
- [x] Definir escopo, regras, arquitetura, persistência, sorteio, envio e privacidade.
- [x] Definir fases, critérios de aceite, riscos e portões.
- [x] Registrar o ponto de retomada e as decisões pendentes.
- [x] Verificar que nenhuma ferramenta foi instalada e nenhum código foi criado.

**Arquivos:** somente Markdown em `README.md`, `AGENTS.md` e `docs/`.

**Critérios de aceite observáveis:**

- [x] Todos os documentos obrigatórios existem e têm finalidade explícita.
- [x] Os links relativos entre documentos resolvem.
- [x] As decisões técnicas têm ADR ou justificativa na arquitetura.
- [x] As fases têm escopo, checklist, arquivos, critérios, testes, riscos e portão.
- [x] `docs/PROGRESSO.md` registra o estado real e o próximo passo.
- [x] Nenhum dado pessoal real, segredo ou backup foi incluído.
- [x] Nenhuma instalação, build ou publicação foi executada.

**Verificação:** revisão manual, conferência de links relativos e `git status --short`. Não há testes de aplicativo nesta fase.

**Riscos:** documentação excessiva ou desatualizada; mitigação é manter `docs/PROGRESSO.md` como fonte de verdade e atualizar os documentos afetados em cada fase.

**Fora do escopo:** instalar Flutter, criar projeto, escrever código de aplicativo, publicar ou enviar mensagens.

**Portão:** documentação revisada e decisão de plataforma confirmada pelo usuário. A confirmação da plataforma é necessária para iniciar a Fase 1.

---

## 4. Fase 1 — Ambiente e fundação

**Objetivo:** deixar o ambiente reprodutível e o esqueleto do aplicativo executando na Web, sem funcionalidades de negócio.

**Dependências:** Fase 0 concluída; usuário confirmou Flutter Web como plataforma inicial; autorização explícita para instalar ferramentas.

### 4.1 Escopo incluído

1. Instalar o Flutter SDK no escopo do usuário, conforme `docs/AMBIENTE.md`.
2. Verificar versão, integridade, PATH, navegadores e `flutter doctor`.
3. Criar o projeto Flutter Web preservando a documentação existente.
4. Configurar dependências, lint, formatação e localização pt-BR.
5. Implementar o shell do aplicativo: tema Material 3, rotas iniciais, layout responsivo e estados de erro.
6. Abrir o banco Sembast antes da interface, com `schemaVersion = 1` e tela de falha segura.
7. Criar a base de testes e o primeiro teste de fumaça.

### 4.2 Fora do escopo

- CRUD de eventos, pessoas, participantes ou grupos;
- sorteio, mensagens, WhatsApp, backup;
- Android, iOS, backend, autenticação ou publicação.

### 4.3 Checklist

- [x] Confirmar por escrito a plataforma inicial Web (autorização da Fase 1 com escopo Web).
- [x] Baixar o Flutter 3.47.9 stable do endereço oficial e conferir o SHA-256.
- [x] Extrair em `%USERPROFILE%\development\flutter` (sem espaços e sem exigir administrador).
- [x] Adicionar `...\flutter\bin` ao `PATH` do usuário e validar em terminal com o caminho atualizado.
- [x] Executar `flutter --version`, `flutter doctor -v`, `flutter devices` e `flutter config --enable-web`.
- [x] Registrar versões, avisos e ações manuais em `docs/AMBIENTE.md`.
- [x] Gerar o projeto em pasta temporária e incorporar somente os arquivos necessários, sem sobrescrever `README.md`, `AGENTS.md` ou `docs/`.
- [x] Adicionar as dependências da Fase 1 e garantir que `pubspec.lock` seja gerado e versionável.
- [x] Configurar `analysis_options.yaml`, formatação e regras de lint.
- [x] Configurar `MaterialApp.router`, tema, localização pt-BR e `go_router`.
- [x] Implementar shell responsivo com `NavigationBar`/`NavigationRail` e rota inicial vazia.
- [x] Implementar abertura do banco, store `meta` e tela de erro com opção de tentar novamente (a importação de backup fica na Fase 5).
- [x] Criar teste de fumaça do app e teste de abertura/transação do banco em memória.
- [x] Executar `flutter pub get`, formatação, `flutter analyze`, `flutter test` e `flutter build web --release`.
- [x] Atualizar `docs/PROGRESSO.md` com comandos e resultados reais.

### 4.4 Arquivos e módulos previstos

```text
pubspec.yaml
analysis_options.yaml
.gitignore
web/
lib/main.dart
lib/app/app.dart
lib/app/router.dart
lib/app/theme.dart
lib/app/bootstrap.dart
lib/core/database/app_database.dart
lib/core/database/database_factory.dart
lib/core/database/database_factory_io.dart
lib/core/database/database_factory_web.dart
lib/core/database/migrations.dart
lib/core/errors/app_error.dart
lib/shared/layout/app_shell.dart
lib/shared/widgets/empty_state.dart
test/app/app_smoke_test.dart
test/core/database/app_database_test.dart
```

### 4.5 Critérios de aceite observáveis

- [x] `flutter --version` informa Flutter 3.47.9 e Dart 3.13.7.
- [x] `flutter doctor -v` foi executado; ausências opcionais (Android/Visual Studio) estão registradas como não bloqueantes.
- [x] O app executa na Web sem erro no console. A execução foi validada em `http://127.0.0.1:8080` com `-d web-server` e no Chrome em `--web-port 8081` (a porta 8080 estava ocupada pelo servidor web).
- [x] A tela inicial carrega em pt-BR, com tema Material 3 e layout adaptável (verificado em 1280×900 e 390×844).
- [x] Recarregar a página mantém a mesma origem e o banco abre novamente.
- [x] Uma falha simulada de banco mostra tela de erro compreensível, sem apagar dados (testes de widget).
- [x] `flutter analyze` não reporta erros; formatação verificada.
- [x] `flutter test` passa, incluindo o teste de banco (6 testes).
- [x] `flutter build web --release` conclui.
- [x] Nenhuma funcionalidade de negócio foi implementada.

### 4.6 Testes e comandos

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
flutter run -d chrome --web-port 8080
```

**Testes obrigatórios (executados):**

- abertura do banco em memória e leitura/gravação no store `meta`;
- transação que falha não deixa registro parcial;
- widget de fumaça com `ProviderScope` e rota inicial;
- widget de layout compacto com `NavigationBar`;
- tela de falha do banco e ação de nova tentativa;
- verificação manual de recarga da página e persistência da origem.

### 4.7 Riscos e limitações

| Risco | Mitigação |
| --- | --- |
| Instalação exigir administrador | Usar pasta do usuário e `PATH` de usuário; não usar `Program Files`. |
| PATH não atualizar no terminal atual | Abrir terminal novo e validar `Get-Command flutter`. |
| `flutter create` sobrescrever documentação | Gerar em pasta temporária e copiar seletivamente. |
| IndexedDB vinculado à porta | Usar sempre a porta 8080 durante o desenvolvimento. |
| Avisos de Android/Visual Studio | Registrar como opcionais; não instalar sem necessidade. |
| Antivírus/Developer Mode atrasarem builds | Documentar a ação manual; não desativar segurança global. |

### 4.8 Portão de saída

A Fase 1 foi aceita em 2026-11-03: o app vazio executa na Web, o banco abre e persiste, os comandos acima passam e `docs/PROGRESSO.md` registra versões, resultados e limitações. A Fase 2 foi autorizada pelo usuário em 2026-11-03 e está em andamento.

---

## 5. Fase 2 — Eventos, pessoas, participantes, responsáveis e grupos

**Objetivo:** permitir organizar completamente um evento em rascunho, sem sorteio.

**Dependências:** Fase 1 aceita.

### 5.1 Escopo incluído

1. CRUD de eventos com nome, data opcional, país padrão e modelo de mensagem inicial.
2. Lista de eventos com busca, situação e quantidade de participantes ativos.
3. Cadastro reutilizável de pessoas e participação por evento.
4. Formulário único de participante: nome, apelido, telefone, responsável, grupos e situação ativa.
5. Criação inline de família/casal/outro grupo sem perder os dados do formulário.
6. Seleção de responsável que participa ou não do evento, com resolução direta do telefone.
7. Grupos com nome único, tipo, membros e restrição ativa/inativa.
8. Busca, filtro, edição e remoção de participantes; remoção não apaga a pessoa.
9. Avisos de nome/telefone duplicado sem bloqueio; bloqueio de participação duplicada.
10. Incremento de `pairingRevision` em qualquer mudança que afete o pareamento.
11. Estados vazios, confirmações de exclusão e mensagens de erro claras.

### 5.2 Fora do escopo

- executar sorteio ou validar viabilidade;
- criar entregas, mensagens ou links;
- backup;
- bloqueio pós-sorteio (depende da Fase 3).

### 5.3 Checklist

- [x] Implementar modelos e repositórios de `Event`, `Person`, `Participant` e `Group`.
- [x] Implementar validação de nome, apelido, telefone e unicidade de grupo.
- [x] Implementar busca de pessoa existente e prevenção de participação duplicada.
- [x] Implementar formulário de participante com criação inline de grupo.
- [x] Implementar resolução direta de responsável, sem cadeia.
- [x] Implementar lista de eventos e visão geral do evento.
- [x] Implementar lista de participantes com busca e filtro ativo/inativo.
- [x] Implementar tela de grupos com edição de membros e restrição.
- [x] Implementar avisos de duplicidade e confirmações de remoção.
- [x] Implementar revisão básica de pendências (sem sorteio).
- [x] Cobrir repositórios, validações e formulários com testes; critérios visuais pendentes foram verificados manualmente.
- [x] Atualizar `docs/PROGRESSO.md`.

**Estado em 2026-11-03:** implementação e testes da fase concluídos; persistência, busca/filtro, duplicidade, responsável externo e layout foram verificados manualmente em navegador com dados fictícios. A Fase 2 foi aceita antes do início da Fase 3.

### 5.4 Arquivos e módulos previstos

```text
lib/features/events/domain/event.dart
lib/features/events/data/event_repository.dart
lib/features/events/presentation/event_list_page.dart
lib/features/events/presentation/event_form_page.dart
lib/features/events/presentation/event_overview_page.dart
lib/features/participants/domain/person.dart
lib/features/participants/domain/participant.dart
lib/features/participants/domain/guardian_resolver.dart
lib/features/participants/data/person_repository.dart
lib/features/participants/data/participant_repository.dart
lib/features/participants/presentation/participant_list_page.dart
lib/features/participants/presentation/participant_form_page.dart
lib/features/groups/domain/group.dart
lib/features/groups/data/group_repository.dart
lib/features/groups/presentation/group_list_page.dart
lib/features/groups/presentation/group_form_page.dart
lib/shared/widgets/confirm_dialog.dart
lib/shared/widgets/duplicate_warning.dart
test/features/...
```

### 5.5 Critérios de aceite observáveis

- [x] Criar, editar, listar e excluir evento com confirmação.
- [x] Evento aparece como “Rascunho” e mantém dados após recarregar.
- [x] Cadastrar participante com todos os campos na mesma tela.
- [x] Criar grupo inline e salvar sem perder nome, apelido ou telefone digitados.
- [x] Reutilizar pessoa existente sem duplicar participação no mesmo evento.
- [x] Cadastrar responsável externo e responsável que também participa.
- [x] Telefone do responsável é resolvido diretamente; não há cadeia.
- [x] Criar família, casal e outro grupo; editar nome, tipo, membros e restrição.
- [x] Nome de grupo duplicado é bloqueado com mensagem clara.
- [x] Pessoa em vários grupos é aceita; a restrição é a união dos grupos ativos.
- [x] Nome/telefone repetido gera aviso e permite salvar.
- [x] Remover participante não apaga a pessoa reutilizável e o remove dos grupos.
- [x] Busca por nome, apelido ou telefone e filtro ativo/inativo funcionam.
- [x] Alterações em participantes, pessoas ou grupos incrementam a revisão de pareamento.
- [x] Layout funciona em 360×800 e em desktop.

### 5.6 Testes e comandos

```powershell
flutter analyze
flutter test
flutter test test/features/participants
flutter test test/features/groups
flutter build web --release
```

**Testes obrigatórios:**

- repositório: `(eventId, personId)` único; remoção em cascata de grupo; pessoa referenciada não é apagada;
- validação: nome/apelido/telefone; nome de grupo único sem diferenciar maiúsculas;
- formulário: criação inline de grupo preserva os campos;
- responsável: próprio, externo, participante, sem telefone e sem cadeia;
- duplicidade: nome e telefone geram aviso, não bloqueio;
- widget: busca, filtro, confirmação de exclusão e estado vazio;
- persistência: recarregar a página mantém os dados (verificação manual na Web).

**Resultado:** critérios aprovados em 2026-11-03. A tentativa de automatizar a busca/filtro com um teste isolado de widget ficou travada em `pumpAndSettle`; a mesma busca por apelido e o filtro de inativos foram conferidos manualmente no navegador. A limitação do harness está registrada em `docs/PROGRESSO.md`.

### 5.7 Riscos e limitações

| Risco | Mitigação |
| --- | --- |
| Formulário grande perder dados ao abrir grupo inline | Estado controlado e teste específico de preservação. |
| Ambiguidade entre pessoa e participante | UI sempre identifica pessoa e evento; modelo separado desde o início. |
| Telefone compartilhado parecer erro | Aviso explícito de que é permitido. |
| Grupo restrito usado como “proibição entre pares” | Deixar claro que grupos agrupam pessoas; pares específicos ficam fora do MVP. |
| Pessoa reutilizável apagada por engano | Bloquear exclusão quando houver vínculo; oferecer remover vínculos primeiro. |

### 5.8 Portão de saída

A Fase 2 foi aceita em 2026-11-03, após implementação, testes automatizados e verificações manuais. A Fase 3 foi autorizada pelo usuário em 2026-11-03; as Fases 4 e 5 continuam exigindo autorização própria.

---

## 6. Fase 3 — Sorteio, validação e persistência

**Objetivo:** realizar um sorteio correto, uniforme entre soluções válidas, persistido de forma atômica e protegido contra alterações silenciosas.

**Dependências:** Fase 2 aceita.

### 6.1 Escopo incluído

1. Verificação completa de viabilidade por matching máximo.
2. Diagnóstico legível para configurações impossíveis.
3. Amostragem uniforme entre correspondências perfeitas válidas.
4. Revisão final antes do sorteio.
5. Confirmação explícita e gravação transacional de sorteio, atribuições e entregas.
6. Revisão de pareamento (`pairingRevision`) e proteção contra conflito.
7. Tela de resultado com cartões ocultos e revelação individual.
8. Retomada do mesmo resultado ao reabrir.
9. Bloqueio de edição de pessoas, participantes, responsáveis e grupos após sorteio ativo.
10. Invalidação explícita com impacto e preservação do histórico.
11. Criação de entregas com snapshots de dono, destinatário, telefone e mensagem usando o modelo padrão do evento (sem abrir WhatsApp).

### 6.2 Fora do escopo

- editor de modelo de mensagem, fila e links do WhatsApp (Fase 4);
- backup (Fase 5);
- pares proibidos específicos e histórico de eventos anteriores.

### 6.3 Checklist

- [x] Implementar grafo bipartido e matching máximo (Hopcroft–Karp).
- [x] Implementar diagnóstico de impossibilidade e sugestões sem salvar alterações.
- [x] Implementar amostragem uniforme por caminhos alternados.
- [x] Implementar RNG injetável e testes determinísticos.
- [x] Implementar tela de revisão com pendências e botão “Sortear” condicionado à viabilidade.
- [x] Implementar confirmação explícita antes de gravar.
- [x] Implementar transação idempotente com verificação de revisão.
- [x] Implementar snapshots de entrega sem integração com WhatsApp.
- [x] Implementar resultado oculto por padrão e revelação individual.
- [x] Implementar bloqueios nos repositórios de edição para sorteios ativos.
- [x] Implementar invalidação no repositório e confirmação com impacto na interface.
- [x] Cobrir matching, diagnósticos, uniformidade, limite de 200, persistência, conflito, invalidação e histórico.
- [x] Atualizar `docs/PROGRESSO.md`.

**Estado em 2026-11-03:** implementação principal concluída. O fluxo foi conferido manualmente em navegador: confirmação, revelação individual, recarga com resultado oculto, bloqueio de edição com atalho para invalidação, confirmação/impacto da invalidação e viewport 360×800. Foram acrescentados testes isolados de widget para resultado oculto/revelação, nomes semânticos, alvo de toque, viewport 360×800 com texto ampliado e diagnóstico nominal de participante sem opção. O aceite final continua pendente da revisão manual de teclado, foco, leitor de tela e contraste.

### 6.4 Arquivos e módulos previstos

```text
lib/features/draw/domain/draw_engine.dart
lib/features/draw/domain/matching.dart
lib/features/draw/domain/draw_models.dart
lib/features/draw/domain/draw_diagnostics.dart
lib/features/draw/data/draw_repository.dart
lib/features/draw/presentation/review_page.dart
lib/features/draw/presentation/draw_page.dart
lib/features/draw/presentation/result_page.dart
lib/features/draw/presentation/invalidate_draw_dialog.dart
lib/features/delivery/domain/recipient_resolver.dart
lib/features/delivery/domain/message_template.dart
test/features/draw/...
test/features/delivery/message_template_test.dart
```

### 6.5 Critérios de aceite observáveis

- [x] Com 0 ou 1 ativo, o sorteio é bloqueado com explicação.
- [x] Todos no mesmo grupo restrito: impossível, sem relaxar regras.
- [x] Grupo restrito maior que a metade dos ativos: impossível, com sugestão.
- [x] Participante sem opção válida é identificado (teste do domínio e nome apresentado na tela).
- [x] Configuração válida gera exatamente uma saída e uma entrada por ativo.
- [x] Ninguém tira a si mesmo; nenhum par restrito aparece.
- [x] Múltiplos grupos e sobreposições são respeitados.
- [x] Vários ciclos são aceitos (teste determinístico encontra e aceita saída com mais de um ciclo).
- [x] Distribuição uniforme entre soluções válidas é demonstrada por teste estatístico com tolerância.
- [x] O sorteio é salvo antes de qualquer ação de envio.
- [x] Falha de revisão não deixa registros parciais (teste de transação).
- [x] Reabrir o app mostra o mesmo sorteio persistido; recarga manual voltou a mostrar todos os cartões ocultos.
- [x] Resultados ficam ocultos até revelação individual (confirmado manualmente).
- [x] Após o sorteio, editar pessoa/participante/responsável/grupo é bloqueado; formulário mostra atalho para invalidar.
- [x] Invalidação pede confirmação, mostra impacto e preserva o histórico (manual e teste de repositório).
- [x] Novo sorteio após invalidação cria novos registros.

### 6.6 Testes e comandos

```powershell
flutter analyze
flutter test test/features/draw
flutter test test/features/delivery/message_template_test.dart
flutter test
flutter build web --release
```

**Testes obrigatórios:**

- 0 e 1 ativo;
- todos no mesmo grupo restrito;
- grupo restrito com mais da metade dos ativos;
- múltiplos grupos sobrepostos e restrição desativada;
- participante isolado;
- 200 ativos com desempenho aceitável;
- uniformidade com RNG determinístico e tolerância estatística;
- todas as invariantes de saída;
- transação idempotente, conflito de revisão e falha sem estado parcial;
- retomada após recarregar;
- bloqueio de edição e invalidação com histórico.

### 6.7 Riscos e limitações

| Risco | Mitigação |
| --- | --- |
| Algoritmo incorreto ou enviesado | Matching exato + testes exaustivos para n pequeno + teste estatístico. |
| Teste estatístico instável | Semente fixa, amostra ampla e tolerância documentada; não usar teste frágil em CI. |
| Sorteio salvo pela metade | Candidato fora da transação e gravação atômica idempotente. |
| Edição concorrente em duas abas | Revisão de pareamento detecta conflito; documentar uso em uma aba. |
| Invalidação apagar histórico | Nunca excluir draw/assignments/deliveries; apenas marcar como invalidado. |
| Usuário não entender bloqueio | Mensagem explica o motivo e oferece “Invalidar sorteio”. |

### 6.8 Portão de saída

A Fase 3 foi aceita em 2026-11-03, após testes automatizados e verificação manual de acessibilidade confirmada pelo usuário. A Fase 4 foi iniciada com autorização explícita do usuário na mesma data; a Fase 5 continua exigindo nova autorização.

---

## 7. Fase 4 — WhatsApp e acompanhamento de entregas

**Objetivo:** transformar o resultado salvo em mensagens individuais, abrir a conversa correta e acompanhar o que o organizador confirma.

**Dependências:** Fase 3 aceita; decisão de usar link universal `wa.me` confirmada (já registrada no ADR-004).

### 7.1 Escopo incluído

1. Editor de modelo de mensagem por evento com as variáveis permitidas.
2. Validação de variáveis, chaves e limite de tamanho; prévia com dados fictícios.
3. Resolução de destinatário: próprio participante ou responsável direto.
4. Normalização de telefone e geração de link `wa.me` codificado.
5. Fila de entregas com dono, destinatário, número e mensagem.
6. Estados `Pendente`, `Conversa aberta` e `Envio confirmado pelo organizador`.
7. Ações: abrir WhatsApp, copiar mensagem, reabrir, marcar como enviado e filtrar pendentes.
8. Tratamento de falha ao abrir, pop-up bloqueado e entrega sem contato.
9. Confirmação manual com método `whatsapp` ou `manual`.
10. Mensagens separadas para várias pessoas com o mesmo responsável.
11. Atualização apenas de mensagens pendentes quando o modelo mudar.

### 7.2 Fora do escopo

- envio automático, API oficial, automação do WhatsApp Web ou confirmação de entrega/leitura;
- notificações, lembretes ou fila em background;
- backup (Fase 5).

### 7.3 Checklist

- [x] Implementar `MessageTemplate` com parser restrito e erros tipados.
- [x] Implementar prévia com dados fictícios.
- [x] Reutilizar a normalização para E.164 existente em `participants/domain/phone_number.dart`.
- [x] Reutilizar o resolvedor de destinatário direto, sem cadeia, existente em `participants/domain/guardian_resolver.dart`.
- [x] Implementar `WhatsAppLink` com `Uri.encodeComponent`.
- [x] Implementar `WhatsAppLauncher` injetável.
- [x] Implementar fila, cartões, filtro e estados.
- [x] Implementar copiar, reabrir, marcar como enviado e confirmação manual.
- [x] Implementar tratamento de falha e entrega sem contato.
- [x] Implementar atualização de mensagens pendentes após editar o modelo.
- [x] Cobrir link, telefone, modelo, destinatário e estados com testes automatizados.
- [x] Atualizar `docs/PROGRESSO.md`.

### 7.4 Arquivos e módulos previstos

```text
lib/core/phone/phone_number.dart
lib/features/delivery/domain/message_template.dart
lib/features/delivery/domain/recipient_resolver.dart
lib/features/delivery/domain/whatsapp_link.dart
lib/features/delivery/domain/delivery_status.dart
lib/features/delivery/data/delivery_repository.dart
lib/features/delivery/presentation/delivery_queue_page.dart
lib/features/delivery/presentation/delivery_card.dart
lib/features/delivery/presentation/message_template_page.dart
lib/features/delivery/presentation/whatsapp_launcher.dart
test/core/phone/...
test/features/delivery/...
```

### 7.5 Critérios de aceite observáveis

- [ ] O link abre a conversa do destinatário correto com a mensagem pronta.
- [ ] Em verificação manual, o link abre o destinatário correto com a mensagem pronta (sem enviar).
- [x] Números são normalizados; `+` é removido do link.
- [x] Acentos, emojis, quebras de linha e caracteres especiais são codificados corretamente.
- [x] Abrir a conversa muda para “Conversa aberta”, nunca para “Envio confirmado” (launcher fake).
- [x] “Marcar como enviado” pede confirmação e registra o método.
- [x] “Copiar mensagem” não altera o estado.
- [x] “Reabrir” preserva uma confirmação existente.
- [x] Filtro de pendentes mostra apenas pendentes.
- [x] Várias pessoas com o mesmo responsável geram entregas e mensagens separadas.
- [x] Entrega sem contato é identificada e pode ser confirmada como manual.
- [x] O app não exibe estados “entregue” ou “lido”.
- [x] Variável desconhecida ou chave não fechada gera erro de validação.
- [x] Mensagens abertas/confirmadas mantêm o conteúdo; pendentes podem ser atualizadas com ação explícita.
- [x] Falha ao abrir mantém a entrega pendente e oferece copiar.

### 7.6 Testes e comandos

```powershell
flutter analyze
flutter test test/core/phone
flutter test test/features/delivery
flutter test
flutter build web --release
```

**Testes obrigatórios:**

- telefones `(11) 90000-0001`, `+55 11 90000-0001`, `+1 202 555 0100` e inválidos;
- link com acentos, emojis e quebras de linha;
- modelo com cada variável, variável desconhecida, chave aberta e limite de 2.000;
- nomes contendo chaves não são reprocessados;
- destinatário próprio, responsável externo, responsável participante, sem telefone e sem cadeia;
- telefone compartilhado com mensagens separadas;
- transições de estado e falha do launcher;
- confirmação manual e reabertura;
- atualização apenas de pendentes.

### 7.7 Riscos e limitações

| Risco | Mitigação |
| --- | --- |
| WhatsApp Web não conectado | Avisar e oferecer copiar a mensagem. |
| Pop-up bloqueado | Usar navegação direta e oferecer cópia. |
| Número válido sem WhatsApp | Não prometer entrega; confirmar manualmente. |
| Codificação incorreta | Testar `Uri.encodeComponent` com acentos, emojis e quebras. |
| Responsável compartilhado causar confusão | Um cartão por participante, com dono e destinatário explícitos. |
| Interpretar abertura como envio | Estado separado e texto inequívoco. |

### 7.8 Portão de saída

A Fase 4 é aceita quando a fila permite abrir, copiar, confirmar e retomar entregas, com estados honestos e testes passando. **A Fase 5 só começa com nova autorização.**

---

## 8. Fase 5 — Acabamento, backup e validação final

**Objetivo:** tornar o MVP recuperável, acessível, responsivo e pronto para uso real, sem publicar sem autorização.

**Dependências:** Fase 4 aceita; decisão de hospedagem definida antes de qualquer publicação.

### 8.1 Escopo incluído

1. Exportação e importação de backup JSON versionado, com validação e substituição atômica.
2. Avisos de sensibilidade e recomendação de backup após o sorteio.
3. Revisão de responsividade em celular e desktop.
4. Acessibilidade: foco, rótulos, contraste, escala de texto e navegação por teclado.
5. Estados vazios, mensagens de erro e confirmações em todo o fluxo.
6. Revisão de desempenho com 200 participantes.
7. Regressão completa e correção de defeitos.
8. Build Web release, manifesto PWA e instruções de publicação (sem publicar).
9. Documentação final e registro de limitações conhecidas.

### 8.2 Fora do escopo

- deploy, compra de domínio, publicação em loja ou envio real de mensagens sem autorização;
- Android/iOS;
- criptografia de backup, login ou sincronização.

### 8.3 Checklist

- [ ] Implementar serialização versionada de todos os stores.
- [ ] Implementar exportação com nome de arquivo sem dados pessoais.
- [ ] Implementar importação com limite de tamanho, validação de schema/referências e prévia.
- [ ] Implementar substituição atômica e reabertura dos providers.
- [ ] Implementar avisos de backup sensível.
- [ ] Revisar layout em 360×800, tablet e desktop.
- [ ] Revisar foco, semântica, contraste, toque e escala de texto.
- [ ] Revisar estados vazios e textos em pt-BR.
- [ ] Executar regressão completa e teste de desempenho.
- [ ] Configurar manifesto/ícones PWA e build release.
- [ ] Atualizar README, PROGRESSO, AMBIENTE, TESTES e limitações.
- [ ] Preparar instruções de publicação sem executá-las.

### 8.4 Arquivos e módulos previstos

```text
lib/features/backup/data/backup_service.dart
lib/features/backup/data/backup_schema.dart
lib/features/backup/presentation/backup_page.dart
lib/features/settings/...
lib/shared/layout/...
lib/shared/widgets/...
web/manifest.json
web/icons/
docs/...
```

### 8.5 Critérios de aceite observáveis

- [ ] Exportar gera JSON com versão, metadados e todos os dados.
- [ ] Importar backup válido mostra prévia e substitui os dados após confirmação.
- [ ] Backup inválido é rejeitado sem alterar a base atual.
- [ ] Após importar, sorteio ativo e entregas são restaurados.
- [ ] O app avisa que o arquivo contém telefones e resultados.
- [ ] Fluxo completo funciona em 360×800 e em desktop.
- [ ] Navegação por teclado e leitor de tela funcionam nos controles principais.
- [ ] Texto em 200% não corta ações essenciais.
- [ ] Estados vazios orientam a próxima ação.
- [ ] Ações destrutivas pedem confirmação.
- [ ] 200 participantes ativos são sorteados em tempo aceitável, sem travar a interface.
- [ ] `flutter build web --release` conclui e o artefato abre localmente.
- [ ] Documentação e limitações estão atualizadas.
- [ ] Nenhuma publicação foi feita sem autorização.

### 8.6 Testes e comandos

```powershell
flutter analyze
flutter test
flutter build web --release
flutter run -d chrome --web-port 8080 --release
```

**Testes obrigatórios:**

- round-trip exportar/importar;
- backup com versão futura, campo ausente, referência quebrada e JSON inválido;
- importação atômica com falha simulada;
- restauração de sorteio ativo e entregas;
- widget responsivo e semântica;
- regressão de todas as fases;
- verificação manual em Chrome e Edge;
- verificação manual de teclado, leitor de tela e escala de texto.

### 8.7 Riscos e limitações

| Risco | Mitigação |
| --- | --- |
| Backup sobrescrever dados bons | Prévia + confirmação + transação atômica + sugerir exportar antes. |
| Backup sensível compartilhado | Aviso explícito e nenhum envio automático. |
| IndexedDB limpo | Documentar e recomendar backup; não prometer persistência eterna. |
| Acessibilidade tratada no fim | Checklist por fase e revisão final com testes manuais. |
| Publicação acidental | Nenhum comando de deploy sem autorização explícita. |
| Regressão em fluxo longo | Integração ponta a ponta com dados fictícios e launcher falso. |

### 8.8 Portão de saída

A Fase 5 e o MVP são aceitos quando todos os critérios acima forem demonstrados, a documentação estiver atualizada e o usuário aprovar o resultado. **Publicação e uso com dados reais continuam exigindo autorização separada.**

---

## 9. Critérios de conclusão de qualquer fase

Uma fase só é considerada concluída quando:

1. o escopo autorizado foi implementado e o que ficou de fora está registrado;
2. os critérios de aceite observáveis foram demonstrados;
3. os testes obrigatórios foram executados e passaram, ou as falhas estão documentadas com impacto;
4. `flutter analyze` e a formatação estão limpos;
5. `docs/PROGRESSO.md` contém comandos, resultados e o próximo passo;
6. a documentação afetada foi atualizada;
7. não há segredos, dados pessoais reais ou backups no repositório;
8. o usuário autorizou a fase seguinte, se houver.

## 10. Controle de mudanças

- Mudança de escopo dentro de uma fase: registrar em `docs/PROGRESSO.md` e pedir confirmação se alterar critérios de aceite.
- Mudança de arquitetura ou dependência: atualizar `docs/ARQUITETURA.md` e criar/atualizar um ADR.
- Mudança de regra de negócio: atualizar `docs/REQUISITOS.md` e os testes correspondentes.
- Descoberta de que uma fase anterior está incompleta: parar, registrar e corrigir antes de avançar, com autorização.
- Não usar `flutter clean`, apagar banco ou reverter trabalho do usuário para contornar problemas.

## 11. Decisões pendentes

| Decisão | Quando é necessária | Padrão recomendado |
| --- | --- | --- |
| Confirmar Flutter Web como plataforma inicial | Antes da Fase 1 | Web primeiro; Android depois |
| Android dentro do MVP | Antes da Fase 1 | Fora do MVP |
| Onde publicar a versão Web | Antes da Fase 5 | Definir somente com autorização |
| Limite de participantes para aceite | Antes da Fase 3 | 200 ativos |
| Exclusão definitiva ou arquivamento | Antes da Fase 2 | Exclusão com confirmação |
| Backup sem senha | Antes da Fase 5 | Aceitável no MVP, com aviso |
