# ADR-005 — Pessoa e participante

- **Status:** Aceito
- **Data:** 2026-11-03
- **Decisores:** projeto Amigo Secreto
- **Relacionados:** `docs/ARQUITETURA.md` (seção 6), `docs/REQUISITOS.md` (RN-01 a RN-03), `docs/PLANO_IMPLEMENTACAO.md` (Fase 2)

## Contexto

O organizador pode criar vários eventos ao longo do tempo e reaproveitar as mesmas pessoas. Uma pessoa pode:

- participar de vários eventos;
- participar no máximo uma vez do mesmo evento;
- ter nome, apelido e telefone;
- ser responsável por outra pessoa, participando ou não do evento;
- pertencer a vários grupos no mesmo evento;
- ficar inativa em um evento sem deixar de existir;
- ter o resultado sorteado, que pertence a ela, não ao responsável.

Há também requisitos de bloqueio: depois de um sorteio ativo, dados que afetam o pareamento não podem mudar sem invalidação. Telefones podem ser compartilhados; o vínculo de responsável não cria restrição; não pode haver cadeia de responsáveis.

## Alternativas consideradas

### A. Apenas `Participant`, com dados duplicados por evento

- Simples no início.
- Obriga a redigitar nome/telefone em cada evento.
- Duplica dados e dificulta correções.
- Não representa bem uma pessoa que é responsável em vários eventos.

### B. `Person` com dados específicos do evento embutidos

- Mistura identidade reutilizável com participação.
- Dificulta alterar o telefone de uma pessoa sem afetar eventos já sorteados.
- Cria ambiguidade sobre qual dado é global e qual é do evento.

### C. `Person` reutilizável + `Participant` por evento

- Separa identidade de participação.
- Permite reaproveitar dados e manter uma única participação por evento.
- Permite que uma pessoa seja responsável sem participar.
- Facilita bloquear edições quando a pessoa é referenciada por evento com sorteio ativo.
- Exige joins e regras de exclusão, mas o volume é pequeno.

### D. Entidade separada de “contato”

- Poderia separar contato de pessoa.
- Adiciona complexidade sem benefício claro no MVP.
- Telefone é um atributo da pessoa, e o responsável é uma pessoa.

## Decisão

Adotar **`Person` reutilizável** + **`Participant` vinculado a um evento**.

### `Person`

- `id` UUID estável;
- `name` obrigatório;
- `nickname` opcional;
- `phoneE164` opcional;
- timestamps de auditoria;
- pode existir sem participação (contato/responsável);
- edição bloqueada se a pessoa for participante ou responsável em evento com sorteio ativo.

### `Participant`

- `id` UUID;
- `eventId`;
- `personId`;
- `isActive`;
- `guardianPersonId` opcional;
- timestamps;
- único por `(eventId, personId)`;
- pertence a exatamente um evento.

### Responsável

- é uma referência direta a `Person`;
- pode participar ou não do evento;
- não pode ser responsável de si mesmo;
- o telefone é resolvido **diretamente** na pessoa responsável;
- nunca há cadeia (o responsável do responsável não é consultado);
- o vínculo não cria restrição de sorteio;
- o resultado pertence ao participante; o responsável é apenas destinatário;
- se o responsável não tiver telefone válido, a entrega fica “sem contato” e pode ser manual.

### Grupos e restrições

- `Group` pertence ao evento;
- contém participantes do mesmo evento;
- uma pessoa pode estar em vários grupos;
- a restrição é a união dos grupos com `restrictionEnabled == true`;
- o vínculo de responsável não entra no cálculo.

### Bloqueio e snapshots

- Após sorteio ativo, alterações em pessoa/participante/responsável/grupo que afetem o pareamento são bloqueadas.
- A invalidação preserva o sorteio antigo como histórico.
- Entregas guardam snapshots de dono, destinatário, telefone e mensagem, para registrar o que foi efetivamente mostrado/enviado.
- Mensagens pendentes podem ser atualizadas se o modelo mudar; abertas/confirmadas mantêm o conteúdo.

## Consequências

### Positivas

- Evita redigitar dados.
- Permite vários eventos com as mesmas pessoas.
- Separa identidade de participação e de resultado.
- Facilita responsáveis externos e participantes inativos.
- Permite bloquear edições de forma precisa.
- Mantém o sorteio independente de detalhes de contato.

### Negativas e riscos

- Mais entidades e joins; consultas precisam resolver pessoa + participação.
- Exclusão de pessoa exige verificar vínculos em todos os eventos.
- Editar uma pessoa pode afetar vários eventos; o bloqueio precisa indicar os eventos afetados.
- Snapshots podem divergir dos dados atuais; isso é intencional e deve ser explicado.
- A UI precisa deixar claro quem é o participante, quem é o responsável e quem recebe.

### Mitigações

- repositórios com transações e validação de referências;
- bloquear exclusão de pessoa vinculada;
- indicar eventos afetados ao tentar editar;
- exibir dono, destinatário e número antes de abrir o WhatsApp;
- testes específicos para responsável externo, participante, sem telefone, sem cadeia e telefone compartilhado.

## Regras de exclusão

- Remover um participante não apaga a pessoa reutilizável.
- Remover um participante o remove dos grupos do evento.
- Uma pessoa só pode ser excluída se não for participante nem responsável em nenhum evento.
- Caso contrário, os vínculos devem ser removidos primeiro.

## Quando reconsiderar

Reavaliar esta decisão se:

- for necessário histórico de alterações de nome/telefone por evento;
- houver múltiplos contatos por pessoa;
- for necessário representar famílias como entidades com dados próprios;
- o produto evoluir para multiusuário ou sincronização;
- a edição global de pessoa se mostrar confusa para o público.

Nesses casos, criar um novo ADR e revisar o modelo e as migrations.

## Referências

- `docs/ARQUITETURA.md`, seção 6.
- `docs/REQUISITOS.md`, RN-01, RN-02, RN-03 e RN-06.
- `docs/TESTES.md`, seções 5.2 e 6.5.
