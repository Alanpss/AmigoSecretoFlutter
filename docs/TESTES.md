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
