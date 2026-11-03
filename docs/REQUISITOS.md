# Requisitos e regras de negócio

Este documento é a fonte de verdade para o comportamento funcional. Os critérios de aceite são observáveis e devem ser demonstrados na fase correspondente.

Convenções: **DEVE** é obrigatório; **NÃO DEVE** é proibido; **PODE** é opcional no MVP.

## 1. Glossário

| Termo | Definição |
| --- | --- |
| Pessoa (`Person`) | Identidade reutilizável: nome, apelido e telefone. Pode existir sem participar de um evento. |
| Participante (`Participant`) | Vínculo de uma pessoa com um evento: situação ativa, responsável e grupos. |
| Responsável | Pessoa que recebe a mensagem no lugar do participante. Pode ou não participar do sorteio. |
| Grupo | Família, casal ou outro agrupamento de participantes do mesmo evento. |
| Restrição ativa | Grupo cujos integrantes não podem tirar uns aos outros. |
| Sorteio ativo | Resultado confirmado e persistido, ainda não invalidado. |
| Entrega (`Delivery`) | Registro da mensagem de um participante para um destinatário resolvido. |
| Destinatário resolvido | Participante (no próprio número) ou responsável (no número do responsável), sempre com telefone direto. |

## 2. Requisitos funcionais

### 2.1 Eventos

- **RF-EVT-01:** o organizador DEVE poder criar um evento com nome obrigatório e data opcional.
- **RF-EVT-02:** o aplicativo DEVE listar eventos com nome, data, quantidade de participantes ativos e situação.
- **RF-EVT-03:** o organizador DEVE poder abrir, editar e excluir um evento, com confirmação.
- **RF-EVT-04:** o evento DEVE ter um modelo de mensagem e um país padrão para telefones.
- **RF-EVT-05:** o evento DEVE manter a referência ao sorteio ativo, se existir.
- **RF-EVT-06:** ao reabrir o aplicativo, o evento e seu sorteio ativo DEVEM ser restaurados sem gerar outro resultado.
- **RF-EVT-07:** excluir um evento com mensagens confirmadas DEVE destacar o impacto e exigir confirmação explícita.

### 2.2 Pessoas e participantes

- **RF-PES-01:** toda pessoa DEVE ter identificador estável (UUID), nome obrigatório, apelido opcional e telefone opcional.
- **RF-PES-02:** o telefone, quando informado, DEVE ser validado e armazenado em formato E.164 com `+`.
- **RF-PES-03:** o aplicativo DEVE permitir reaproveitar uma pessoa existente em outro evento.
- **RF-PES-04:** uma pessoa NÃO PODE ter duas participações no mesmo evento.
- **RF-PAR-01:** cada participante DEVE ter situação ativa ou inativa, ativa por padrão.
- **RF-PAR-02:** o cadastro DEVE acontecer na mesma tela, com nome, apelido, telefone, responsável e grupos.
- **RF-PAR-03:** o organizador DEVE poder pesquisar, filtrar, editar e remover participantes.
- **RF-PAR-04:** remover um participante NÃO DEVE excluir automaticamente a pessoa do cadastro reutilizável.
- **RF-PAR-05:** nomes ou telefones repetidos DEVEM gerar aviso, sem impedir o cadastro.
- **RF-PAR-06:** telefones compartilhados entre pessoas DEVEM ser permitidos.
- **RF-PAR-07:** o apelido DEVE ser usado nas mensagens quando preenchido; o nome completo DEVE permanecer visível para identificação.
- **RF-PAR-08:** o organizador DEVE poder criar uma família ou casal sem perder os dados já preenchidos no formulário do participante.

### 2.3 Responsáveis e entrega

- **RF-RESP-01:** um participante PODE receber no próprio número, no número de um responsável ou por entrega manual.
- **RF-RESP-02:** o responsável PODE ser participante ou apenas um contato sem participação no evento.
- **RF-RESP-03:** o responsável DEVE ser uma pessoa do cadastro; seu telefone é resolvido diretamente nela.
- **RF-RESP-04:** NÃO DEVE existir cadeia de responsáveis. Se A é responsável de B e B é responsável de C, a mensagem de C usa o telefone de B, nunca o de A.
- **RF-RESP-05:** um participante NÃO PODE ser responsável de si mesmo.
- **RF-RESP-06:** o vínculo com responsável NÃO DEVE criar restrição de sorteio.
- **RF-RESP-07:** o resultado pertence ao participante; o responsável é apenas destinatário.
- **RF-RESP-08:** antes de abrir o WhatsApp, o app DEVE mostrar claramente o dono do resultado, o destinatário e o número usado.
- **RF-RESP-09:** se não houver telefone próprio nem responsável com telefone válido, o app DEVE sinalizar “sem contato” e permitir entrega manual identificada.
- **RF-RESP-10:** a possibilidade de participar do sorteio NÃO DEVE depender de ter telefone ou responsável válido.
- **RF-RESP-11:** se o responsável não tiver telefone válido, o app NÃO DEVE usar o responsável do responsável como fallback.

### 2.4 Grupos e restrições

- **RF-GRP-01:** o organizador DEVE poder criar grupos com nome e tipo: família, casal ou outro.
- **RF-GRP-02:** uma pessoa PODE pertencer a vários grupos no mesmo evento.
- **RF-GRP-03:** cada grupo DEVE ter uma opção de restrição ativa/inativa.
- **RF-GRP-04:** se duas pessoas compartilharem qualquer grupo com restrição ativa, elas NÃO PODEM tirar uma à outra.
- **RF-GRP-05:** desabilitar a restrição de um grupo remove apenas as proibições daquele grupo; as dos demais continuam valendo.
- **RF-GRP-06:** o nome do grupo DEVE ser único no evento, sem diferenciar maiúsculas/minúsculas.
- **RF-GRP-07:** grupos só PODEM conter participantes do próprio evento.
- **RF-GRP-08:** remover um participante DEVE removê-lo dos grupos do evento.
- **RF-GRP-09:** restrições específicas entre duas pessoas estão fora do MVP e não devem ser simuladas por grupos temporários sem explicação.

### 2.5 Sorteio

- **RF-SOR-01:** somente participantes ativos participam do sorteio.
- **RF-SOR-02:** ninguém PODE tirar a si mesmo.
- **RF-SOR-03:** cada participante ativo DEVE tirar exatamente uma pessoa.
- **RF-SOR-04:** cada participante ativo DEVE ser sorteado exatamente uma vez.
- **RF-SOR-05:** todas as restrições de grupos com restrição ativa DEVEM ser respeitadas.
- **RF-SOR-06:** o app DEVE detectar configurações sem solução e explicar o impedimento em linguagem simples.
- **RF-SOR-07:** nenhuma restrição PODE ser relaxada silenciosamente. O app NÃO DEVE “tentar de novo até dar certo” ignorando regras.
- **RF-SOR-08:** a verificação de existência de solução DEVE ser completa, não apenas uma checagem preliminar.
- **RF-SOR-09:** o resultado DEVE ser gerado com aleatoriedade adequada e distribuído uniformemente entre as soluções válidas.
- **RF-SOR-10:** vários ciclos separados são permitidos; não é obrigatório formar um único ciclo.
- **RF-SOR-11:** antes de confirmar, o organizador DEVE ver um resumo do que será feito e confirmar explicitamente.
- **RF-SOR-12:** o sorteio confirmado DEVE ser salvo de forma consistente antes de qualquer mensagem ser aberta.
- **RF-SOR-13:** reabrir o aplicativo NÃO PODE gerar outro resultado para o mesmo sorteio ativo.
- **RF-SOR-14:** o app DEVE registrar a versão do algoritmo e a revisão dos dados de entrada usada no sorteio.
- **RF-SOR-15:** se a gravação falhar, o evento DEVE continuar em rascunho e o organizador DEVE receber uma mensagem clara; nenhuma entrega parcial pode existir.
- **RF-SOR-16:** depois do sorteio, alterações em participantes, pessoas, responsáveis ou grupos DEVEM ser bloqueadas até uma invalidação explícita.
- **RF-SOR-17:** a invalidação DEVE exigir confirmação e, se houver mensagens abertas ou confirmadas, destacar quantas e o impacto.
- **RF-SOR-18:** o sorteio invalidado DEVE ser preservado como histórico; um novo sorteio cria novos registros de entrega.
- **RF-SOR-19:** editar o modelo de mensagem depois do sorteio PODE ser permitido, mas só deve atualizar mensagens ainda pendentes; mensagens abertas ou confirmadas mantêm o conteúdo enviado.
- **RF-SOR-20:** resultados DEVEM ficar ocultos por padrão, com revelação individual.

### 2.6 WhatsApp e acompanhamento

- **RF-ENV-01:** o app DEVE abrir a conversa individual do destinatário com a mensagem pronta usando um link oficial `https://wa.me/<numero>?text=<mensagem>`.
- **RF-ENV-02:** o número DEVE ser normalizado para o formato internacional, sem `+` no link, e a mensagem DEVE ser codificada corretamente (inclusive acentos, emojis e quebras de linha).
- **RF-ENV-03:** o app DEVE usar a conta já conectada no dispositivo; NÃO DEVE solicitar credenciais do WhatsApp.
- **RF-ENV-04:** o usuário DEVE confirmar o envio dentro do WhatsApp; o app NÃO PODE enviar automaticamente.
- **RF-ENV-05:** NÃO DEVE ser usada automação não oficial do WhatsApp Web.
- **RF-ENV-06:** abrir a conversa NÃO DEVE ser tratado como envio ou entrega.
- **RF-ENV-07:** a fila DEVE permitir abrir WhatsApp, copiar mensagem, marcar manualmente como enviado, reabrir mensagem e filtrar pendentes.
- **RF-ENV-08:** os estados DEVEM ser: `Pendente`, `Conversa aberta` e `Envio confirmado pelo organizador`.
- **RF-ENV-09:** o app NÃO DEVE exibir “entregue” ou “lido” sem comprovação disponível.
- **RF-ENV-10:** se várias pessoas usarem o mesmo responsável, as mensagens DEVEM permanecer separadas por participante e identificadas pelo nome de quem tirou o quê.
- **RF-ENV-11:** cada cartão DEVE mostrar dono do resultado, destinatário e número antes de abrir o WhatsApp.
- **RF-ENV-12:** entregas sem contato válido DEVEM ser identificadas e poder ser confirmadas como entrega manual, com registro do método.
- **RF-ENV-13:** o modelo de mensagem DEVE aceitar apenas as variáveis `{evento}`, `{participante}`, `{apelido}`, `{sorteado}` e `{responsavel}`.
- **RF-ENV-14:** variável desconhecida DEVE gerar erro de validação, não substituição silenciosa.
- **RF-ENV-15:** o app DEVE oferecer uma prévia da mensagem com dados fictícios na edição do modelo.
- **RF-ENV-16:** falha ao abrir o WhatsApp DEVE manter a entrega pendente e oferecer copiar a mensagem.

### 2.7 Backup e restauração

- **RF-BKP-01:** o organizador DEVE poder exportar todos os dados em um arquivo JSON versionado.
- **RF-BKP-02:** o organizador DEVE poder importar um backup válido, com prévia de quantidades e confirmação.
- **RF-BKP-03:** a importação DEVE validar versão, estrutura e referências antes de substituir os dados.
- **RF-BKP-04:** a importação DEVE ser atômica: ou substitui tudo, ou não altera nada.
- **RF-BKP-05:** o app DEVE avisar que o backup contém telefones e resultados e é sensível.
- **RF-BKP-06:** o app NÃO DEVE incluir dados em logs, nomes de arquivo temporário ou mensagens de erro.
- **RF-BKP-07:** um backup inválido ou incompatível DEVE ser rejeitado com explicação e sem perda dos dados atuais.
- **RF-BKP-08:** após importar, o app DEVE reabrir os dados importados e respeitar o sorteio ativo, se existir.

### 2.8 Experiência e acessibilidade

- **RF-UX-01:** a interface DEVE estar em português do Brasil.
- **RF-UX-02:** o fluxo principal DEVE ser: criar evento → adicionar participantes e contatos → organizar grupos → revisar pendências → sortear e confirmar → enviar.
- **RF-UX-03:** o layout DEVE funcionar em celular e computador, com áreas de toque de pelo menos 48×48.
- **RF-UX-04:** o app DEVE ter estados vazios com orientação e ação principal.
- **RF-UX-05:** ações destrutivas ou irreversíveis DEVEM pedir confirmação.
- **RF-UX-06:** o app DEVE retomar a organização e os envios após fechar e reabrir.
- **RF-UX-07:** o app DEVE suportar escala de texto, contraste adequado e navegação por teclado na Web.
- **RF-UX-08:** o app NÃO DEVE depender apenas de cor para indicar estado.
- **RF-UX-09:** resultados DEVEM ficar ocultos por padrão e ser revelados individualmente.
- **RF-UX-10:** o app DEVE deixar explícito que o organizador pode ver todos os resultados e que responsáveis conhecem os resultados recebidos.

## 3. Regras de negócio detalhadas

### RN-01 — Identidade e participação

- Pessoa tem UUID estável; participante tem UUID estável por evento.
- Uma pessoa pode participar de vários eventos, mas no máximo uma vez em cada evento.
- Pessoa sem participação pode existir como contato/responsável.
- Excluir uma pessoa só é permitido se ela não for participante nem responsável em nenhum evento; caso contrário, o vínculo deve ser removido primeiro.

### RN-02 — Dados obrigatórios e duplicidade

- Nome: obrigatório, sem espaços nas pontas, entre 1 e 120 caracteres.
- Apelido: opcional, entre 1 e 40 caracteres quando preenchido.
- Telefone: opcional; se preenchido, deve ser válido em E.164.
- Nome repetido: aviso “Já existe uma pessoa com nome parecido”; não bloqueia.
- Telefone repetido: aviso “Este telefone já é usado por outra pessoa; isso é permitido quando várias pessoas recebem pelo mesmo responsável”; não bloqueia.
- Participante repetido no mesmo evento: bloqueia, pois cada pessoa só pode ter uma participação por evento.

### RN-03 — Resolução do destinatário

Ordem, sem cadeia:

1. Se o participante tem responsável, usar o telefone da pessoa responsável.
2. Caso contrário, usar o telefone do próprio participante.
3. Se o telefone resolvido estiver ausente ou inválido, a entrega fica “sem contato”.

O telefone do responsável é sempre o telefone direto da pessoa responsável. Nunca seguir o campo “responsável” dessa pessoa. Se o responsável for participante, seu próprio resultado continua separado.

### RN-04 — Restrições

- Cada grupo tem `restrictionEnabled` (padrão: ativo).
- O par (A, B) é proibido se A ≠ B e existe ao menos um grupo com restrição ativa que contém ambos.
- A proibição é simétrica.
- O vínculo de responsável não entra no cálculo.
- Desativar a restrição de um grupo não remove os membros nem o grupo.

### RN-05 — Estados do evento e do sorteio

**Evento:**

- `Rascunho`: sem sorteio ativo; participantes e grupos editáveis.
- `Sorteado`: com sorteio ativo; participantes, pessoas, responsáveis e grupos bloqueados para edição.
- `Enviando` (derivado): há pelo menos uma entrega aberta ou confirmada e nem todas estão confirmadas.
- `Envios concluídos` (derivado): todas as entregas estão confirmadas.

**Sorteio:**

- `Ativo`: resultado persistido e disponível.
- `Invalidado`: histórico preservado; não pode ser usado para envio; não é reativado.

**Entrega:**

- `Pendente`: ainda não foi aberta nem confirmada.
- `Conversa aberta`: o link foi aberto com sucesso; não prova envio.
- `Envio confirmado`: o organizador marcou manualmente como enviado; método `whatsapp` ou `manual`.

### RN-06 — Bloqueio e invalidação

Depois de um sorteio ativo:

- adicionar, remover ou alterar participante;
- alterar situação ativa/inativa;
- alterar nome, apelido ou telefone de pessoa que participa ou é responsável no evento;
- criar, renomear, excluir ou alterar membros de grupo;
- ativar/desativar restrição de grupo;

ficam bloqueados até que o organizador invalide o sorteio.

Editar o modelo de mensagem é permitido. Ao salvar, o app deve perguntar se deseja atualizar as mensagens pendentes; as que já estão abertas ou confirmadas mantêm o conteúdo anterior.

Se a pessoa editada participar de outro evento com sorteio ativo, a edição também é bloqueada, com indicação dos eventos afetados. Isso evita alterar contatos de um sorteio já realizado por outro caminho.

A invalidação:

- exige confirmação;
- informa quantas mensagens estão abertas e confirmadas;
- preserva o sorteio antigo como `Invalidado`;
- mantém o histórico de entregas antigas;
- retorna o evento para `Rascunho`;
- permite um novo sorteio, que cria novas entregas.

### RN-07 — Sorteio: validade e aleatoriedade

- O sorteio é uma correspondência perfeita em um grafo bipartido: givers à esquerda, receivers à direita, aresta permitida quando não é auto-sorteio e não há restrição.
- A existência é verificada por matching máximo. Se o matching máximo for menor que o número de ativos, não há solução.
- A geração escolhe, para cada giver em ordem fixa, um receiver ainda livre que preserve a existência de uma correspondência perfeita no restante. A escolha é uniforme entre os candidatos viáveis.
- Essa construção é uniforme entre todas as soluções válidas. Não há garantia de uniformidade entre formatos de ciclos ou outras métricas de “qualidade”.
- A aleatoriedade usa fonte segura; testes podem injetar um gerador determinístico.
- O resultado pode formar vários ciclos. Não há exigência de ciclo único.
- O sorteio não considera histórico de eventos anteriores, gênero, idade ou afinidade.

### RN-08 — Persistência do sorteio

- O candidato é calculado fora da transação de gravação.
- Ao confirmar, o app grava em uma única transação: sorteio, atribuições, entregas e atualização do evento.
- A gravação é idempotente: repetir a mesma confirmação não pode gerar outro resultado.
- A transação verifica a revisão de pareamento do evento; se os dados mudaram desde a revisão, aborta e pede nova revisão.
- O sorteio armazena a versão do algoritmo e a revisão de entrada.
- Se a gravação falhar, nada é parcialmente salvo e o evento continua em rascunho.

### RN-09 — Mensagem

Variáveis permitidas:

| Variável | Valor |
| --- | --- |
| `{evento}` | Nome do evento. |
| `{participante}` | Nome completo do participante dono do resultado. |
| `{apelido}` | Apelido do participante dono do resultado; se vazio, nome completo. |
| `{sorteado}` | Apelido da pessoa sorteada; se vazio, nome completo. |
| `{responsavel}` | Nome do destinatário: responsável, se houver; senão, o próprio participante. |

Regras:

- O modelo pode ter até 2.000 caracteres.
- Variáveis desconhecidas ou chaves não fechadas geram erro.
- A substituição não deve reprocessar o texto substituído.
- Nomes com chaves, acentos, emojis ou quebras de linha devem ser tratados como texto.
- A mensagem final é codificada na URL; o texto exibido no app permanece legível.
- Mensagens de um mesmo responsável são separadas e identificadas pelo participante.

Exemplo fictício:

```text
Olá, {responsavel}! 🎁
Aqui é o Amigo Secreto de {evento}.
O resultado de {participante} é: {sorteado}.
Guarde este segredo! 🤫
```

### RN-10 — Telefones

- Entrada aceita: `(11) 90000-0001`, `+55 11 90000-0001`, `+1 202 555 0100`.
- Sem `+`, interpretar como Brasil (premissa do MVP).
- Armazenar `+<país><número>` apenas com dígitos após o `+`.
- Validar com biblioteca de parsing; não exigir que seja celular, para não rejeitar números válidos de WhatsApp.
- Para o link, remover o `+` e qualquer caractere não numérico.
- Telefone inválido bloqueia apenas o campo; o participante pode ser salvo sem telefone e receber manualmente.

### RN-11 — Backup

- Formato JSON com `schemaVersion`, identificação do app, data de exportação e dados.
- Inclui pessoas, eventos, participantes, grupos, sorteios, entregas e configurações.
- É sensível: contém telefones e resultados.
- Importação substitui toda a base local; não faz merge.
- Antes de importar, validar tudo e mostrar um resumo; se qualquer referência estiver quebrada, rejeitar.
- O app deve sugerir exportar um backup antes de importar outro.
- O arquivo não deve ser commitado nem enviado pelo WhatsApp.

### RN-12 — Acessibilidade e responsividade

- Contraste mínimo AA para texto e componentes essenciais.
- Áreas de toque de pelo menos 48×48.
- Rótulos semânticos em botões e campos; ordem de foco lógica.
- Estados não dependem só de cor: usar texto e ícone.
- Suportar escala de texto sem cortar ações essenciais.
- Layout compacto em telas estreitas e confortável em desktop.

## 4. Critérios de aceite

### CA-01 — Eventos e retomada

- [ ] Criar evento com nome e data opcional; aparece na lista com situação “Rascunho”.
- [ ] Fechar e reabrir o app mantém o evento e seus dados.
- [ ] Excluir evento pede confirmação; com mensagens confirmadas, mostra o impacto antes.
- [ ] Abrir um evento com sorteio ativo mostra o resultado salvo, não um novo sorteio.

### CA-02 — Pessoas e participantes

- [ ] Cadastrar participante com nome, apelido, telefone, responsável e grupos na mesma tela.
- [ ] Criar uma família ou casal dentro do formulário sem perder nome, apelido ou telefone digitados.
- [ ] Pesquisar por nome, apelido ou telefone e filtrar ativos/inativos.
- [ ] Nome repetido gera aviso e permite salvar.
- [ ] Telefone repetido gera aviso, permite salvar e mantém as mensagens separadas.
- [ ] Editar e remover participante funciona; remover não apaga a pessoa reutilizável.
- [ ] Apelido aparece na mensagem; nome completo aparece na identificação da interface.

### CA-03 — Responsáveis

- [ ] Participante com telefone próprio recebe no próprio número.
- [ ] Participante com responsável recebe no número do responsável.
- [ ] Responsável que não participa do evento pode ser cadastrado e recebe a mensagem.
- [ ] Responsável que participa do sorteio recebe a mensagem do outro participante no próprio número, sem cadeia.
- [ ] Responsável sem telefone válido é sinalizado; o app não tenta outro responsável.
- [ ] Participante sem contato válido continua no sorteio e aparece como entrega manual.
- [ ] O cartão mostra dono, destinatário e número antes de abrir o WhatsApp.
- [ ] Vínculo de responsável não altera as restrições.

### CA-04 — Grupos e restrições

- [ ] Criar família, casal e outro grupo; editar nome, tipo, membros e restrição.
- [ ] Pessoa em família e casal respeita a união das restrições.
- [ ] Desativar a restrição de um grupo permite o par daquele grupo, mas mantém as demais.
- [ ] Grupo com restrição que torna o sorteio impossível é detectado com explicação.
- [ ] Nome de grupo duplicado é bloqueado com mensagem clara.

### CA-05 — Sorteio

- [ ] Com 0 ou 1 ativo, o sorteio é bloqueado com explicação.
- [ ] Todos no mesmo grupo restrito: impossível, sem relaxar regras.
- [ ] Grupo restrito maior que a metade dos ativos: impossível, com sugestão de ajuste.
- [ ] Configuração válida gera atribuições em que ninguém tira a si mesmo, todos tiram uma vez e todos são sorteados uma vez.
- [ ] Nenhum par de grupo restrito aparece no resultado.
- [ ] Vários grupos e sobreposições são respeitados.
- [ ] O resultado pode ter vários ciclos; isso é aceito.
- [ ] A distribuição entre soluções válidas é uniforme (teste estatístico com tolerância).
- [ ] O sorteio confirmado é salvo antes de qualquer abertura de WhatsApp.
- [ ] Falha de gravação não deixa sorteio parcial.
- [ ] Reabrir o app mantém exatamente o mesmo resultado.
- [ ] Resultados ficam ocultos até revelação individual.

### CA-06 — Alterações e invalidação

- [ ] Após o sorteio, adicionar/remover/editar participante, pessoa, responsável ou grupo é bloqueado.
- [ ] A interface explica que é preciso invalidar o sorteio.
- [ ] A invalidação pede confirmação e mostra quantas mensagens foram abertas/confirmadas.
- [ ] Invalidar preserva o histórico e permite novo sorteio.
- [ ] Depois de uma mensagem confirmada, a invalidação destaca o impacto e não apaga o registro antigo.
- [ ] Editar o modelo de mensagem não altera mensagens abertas/confirmadas; mensagens pendentes podem ser atualizadas com ação explícita.

### CA-07 — WhatsApp e fila

- [ ] O link abre a conversa do destinatário correto com a mensagem pronta.
- [ ] Números são normalizados; acentos, emojis e quebras de linha chegam corretamente.
- [ ] Abrir a conversa muda o estado para “Conversa aberta”, nunca para “Envio confirmado”.
- [ ] “Marcar como enviado” exige confirmação e registra o método.
- [ ] “Copiar mensagem” não altera o estado.
- [ ] “Reabrir” funciona sem apagar a confirmação existente.
- [ ] Filtro de pendentes mostra apenas entregas pendentes.
- [ ] Várias pessoas com o mesmo responsável geram cartões e mensagens separados.
- [ ] Entrega sem contato pode ser confirmada como manual, com identificação.
- [ ] O app não exibe “entregue” ou “lido”.

### CA-08 — Backup

- [ ] Exportar gera JSON com versão e todos os dados.
- [ ] Importar um backup válido mostra prévia e substitui os dados após confirmação.
- [ ] Backup inválido é rejeitado sem alterar a base atual.
- [ ] O app avisa que o arquivo contém dados sensíveis.
- [ ] Após importar, sorteio ativo e entregas são restaurados.

### CA-09 — Experiência

- [ ] Fluxo completo funciona em tela de 360×800 e em desktop.
- [ ] Estados vazios orientam a próxima ação.
- [ ] Ações destrutivas pedem confirmação.
- [ ] Navegação por teclado e leitor de tela funcionam nos controles principais.
- [ ] Textos estão em português do Brasil e não usam jargão técnico.
- [ ] O app retoma a organização e os envios após fechar e reabrir.

## 5. Casos limite e comportamento esperado

| Caso | Comportamento |
| --- | --- |
| 0 ou 1 participante ativo | Bloquear sorteio; explicar que são necessários pelo menos 2. |
| Todos no mesmo grupo restrito | Bloquear; sugerir desativar a restrição, dividir o grupo ou adicionar pessoas de fora. |
| Grupo restrito com mais da metade dos ativos | Bloquear; explicar que não há receptores suficientes fora do grupo. |
| Participante sem nenhuma opção válida | Bloquear; indicar o participante e os grupos que o isolam. |
| Pessoa em família e casal | União das restrições; se qualquer grupo restrito contiver o par, proibir. |
| Restrição desativada | Grupo continua existindo, mas não proíbe pares. |
| Responsável externo | Recebe no telefone próprio; não entra no sorteio. |
| Responsável participante | Recebe no telefone próprio; seu próprio resultado é separado. |
| Responsável sem telefone | Entrega fica sem contato; não seguir cadeia. |
| Participante sem telefone e sem responsável | Participa e é sorteado; entrega manual. |
| Telefone compartilhado | Permitido; mensagens separadas e identificadas. |
| Nome repetido | Aviso; permitido. |
| Participante inativo | Não sorteia nem é sorteado; pode ser responsável. |
| Edição após sorteio | Bloqueada até invalidação explícita. |
| Edição de pessoa usada em evento sorteado | Bloqueada; indicar os eventos afetados. |
| Modelo alterado após abertura | Mensagem aberta/confirmada permanece; pendentes podem ser atualizadas. |
| Falha ao salvar sorteio | Nada parcial; evento continua em rascunho. |
| Falha ao abrir WhatsApp | Entrega continua pendente; oferecer copiar. |
| App fechado durante envio | Estado persistido; retomar na fila. |
| Backup inválido | Rejeitar; dados atuais intactos. |
| Armazenamento do navegador limpo | Dados perdidos; só backup recupera. |

## 6. Fora do escopo e melhorias futuras

- Proibições específicas entre pares.
- Exigir um único ciclo.
- Evitar pares repetidos de anos anteriores.
- Sorteio ponderado ou com cotas.
- Envio automático e confirmação de entrega.
- Sincronização em nuvem e multiusuário.
- iOS e publicação em lojas.
- Backup criptografado por senha.
- Arquivamento de eventos, duplicação de evento e modelos por participante.
- Exportação em CSV/PDF para impressão.
- Modo “organizador não vê os pares”.

Essas melhorias só devem ser implementadas após o MVP e com requisitos próprios.
