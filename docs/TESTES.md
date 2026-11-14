# Testes e verificação

Este documento é a fonte de verdade para a **estratégia de testes**, os cenários obrigatórios e a forma de comprovar resultados. Nenhum teste deve usar dados pessoais reais.

## 1. Princípios

- **Dados fictícios apenas.** Nomes, apelidos e telefones de teste são inventados.
- **Determinismo onde possível.** Relógio, IDs, aleatoriedade, launcher e arquivos são injetados.
- **Testar regras no domínio.** Sorteio, telefone, mensagem e destinatário são Dart puro.
- **Poucos testes de UI, mas nos fluxos críticos.** Formulários longos, confirmações e resultados ocultos.
- **Nenhum teste abre o WhatsApp real.** O launcher é substituído por um fake.
- **Nenhum teste depende de ordem, rede ou estado global.**
- **Falha não é escondida.** Se um teste falhar, registrar o impacto em `docs/PROGRESSO.md`.

## 2. Níveis de teste

| Nível | Ferramenta | O que cobre | Quando |
| --- | --- | --- | --- |
| Unitário de domínio | `flutter_test` | Sorteio, restrições, telefone, modelo, destinatário, validações | Fases 2–5 |
| Unitário de dados | `flutter_test` + Sembast em memória | Repositórios, transações, migrações, backup | Fases 2–5 |
| Widget | `flutter_test` + `ProviderScope` | Formulários, listas, estados, confirmações, responsividade | Fases 2–5 |
| Integração | `integration_test` + `flutter drive` | Fluxo Web completo com dependências falsas | Fases 2–5 |
| Manual | Chrome/Edge/celular | Persistência real, WhatsApp, teclado, leitor de tela, PWA | Todas as fases |

Não é meta atingir 100% de cobertura. A meta é cobrir todas as regras e critérios de aceite com testes significativos.

## 3. Ferramentas e substitutos (fakes)

Para executar o fluxo de integração Web no Chrome, use o driver do projeto:

```bash
flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart
```

| Dependência | Substituto nos testes | Comportamento |
| --- | --- | --- |
| `Clock` | `FakeClock` | Retorna data fixa ou avançada manualmente |
| `IdGenerator` | `SequentialIdGenerator` | Gera `id-1`, `id-2`, ... |
| `Random` | `Random(semente)` | Reproduzível |
| `WhatsAppLauncher` | `RecordingWhatsAppLauncher` | Registra URI; simula sucesso/falha |
| `BackupFileService` | `FakeBackupFileService` | Devolve bytes fixos; simula cancelamento/erro |
| Banco | `databaseFactoryMemory` | Sem arquivo/IndexedDB; isolado por teste |
| Tempo/agendamento | Evitar `Future.delayed` | Usar `pump`/`pumpAndSettle` com cuidado |

Regras:

- Cada teste abre um banco novo em memória e o fecha no `tearDown`.
- Providers são sobrescritos no `ProviderContainer` ou `ProviderScope`.
- Nenhum teste depende de `DateTime.now()` real.
- Nenhum teste grava em `%APPDATA%`, no projeto ou em backup real.
- O launcher fake nunca chama `url_launcher`.

## 4. Dados fictícios

### 4.1 Nomes

Usar nomes claramente fictícios e variados:

- Ana, Bruno, Carla, Diego, Elisa, Felipe, Gabriela, Hugo;
- apelidos: “Aninha”, “Bru”, “Cacá”, “Dudu”;
- casos com acentos, cedilha, hífen, apóstrofo e emoji em testes de mensagem.

### 4.2 Telefones

Usar somente números reservados para teste, nunca números de pessoas reais:

```text
+55 11 90000-0001
+55 11 90000-0002
+55 21 90000-0003
+1 202 555 0100
```

Esses números são fictícios. Não os use para enviar mensagens reais.

### 4.3 Proibições

- Não copiar nomes/telefones de participantes reais para testes, prints, issues ou documentação.
- Não commitar backups, bancos, exports ou capturas com dados reais.
- Não usar o número pessoal do desenvolvedor em testes automatizados.
- Em teste manual de WhatsApp, usar apenas um número de teste autorizado e não confirmar envio a terceiros.

## 5. Cobertura por fase

### 5.1 Fase 1 — Fundação

| Caso | Tipo | Esperado |
| --- | --- | --- |
| Abrir banco em memória | Unitário | Store `meta` criado com `schemaVersion = 1` |
| Gravar e ler metadados | Unitário | Valor persistido e recuperado |
| Transação com erro | Unitário | Nada é gravado |
| App abre na rota inicial | Widget | Shell em pt-BR, sem exceção |
| Tema e layout | Widget | Material 3; `NavigationBar` no compacto e `NavigationRail` no expandido |
| Recarregar a página | Manual | Banco reabre na mesma origem |

**Situação em 2026-11-03:** implementados em `test/core/database/app_database_test.dart`, `test/app/app_smoke_test.dart` e `test/app/database_failure_test.dart`; `flutter test` executou 6 testes com sucesso. A recarga foi verificada em `http://127.0.0.1:8080`, com `meta.schemaVersion = 1` e `createdAt` preservado no IndexedDB.

### 5.2 Fase 2 — Cadastro e organização

| Caso | Tipo | Esperado |
| --- | --- | --- |
| Criar/editar/excluir evento | Unitário + widget | Persistência e confirmação |
| Nome de evento vazio | Unitário/widget | Erro claro, sem gravar |
| Reutilizar pessoa | Unitário | Mesma pessoa, sem duplicar |
| Participação duplicada no evento | Unitário | Bloqueada |
| Criar grupo inline | Widget | Campos do formulário preservados |
| Nome de grupo duplicado | Unitário | Bloqueado, sem diferenciar maiúsculas |
| Remover participante | Unitário | Remove dos grupos; mantém a pessoa |
| Apagar pessoa vinculada | Unitário | Bloqueado |
| Nome repetido | Unitário/widget | Aviso; salva |
| Telefone repetido | Unitário/widget | Aviso; salva |
| Responsável externo | Unitário | Resolvido no telefone próprio |
| Responsável participante | Unitário | Resultado do responsável separado |
| Responsável sem telefone | Unitário | “Sem contato”; não segue cadeia |
| Responsável de si mesmo | Unitário | Bloqueado |
| Busca/filtro | Widget | Resultados corretos |

**Situação em 2026-11-03:** repositórios de eventos, participantes e grupos têm testes unitários em `test/features/`; há testes de widget em `test/app/phase2_flow_test.dart`. A suíte cobre a migração 1→2, a preservação de nome/apelido/telefone na criação inline e a detecção de dados duplicados. `flutter test` executou 36 testes com sucesso. Busca/filtro, aviso de duplicidade e salvamento após o aviso também foram conferidos manualmente no navegador.
| Estado vazio | Widget | Orientação e ação principal |
| Recarregar | Manual | Dados mantidos |

### 5.3 Fase 3 — Sorteio e integridade

Ver matriz detalhada na seção 6. Os testes atuais cobrem matching, restrições sobrepostas, diagnóstico de participante sem opção, amostragem uniforme dos dois derangements de 3 participantes, saída com vários ciclos, cenário com 200 ativos, persistência atômica, idempotência, conflito de revisão, bloqueio em participantes/pessoas/grupos, invalidação, histórico e novo sorteio. Testes de widget cobrem resultados ocultos por padrão, revelação de apenas um cartão, rótulo semântico nominal, alvos de toque de 48 px, viewport 360×800 com texto em escala 2.0 e apresentação do diagnóstico com o nome do participante. A confirmação, retomada após recarga, invalidação e revisão manual de teclado, foco, leitor de tela e contraste foram verificadas; o usuário confirmou que os testes manuais ocorreram sem problemas.

### 5.4 Fase 4 — WhatsApp e entregas

**Implementado e automatizado em 2026-11-03:** 34 testes focados passaram, além da suíte completa de 73 testes. A cobertura inclui parser e substituição de variáveis; limite; URI `wa.me`; responsável compartilhado em entregas separadas; estados de fila; falha/sucesso do launcher fake; cópia sem mudança de estado; filtro; confirmações WhatsApp/manual; contato ausente; atualização somente de pendentes; bloqueio de edição se a fila não puder ser carregada. A revisão manual no navegador e a abertura click-to-chat continuam pendentes.

| Caso | Tipo | Esperado |
| --- | --- | --- |
| Telefones aceitos | Unitário | Normalizados para E.164 |
| Telefone inválido | Unitário | Erro no campo; permite salvar sem telefone |
| Link `wa.me` | Unitário | Dígitos apenas, sem `+` |
| Acentos/emojis/quebras | Unitário | Texto preservado após decodificação |
| Variáveis do modelo | Unitário | Substituição correta |
| Variável desconhecida | Unitário | Erro de validação |
| Chave não fechada | Unitário | Erro de validação |
| Chaves no nome | Unitário | Não reprocessadas |
| Limite de 2.000 | Unitário | Aceita até o limite; rejeita acima |
| Destinatário próprio | Unitário | Dono = destinatário |
| Destinatário responsável | Unitário | Responsável direto |
| Sem contato | Unitário | Entrega manual |
| Telefone compartilhado | Widget/unitário | Cartões e mensagens separados |
| Abrir WhatsApp | Unitário/widget | Estado `opened`, nunca `confirmed` |
| Falha do launcher | Unitário/widget | Permanece `pending`; oferece copiar |
| Marcar como enviado | Widget | Confirmação; estado `confirmed` e método |
| Reabrir | Widget | Preserva confirmação |
| Filtro pendentes | Widget | Somente `pending` |
| Modelo alterado | Unitário | Pendentes atualizadas; abertas/confirmadas mantidas |

### 5.5 Fase 5 — Backup e acabamento

**Estado parcial em 2026-11-04:** testes de serviço/widget cobrem round-trip, validação, prévia, confirmação, responsividade a 200% e atomicidade. A regressão completa passou (87 testes). Chrome integrado exercitou a exportação e importação de arquivos fictícios em origem isolada; layouts 360×800, 768×1024 e 1280×900 foram inspecionados; a ordem de teclado foi observada e os pares principais de contraste têm teste automatizado. Leitor de tela real, zoom manual do navegador a 200% e fluxo de arquivo no Edge ainda precisam de verificação.

A integração Web foi tentada em 2026-11-04. `flutter test integration_test` não seleciona dispositivo quando há vários conectados; com `-d chrome`, o comando informa que Web não é suportado. `flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart` iniciou o Chrome, mas ficou aguardando o serviço de depuração por mais de três minutos e foi interrompido. O fluxo de integração segue pendente; os 87 testes unitários/widget passaram.

O teste `test/app/theme_accessibility_test.dart` verifica contraste ≥4,5:1 nos pares principais das paletas clara/escura. `test/tools/draw_performance_fixture_test.dart` gera em `%TEMP%\amigo-secreto-backup-test-200.json` um backup de demonstração com 200 nomes fictícios e um telefone fictício; o arquivo deve ser removido manualmente quando não for mais necessário para teste manual.

| Caso | Tipo | Esperado |
| --- | --- | --- |
| Exportar/importar | Unitário + integração | Round-trip completo |
| Versão futura | Unitário | Rejeitada sem alterar dados |
| Campo ausente | Unitário | Rejeitado |
| Referência quebrada | Unitário | Rejeitado |
| JSON malformado | Unitário | Rejeitado |
| Falha no meio da importação | Unitário | Nada alterado |
| Sorteio ativo restaurado | Integração | Mesmo resultado e entregas |
| Layout 360×800 | Widget/manual | Sem overflow; ações acessíveis |
| Layout desktop | Widget/manual | Uso confortável |
| Escala de texto 200% | Widget/manual | Sem corte de ações |
| Semântica/foco | Widget/manual | Rótulos e ordem lógicos |
| 200 participantes | Performance | Sorteio em tempo aceitável |

## 6. Matriz do sorteio

### 6.1 Correção

| ID | Cenário | Entrada | Esperado |
| --- | --- | --- | --- |
| S-01 | Sem ativos | 0 | Bloqueado com explicação |
| S-02 | Um ativo | 1 | Bloqueado com explicação |
| S-03 | Dois ativos, sem restrição | 2 | Cada um tira o outro |
| S-04 | Sem restrição | n | Ninguém tira a si mesmo; uma saída/entrada por ativo |
| S-05 | Todos no mesmo grupo restrito | n | Impossível; sem relaxar |
| S-06 | Grupo restrito > metade | n | Impossível; sugestão de ajuste |
| S-07 | Grupo restrito = metade | n | Pode ser possível ou não; matching decide |
| S-08 | Múltiplos grupos sobrepostos | n | União das restrições respeitada |
| S-09 | Restrição desativada | n | Par permitido naquele grupo |
| S-10 | Participante isolado | n | Identificado; bloqueado |
| S-11 | Vários ciclos | n | Aceito |
| S-12 | Ciclo único | n | Aceito quando ocorrer |
| S-13 | 200 ativos | 200 | Resultado válido em tempo aceitável |
| S-14 | Grupo com 1 membro | 1 | Não restringe ninguém |
| S-15 | Grupo vazio | 0 membros | Não restringe ninguém |

### 6.2 Invariantes verificadas em toda saída

Para toda solução retornada:

1. o conjunto de givers é igual ao conjunto de ativos;
2. o conjunto de receivers é igual ao conjunto de ativos;
3. cada giver aparece exatamente uma vez;
4. cada receiver aparece exatamente uma vez;
5. `giver != receiver`;
6. nenhum par proibido aparece;
7. todos os IDs pertencem ao evento;
8. nenhum participante inativo aparece;
9. o resultado é determinístico para a mesma semente;
10. o resultado não altera a entrada.

### 6.3 Uniformidade

Estratégia em duas camadas:

1. **Exaustão para n pequeno:** para n ≤ 6, enumerar todas as permutações válidas e confirmar que o conjunto de soluções suportadas pelo algoritmo coincide com a enumeração e que nenhuma solução inválida aparece.
2. **Amostragem com semente fixa:** para um cenário pequeno (por exemplo, 4 pessoas sem restrição, 9 derangements), gerar uma amostra grande (≥ 20.000) e comparar as frequências com a distribuição uniforme esperada.

Regras para evitar teste frágil:

- usar `Random(semente)` fixa;
- documentar a semente;
- usar tolerância relativa ampla (por exemplo, 10%) ou teste qui-quadrado com nível conservador;
- não usar tempo real como fonte de aleatoriedade;
- não executar o teste estatístico em todas as combinações; escolher cenários representativos.

A uniformidade é entre **soluções válidas**, não entre formatos de ciclos. O teste não deve exigir um ciclo único.

### 6.4 Persistência e concorrência

| ID | Cenário | Esperado |
| --- | --- | --- |
| P-01 | Confirmar sorteio | Draw, assignments, deliveries e `activeDrawId` gravados juntos |
| P-02 | Repetir a mesma confirmação | Nenhum novo sorteio; payload idempotente |
| P-03 | Revisão mudou antes da gravação | Transação aborta; evento continua em rascunho |
| P-04 | Falha no meio da transação | Nada parcial |
| P-05 | Reabrir o banco | Mesmo draw e assignments |
| P-06 | Dois draws ativos no mesmo evento | Impossível por invariante |
| P-07 | Invalidação | Draw antigo `invalidated`; assignments/deliveries preservados |
| P-08 | Novo sorteio após invalidação | Novos IDs e novos registros |
| P-09 | Assignment com giver duplicado | Rejeitado |
| P-10 | Assignment com receiver duplicado | Rejeitado |
| P-11 | Assignment de outro evento | Rejeitado |

### 6.5 Bloqueio e invalidação

| ID | Cenário | Esperado |
| --- | --- | --- |
| B-01 | Editar participante após sorteio | Bloqueado com explicação |
| B-02 | Editar pessoa usada em outro evento sorteado | Bloqueado; eventos indicados |
| B-03 | Criar/editar grupo após sorteio | Bloqueado |
| B-04 | Alterar restrição após sorteio | Bloqueado |
| B-05 | Editar modelo de mensagem | Permitido; pendentes podem ser atualizadas |
| B-06 | Invalidar com mensagens abertas | Confirmação mostra contagem |
| B-07 | Invalidar com mensagens confirmadas | Confirmação destaca impacto |
| B-08 | Cancelar invalidação | Nada muda |
| B-09 | Confirmar invalidação | Evento volta a rascunho; histórico mantido |

## 7. Testes de telefone e link

### 7.1 Entrada e armazenamento

| Entrada | Esperado |
| --- | --- |
| `(11) 90000-0001` | `+5511900000001` |
| `11900000001` | `+5511900000001` |
| `+55 11 90000-0001` | `+5511900000001` |
| `+1 202 555 0100` | `+12025550100` |
| `abc` | Inválido |
| `+` | Inválido |
| vazio | Permitido como ausente |
| número muito curto/longo | Inválido |

Regras:

- armazenar `+` seguido de dígitos;
- não exigir celular;
- não usar `localStorage`;
- telefone inválido bloqueia apenas o campo, não o cadastro inteiro.

### 7.2 Link

| Caso | Esperado |
| --- | --- |
| Número `+5511900000001` | `https://wa.me/5511900000001?text=...` |
| Texto com `á`, `ç`, emoji | Percent-encoding correto |
| Texto com `\n` | `%0A` |
| Texto com `&`, `?`, `#` | Codificado como texto |
| Texto vazio | Permitido ou validado conforme a tela |
| Sem telefone | Não gerar link; oferecer manual |

Verificação: decodificar o parâmetro `text` e comparar com a mensagem original.

## 8. Testes de mensagem

| Caso | Esperado |
| --- | --- |
| `{evento}` | Nome do evento |
| `{participante}` | Nome completo do dono |
| `{apelido}` | Apelido do dono ou nome completo |
| `{sorteado}` | Apelido do sorteado ou nome completo |
| `{responsavel}` | Responsável ou o próprio participante |
| `{desconhecida}` | Erro de validação |
| `{evento` | Erro de chave não fechada |
| `{{evento}}` | Erro de validação; não substituir silenciosamente |
| Nome com `{evento}` | Texto literal, sem reprocessar |
| Nome com emoji/quebra | Preservado |
| Texto com 2.000 caracteres | Aceito |
| Texto com 2.001 | Rejeitado |
| Modelo vazio | Rejeitado ou usa padrão, conforme decisão documentada |

A substituição é feita em uma passada; o texto inserido não é reprocessado.

## 9. Testes de interface e acessibilidade

### 9.1 Widget

- `ProviderScope` com overrides;
- tamanhos: 360×800, 800×1280 e 1280×800;
- escala de texto: 1.0, 1.5 e 2.0;
- estados: carregando, vazio, erro, sucesso;
- confirmações destrutivas;
- resultados ocultos e revelação individual;
- formulário com criação inline de grupo;
- foco e ordem de tabulação;
- semântica com `tester.ensureSemantics()`;
- nenhum overflow visível.

### 9.2 Manual

- teclado: Tab/Shift+Tab, Enter, Espaço, Escape;
- leitor de tela: Narrator no Windows ou NVDA;
- contraste: verificar textos e botões principais;
- toque: alvos de pelo menos 48×48;
- zoom do navegador em 200%;
- celular real ou emulação de viewport;
- recarregar e retomar.

## 10. Testes de backup

| Caso | Esperado |
| --- | --- |
| Exportar base vazia | JSON válido com versão |
| Exportar base completa | Todos os stores e referências |
| Importar o próprio export | Round-trip idêntico |
| Versão futura | Rejeitado; dados atuais intactos |
| Campo obrigatório ausente | Rejeitado |
| Referência quebrada | Rejeitado |
| JSON inválido | Rejeitado |
| Arquivo grande | Limite e mensagem clara |
| Falha durante substituição | Nada alterado |
| Importar com sorteio ativo | Draw, assignments e deliveries restaurados |
| Nome do arquivo | Sem nomes/telefones |

O backup é sensível: os testes usam somente dados fictícios e não deixam arquivos no repositório.

## 11. Testes de integração

Fluxos mínimos:

1. criar evento → adicionar 4 pessoas → criar família → revisar → sortear → confirmar;
2. abrir resultado → revelar → reabrir app → mesmo resultado;
3. abrir WhatsApp com launcher fake → estado `opened` → confirmar manualmente;
4. tentar editar após sorteio → bloqueio → invalidar → editar → novo sorteio;
5. responsável externo e telefone compartilhado → cartões separados;
6. participante sem contato → entrega manual;
7. exportar → limpar base de teste → importar → dados restaurados;
8. backup inválido → rejeitado → dados intactos.

Na Web, `integration_test` pode exigir Chromedriver. Quando não estiver disponível, executar os fluxos equivalentes como testes de widget e registrar a verificação manual. Não declarar teste de integração executado sem tê-lo executado.

## 12. Comandos

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test test/features/draw
flutter build web --release
```

Teste de integração Web no Chrome:

```powershell
flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart
```

Executar sempre a partir da raiz clonada do repositório.

## 13. Evidências e registro

Para cada fase, registrar em `docs/PROGRESSO.md`:

- comandos executados;
- resultado (sucesso/falha);
- quantidade de testes;
- falhas conhecidas e impacto;
- cenários manuais verificados;
- navegador/dispositivo usado;
- data.

Não anexar capturas com dados reais. Se uma captura for necessária, usar somente dados fictícios.

## 14. Tratamento de falhas e testes instáveis

- Falha reproduzível: corrigir antes de concluir a fase ou registrar como pendência com impacto.
- Teste instável: identificar causa (tempo, ordem, aleatoriedade, rede); não mascarar com `skip`.
- Teste estatístico: usar semente fixa e tolerância documentada; se continuar frágil, reduzir a asserção ao suporte de soluções e manter a uniformidade como verificação separada.
- Teste de integração dependente de Chromedriver: se o ambiente não permitir, registrar a limitação e cobrir o fluxo em widget/manual.
- Nunca alterar o teste para “passar” sem antes confirmar que a regra de negócio está correta.

## 15. Critério de “testado”

Uma funcionalidade só é considerada testada quando:

1. os cenários obrigatórios da fase foram executados;
2. os testes automatizados relevantes passam;
3. os fluxos manuais críticos foram verificados;
4. os resultados estão registrados em `docs/PROGRESSO.md`;
5. não há dados reais, segredos ou artefatos sensíveis no repositório.

## 16. Fora do escopo de testes do MVP

- carga com milhares de eventos simultâneos;
- múltiplos usuários concorrentes;
- Safari/iOS;
- envio real automatizado pelo WhatsApp;
- testes de segurança ofensiva;
- testes de acessibilidade certificados;
- compatibilidade com navegadores antigos.

## 17. Fase 6 — sorteio online

O serviço `server/` usa `dart test` e a suíte Flutter continua sendo executada na raiz. Testes obrigatórios para concluir a fase:

- motor compartilhado conserva invariantes e restrições;
- serviço persiste somente hash SHA-256 do token e não expõe `receiverId` ou `receiverName` no DTO do organizador;
- links diferentes retornam somente seu resultado correspondente; token inválido e revogado não retornam dados;
- IDs/participantes inconsistentes, sorteio impossível e restrições de grupos são rejeitados sem salvar parcial;
- persistência Firestore é idempotente, respeita `pairingRevision` e evita dois sorteios ativos;
- endpoints negam acesso anônimo e evento alheio; endpoints públicos não revelam outros resultados;
- Firebase Emulator cobre regras, transações e fluxo ponta a ponta com dados fictícios;
- 200 participantes online respeitam o mesmo motor e invariantes;
- UI verifica que a lista do organizador não recebe pares e WhatsApp contém somente links;
- revogação invalida o link sem expor resultado;
- nenhum serviço real ou mensagem WhatsApp é usado em testes.
- rascunho online é restaurado no mesmo banco local e não é incluído no backup JSON.

### Verificações locais da primeira integração (2026-11-05)

Executados com dados fictícios: `flutter analyze` sem issues; a suíte inicial da integração online executou 87 testes e a verificação de rascunho local posterior elevou a suíte a 88, todos passando; `dart format --output=none --set-exit-if-changed .` sem alterações; `flutter build web --release` concluído; `dart analyze` em `server/` sem issues; `dart test` em `server/` com 6 testes passando, incluindo API HTTP, posse do evento, revelação/revogação, fluxo REST Firestore simulado e 200 participantes. O teste do rascunho confirma que a tela restaura os dados locais e que nome/link bearer não entram no backup JSON.

Os testes unitários do adaptador REST usam um servidor HTTP falso. A integração real com Firestore Emulator é coberta separadamente pelo teste `server/test/firestore_emulator_integration_test.dart`; o build Web sozinho não demonstra login nem acesso ao Emulator.

### Roteiro manual — Auth/Firestore Emulator e Chrome

Use exclusivamente dados fictícios e o projeto demo abaixo. O prefixo `demo-` faz com que a suíte use emuladores em vez de recursos ativos; o Auth Emulator oferece fluxo OAuth simulado para o `signInWithPopup` Web. Consulte os passos oficiais de [instalação do Emulator Suite](https://firebase.google.com/docs/emulator-suite/install_and_configure), [Auth Emulator](https://firebase.google.com/docs/emulator-suite/connect_auth) e [testes de regras](https://firebase.google.com/docs/rules/unit-tests).

1. Instale Node.js 18+ (com npm), JDK 11+ e Firebase CLI (`npm install -g firebase-tools`). Confira com `node --version`, `npm --version`, `java -version` e `firebase --version`. Não execute `firebase login` nem selecione projeto real para este teste.
2. Terminal 1, raiz do repositório: `firebase emulators:start --only auth,firestore --project demo-amigosecreto`. Aguarde Auth `9099`, Firestore `8080` e UI `4000`. O Emulator carrega `firestore.rules` a partir de `firebase.json`.
3. Terminal 2, configure e inicie a API:

   ```powershell
   Set-Location C:\workspace\repositories\AmigoSecreto\server
   $env:GOOGLE_CLOUD_PROJECT = 'demo-amigosecreto'
   $env:FIREBASE_WEB_API_KEY = 'demo-key'
   $env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
   $env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
   $env:PUBLIC_BASE_URL = 'http://127.0.0.1:8081'
   $env:PORT = '8090'
   dart pub get
   dart analyze
   dart test
   dart run bin/server.dart
   ```

   No Emulator, o serviço envia o token administrativo local `owner`; o valor é usado só quando `FIRESTORE_EMULATOR_HOST` está definido. Em Cloud Run, o serviço usa a identidade anexada.
4. Terminal 3, raiz do repositório, inicie o app:

   ```powershell
   flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8081 --dart-define=FIREBASE_API_KEY=demo-key --dart-define=FIREBASE_APP_ID=demo-app --dart-define=FIREBASE_MESSAGING_SENDER_ID=demo-sender --dart-define=FIREBASE_AUTH_DOMAIN=demo-amigosecreto.firebaseapp.com --dart-define=FIREBASE_PROJECT_ID=demo-amigosecreto --dart-define=ONLINE_DRAW_API_BASE_URL=http://127.0.0.1:8090 --dart-define=USE_FIREBASE_EMULATORS=true
   ```

   Se o Flutter não conseguir iniciar o Chrome automaticamente, mantenha o comando `web-server` ativo e abra manualmente `http://127.0.0.1:8081` no Chrome. Use `127.0.0.1` também nos links gerados; `localhost` e `127.0.0.1` são origens diferentes no navegador e podem resolver para interfaces de rede distintas.

5. Na página “Evento online”, entre por Google usando o fluxo simulado pelo Auth Emulator. Se a janela mostrar **No Google.com accounts exist in the Auth Emulator**, selecione **Add new account** e crie uma identidade fictícia; não use sua conta nem senha Google real. Cadastre quatro pessoas fictícias (Ana Teste, Bruno Teste, Caio Teste, Dora Teste) e destinatários diretos fictícios. Em “Grupos e restrições”, crie grupos dos tipos Família, Casal e Outro, selecione integrantes e alterne a opção “Impedir sorteios dentro do grupo”. Aguarde “Rascunho salvo neste dispositivo”, recarregue a rota e confirme que participantes, grupos, tipos, membros e opções de restrição retornam.
6. Gere o sorteio. Confirme que a lista contém participante, destinatário e link, mas não mostra quem cada um tirou. Abra os links em uma janela anônima do Chrome, sem login: cada link deve revelar um resultado; recarregar o mesmo link deve manter esse resultado. Um token inventado deve mostrar link indisponível.
7. Volte à página do organizador, revogue um link com confirmação e reabra esse link anonimamente. Deve aparecer link indisponível. No botão WhatsApp, confirme que a mensagem tem apenas o link; feche a página do WhatsApp sem enviar.
8. Edite os dados ou a restrição do grupo após o sorteio. Confirme que a tela avisa que os links atuais ainda mostram o sorteio anterior. Escolha “Refazer sorteio e invalidar links atuais” e confirme. Os links da revisão anterior devem deixar de funcionar; os novos links devem revelar um único resultado cada. A nova lista exige encaminhar os links novamente.
9. Teste regra Firestore sem autenticação (PowerShell):

   ```powershell
   curl.exe -s -o NUL -w "%{http_code}`n" `
     "http://127.0.0.1:8080/v1/projects/demo-amigosecreto/databases/(default)/documents/events"
   ```

   Resultado esperado: `403`. A API do servidor é autorizada; o cliente anônimo deve ser bloqueado pelas regras fechadas.
10. Teste sorteio impossível em uma sessão nova: cadastre três pessoas fictícias e coloque as três no mesmo grupo com restrição ativa. O app deve explicar que as regras não permitem concluir o sorteio e não deve gerar links. Desative a restrição e confirme que é possível sortear.
11. Opcionalmente, consulte Emulator UI em `http://127.0.0.1:4000` para inspecionar documentos gravados. Use somente os nomes fictícios acima. Encerre os emuladores com `Ctrl+C` em Terminal 1.

### Testes automatizados contra o Firestore Emulator

Com Auth/Firestore Emulator ativo, execute em outro terminal:

```powershell
Set-Location C:\workspace\repositories\AmigoSecreto\server
$env:GOOGLE_CLOUD_PROJECT = 'demo-amigosecreto'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
dart test test/firestore_emulator_integration_test.dart --reporter expanded
```

O teste usa somente documentos fictícios e valida leitura/escrita anônimas negadas pelas regras, gravação e leitura de 200 resultados reais no Emulator, e concorrência na revisão: somente uma gravação com a mesma revisão vence e a revisão seguinte permanece utilizável. Sem `FIRESTORE_EMULATOR_HOST`, esses cenários são ignorados; a suíte Dart normal continua executando os testes unitários com HTTP simulado.

**Resultado manual informado pelo usuário em 2026-11-12:** fluxo de links/revelação/revogação; edição de grupos e estado de restrição; refazer sorteio com invalidação da revisão anterior; token inventado indisponível; sorteio impossível explica o problema e não gera links. Todos passaram no Chrome com dados fictícios. Nenhum envio WhatsApp foi realizado.

## 18. Fase 7 — cópia entre modos

Testes automatizados em `test/features/online_draw/data/online_draft_local_copy_repository_test.dart` validam que a cópia online → local preserva situação ativa/inativa, contato direto, grupo e restrição, cria destinatário compartilhado uma vez e não cria sorteio/atribuições. Entrada inválida deve falhar antes da gravação do evento.

Validação manual confirmada pelo usuário em 2026-11-12 no Chrome: criar dois eventos online, recarregar e reabrir cada um; copiar evento local (incluindo evento já sorteado) para online, cancelar e confirmar a prévia; conferir que uma nova cópia não altera links de outros eventos; copiar rascunho online para local e conferir que a origem/links permanecem disponíveis. Com a API parada, verificar mensagem de conexão acionável. Dados fictícios; nenhum WhatsApp foi enviado.

Validação manual confirmada pelo usuário em 2026-11-12: entrar com a identidade fictícia do Auth Emulator, tocar em **Sair** e confirmar que o formulário volta a oferecer login; entrar novamente, excluir um rascunho e conferir que os outros eventos permanecem. Em outro evento já sorteado, cancelar a confirmação e verificar que rascunho e links permanecem; confirmar exclusão e verificar que todos os links dele mostram link inválido e que os demais eventos continuam acessíveis.

**Retomada de sorteios:** crie os Emulators, a API e o Flutter em três terminais conforme os passos 2–4 acima. A API é necessária para o sorteio e precisa permanecer ativa na porta 8090; verifique com `Test-NetConnection 127.0.0.1 -Port 8090`. Para validar apenas cópias e gerenciar rascunhos, não é necessário confirmar/enviar sorteio. A URL da API e a URL pública dos links usam `127.0.0.1` para evitar resolução diferente de `localhost`.

**Gestão de vários eventos online:** na raiz do app, abra a lista “Eventos online”, crie dois eventos fictícios, aguarde o rascunho salvar, atualize a página e reabra cada um. Confirme que nomes, participantes, revisões e links correspondem ao evento selecionado; refazer/revogar um evento não deve alterar o outro. O teste deve usar a mesma origem do navegador (`http://127.0.0.1:8081`); trocar entre `localhost` e `127.0.0.1`, porta, perfil ou navegador acessa outro IndexedDB.

### 19.1 Login Google real (pendente de projeto Firebase)

Depois de criar/configurar um projeto real conforme `docs/DEPLOY.md`, valide primeiro em staging com dados fictícios:

1. Confirme que `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID` e `FIREBASE_AUTH_DOMAIN` pertencem ao mesmo app Web Firebase e que `USE_FIREBASE_EMULATORS=false`.
2. Inclua o domínio Hosting exato em Authentication → Settings → Authorized domains e habilite Google em Authentication → Sign-in method.
3. Abra o domínio HTTPS de staging e entre com uma conta Google de teste autorizada pelo projeto. Confirme que o popup retorna ao app e que a tela mostra o estado autenticado após recarregar.
4. Crie um evento fictício. Confirme que a API aceita o Firebase ID token para a conta proprietária; sem login, os endpoints administrativos devem responder 401 e a conta diferente deve receber 403.
5. Gere, revele e revogue links fictícios; confirme que a revelação pública não pede login, que cada link revela somente um resultado e que revogação/exclusão invalidam o link.
6. No Cloud Run, confirme que `FIREBASE_AUTH_EMULATOR_HOST` está ausente e que a conta de serviço dedicada tem somente os papéis necessários, incluindo `roles/datastore.user` no projeto Firestore.

**Estado:** não executado. O projeto Firebase real ainda não existe; a validação disponível até aqui usa Auth/Firestore Emulators.

## 19. Fase 8 — Docker e automação

Com Docker Desktop instalado e iniciado, na raiz do repositório:

```powershell
Copy-Item .env.example .env
docker compose config
docker compose up --build --detach
docker compose ps
docker compose --profile test run --build --rm flutter-tests
docker compose --profile test run --build --rm api-tests
curl.exe --fail http://127.0.0.1:8090/health
curl.exe --fail http://127.0.0.1:8081/
```

Fluxo esperado: Emulators ficam saudáveis antes da API; API responde `{ "status": "ok" }`; Web abre em `127.0.0.1:8081`, login usa Auth Emulator e sorteio persiste no Firestore Emulator. `api-tests` inclui os testes de integração reais do Emulator porque define `FIRESTORE_EMULATOR_HOST`. O UI está em `http://127.0.0.1:4000`. Use apenas `demo-amigosecreto` e participantes fictícios.

`docker compose down` preserva os volumes de dados/cache. `docker compose down --volumes` apaga os dados locais dos emuladores; use apenas quando decidir limpar o ambiente de teste. Não envie os arquivos de dados dos volumes ao Git.

CI: `.github/workflows/verify.yml` repete formatação, análise, testes, build e smoke test em PR/push; a validação `compose-verification` do GitHub Actions passou, incluindo Emulator, verificações Flutter/Dart e execução dos contêineres. O workflow `.github/workflows/deploy-staging.yml` é manual e requer a confirmação explícita `yes`. Após a configuração do Environment `staging`, Workload Identity Federation, contas de serviço e variáveis listadas em `docs/DEPLOY.md`, a execução autorizada #2 publicou API Cloud Run, Hosting e regras Firestore; o smoke test da API passou. Isso demonstra o deploy automatizado em staging, mas não substitui a validação manual do app real no navegador. Produção segue fora de escopo sem nova autorização.

**Tentativa de validação em 2026-11-12:** `docker --version`, `docker compose version` e `docker info` não puderam executar porque `docker` não está no PATH. Também verifiquei os caminhos padrão do Docker Desktop e do Podman; nenhum executável foi encontrado e `podman` não está disponível. Assim, `docker compose config`, os builds/serviços e os health checks seguem pendentes até que um Docker Engine esteja instalado e iniciado neste ambiente. O workflow cloud de staging continua manual e sem execução.

Como verificações independentes de contêiner, foram executados no host: `dart format --output=none --set-exit-if-changed .` (118 arquivos, nenhum alterado), `flutter analyze` (sem issues), `flutter test` (92 passaram), `flutter build web --release` (concluído), `dart analyze` em `server/` (sem issues) e `dart test` em `server/` (9 passaram; 3 testes do Firestore Emulator ignorados porque `FIRESTORE_EMULATOR_HOST` não foi definido). `java -version` também falha por Java ausente do PATH; os três testes de integração precisam do Emulator e permanecem pendentes. `git diff --check` terminou sem erros, com avisos de normalização LF/CRLF.

**Validação com Docker em 2026-11-13:** `docker compose config` passou; `docker compose up --build --detach` concluiu depois dos ajustes descritos em `docs/PROGRESSO.md`. Os três serviços ficaram `healthy`; API respondeu `{"status":"ok"}` e Web/Auth/Firestore responderam HTTP 200. `docker compose --profile test run --build --rm flutter-tests` passou: formatação (118 arquivos, 0 alterados), análise Flutter sem issues, 92 testes e build Web release (93,7 s). `docker compose --profile test run --build --rm api-tests` passou com 12 testes, incluindo os 3 testes de integração do Firestore Emulator (regras, lote de 200 resultados e concorrência). A conferência visual/interativa da Web no Chrome não foi concluída: a ferramenta de automação encerrou a ação porque não conseguiu identificar com confiança a URL atual do navegador. A resposta HTTP 200 confirma o serviço web, mas não substitui a conferência da interface/autenticação/persistência pelo navegador.

### Conferência do fluxo online após a reorganização

Validar no Chrome com Auth/Firestore Emulator e dados fictícios: (1) criar um evento e percorrer as abas **Evento**, **Participantes**, **Grupos** e **Revisão e links**, confirmando que cada área contém os controles correspondentes; (2) navegar entre abas sem perder dados, recarregar a página e confirmar restauração do rascunho; (3) verificar progresso/estado de salvamento e bloqueio de ações dependentes de login; (4) criar grupos com restrições e concluir um sorteio, confirmando que a revisão apresenta os grupos e a tela de links nunca mostra pares; (5) conferir layout em celular e desktop, teclado, foco, escala de texto e alvos de toque; (6) confirmar que lista, exclusão, revogação e cópia continuam funcionando e que nenhuma ação envia WhatsApp automaticamente.

**Estado em 2026-11-13:** as quatro áreas, o tema visual e os cartões de lista foram implementados. Formatação, `flutter analyze` e o build Flutter Web no Docker passaram; os serviços permaneceram saudáveis e os endpoints responderam. A navegação manual visual/interativa ainda precisa ser conferida no Chrome.

**Deploy staging em 2026-11-14:** workflow manual #2 concluído com sucesso após autorização explícita. Build Web, deploy Cloud Run, publicação de `firestore.rules` e release Firebase Hosting passaram. Hosting: `https://amigo-secreto-oculto.web.app`; API: `https://amigo-secreto-api-staging-833149683923.southamerica-east1.run.app`; smoke test da API retornou `{"status":"ok"}`. Falta conferir no Chrome o login Google do projeto de staging, persistência da sessão e o ciclo de evento fictício, incluindo revelação e revogação de link. Não usar dados reais nem enviar convites nesta validação.
