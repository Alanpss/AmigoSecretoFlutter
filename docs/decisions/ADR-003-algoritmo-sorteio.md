# ADR-003 — Algoritmo de sorteio

- **Status:** Aceito
- **Data:** 2026-11-03
- **Decisores:** projeto Amigo Secreto
- **Relacionados:** `docs/ARQUITETURA.md` (seção 7), `docs/REQUISITOS.md` (RN-07), `docs/TESTES.md` (seção 6), `docs/PLANO_IMPLEMENTACAO.md` (Fase 3)

## Contexto

O sorteio precisa produzir uma correspondência entre participantes ativos com estas regras:

- ninguém tira a si mesmo;
- cada ativo tira exatamente uma pessoa;
- cada ativo é sorteado exatamente uma vez;
- todas as restrições de grupos com restrição ativa são respeitadas;
- configurações impossíveis são detectadas e explicadas;
- nenhuma restrição é relaxada silenciosamente;
- o resultado é uniformemente distribuído entre as soluções válidas;
- vários ciclos são permitidos;
- o app deve lidar com até cerca de 200 participantes;
- o resultado deve ser reproduzível em testes e persistido antes do envio.

O problema é uma **correspondência perfeita em grafo bipartido** com arestas proibidas.

## Alternativas consideradas

### A. Embaralhar e testar até dar certo

- Simples de escrever.
- Pode ser exponencialmente lento em configurações restritas.
- Pode falhar sem explicar por que não há solução.
- Enviesa a distribuição e incentiva “tentar de novo” ignorando regras.
- Inaceitável para o requisito de diagnóstico e uniformidade.

### B. Backtracking puro

- Encontra uma solução, se existir.
- Pode ser exponencial no pior caso.
- A ordem de exploração enviesa a primeira solução.
- A detecção de impossibilidade pode ser cara e pouco explicativa.

### C. Matching máximo + amostragem por caminhos alternados

- Usa Hopcroft–Karp para verificar existência e obter um matching perfeito.
- Constrói a solução passo a passo, escolhendo uniformemente entre receivers que preservam a existência de solução.
- Garante validade e uniformidade entre soluções válidas.
- Complexidade adequada para 200 participantes.
- Permite diagnóstico claro de impossibilidade.

### D. Forçar um único ciclo

- Poderia ser desejável em alguns eventos, mas não é requisito.
- Reduz o conjunto de soluções e complica o algoritmo.
- Pode tornar impossível uma configuração que seria válida com vários ciclos.

## Decisão

Adotar **matching máximo (Hopcroft–Karp) + amostragem uniforme por caminhos alternados**, com estas etapas:

1. Montar o grafo bipartido com givers e receivers ativos.
2. Criar aresta quando `giver != receiver` e o par não é proibido.
3. Calcular o matching máximo.
4. Se o matching máximo for menor que o número de ativos, não há solução; gerar diagnóstico.
5. Obter um matching perfeito inicial.
6. Processar os givers em ordem fixa.
7. Para o giver atual, considerar `r0` (seu receiver no matching atual).
8. Construir o grafo alternado do conjunto restante.
9. Considerar viável todo receiver `r` que seja `r0` ou cuja aresta `(g, r)` seja permitida e cujo giver atualmente casado com `r` alcance `r0` no grafo alternado.
10. Escolher uniformemente entre os receivers viáveis.
11. Se `r != r0`, inverter o caminho alternado e casar `g` com `r`.
12. Remover `g` e `r` do conjunto e repetir.

A ordenação dos givers é fixa; a aleatoriedade vem de uma fonte injetável. O sorteio é Dart puro, sem widgets, banco ou WhatsApp.

## Justificativa da uniformidade

Com a ordem de givers fixa, cada matching perfeito corresponde a exatamente uma sequência de escolhas. Em cada passo, o conjunto de candidatos que preserva a existência de solução depende apenas do conjunto restante, não do matching escolhido. Escolher uniformemente entre esses candidatos atribui a mesma probabilidade a todas as soluções válidas.

A uniformidade é entre **soluções válidas**, não entre formatos de ciclos, nem entre “qualidades” subjetivas.

## Complexidade

- Matching inicial: `O(E√V)`.
- Cada passo constrói grafo alternado e faz busca: `O(E)`.
- Total: `O(nE)`.
- Para 200 participantes, o custo é adequado; o teste de desempenho registra o tempo real.

## Diagnóstico de impossibilidade

Quando não há solução:

- identificar participantes sem nenhuma opção;
- identificar grupo restrito com mais da metade dos ativos;
- testar, sem salvar, a desativação individual de cada grupo restrito para indicar quais ajustes tornariam o sorteio possível;
- usar mensagem genérica quando a causa for uma combinação de restrições.

As mensagens são explicativas, não uma prova minimal de impossibilidade. O app nunca relaxa uma restrição para “fazer o sorteio funcionar”.

## Consequências

### Positivas

- Garante existência ou explica a impossibilidade.
- Respeita todas as restrições.
- Distribuição uniforme entre soluções válidas.
- Sem tentativas aleatórias indefinidas.
- Testável com RNG determinístico.
- Permite vários ciclos, como exigido.

### Negativas e limitações

- Não evita repetição de pares de eventos anteriores.
- Não pondera gênero, idade, afinidade ou cotas.
- Não garante um ciclo único.
- A implementação é mais complexa que um embaralhamento simples.
- A explicação de impossibilidade é heurística, não uma prova minimal.
- O resultado depende da ordem fixa dos givers para a construção, embora a distribuição final seja uniforme.

## Persistência

- O candidato é calculado fora da transação.
- A confirmação grava em uma única transação: draw, assignments, deliveries e `activeDrawId`.
- A transação verifica `pairingRevision`; se os dados mudaram, aborta.
- O draw registra `algorithmVersion` e `pairingRevision`.
- Falha não deixa estado parcial; o evento continua em rascunho.
- Reabrir o app não gera outro resultado.

## Testes

- cenários impossíveis: 0/1 ativo, todos no mesmo grupo, grupo maior que a metade;
- múltiplos grupos e sobreposições;
- restrição desativada;
- participante isolado;
- invariantes de saída;
- uniformidade por exaustão (n ≤ 6) e amostragem com semente fixa;
- 200 participantes;
- persistência idempotente, conflito de revisão e falha atômica;
- bloqueio de edição e invalidação.

Detalhes em `docs/TESTES.md`, seção 6.

## Quando reconsiderar

Reavaliar esta decisão se:

- for necessário exigir um ciclo único;
- forem necessárias cotas, pesos ou proibições por par;
- o número de participantes crescer muito além de 200;
- for necessário evitar pares de eventos anteriores;
- a uniformidade entre soluções deixar de ser requisito.

Nesses casos, criar um novo ADR e revisar os critérios de aceite.

## Referências

- `docs/ARQUITETURA.md`, seção 7.
- `docs/REQUISITOS.md`, RN-07 e CA-05.
- `docs/TESTES.md`, seção 6.
