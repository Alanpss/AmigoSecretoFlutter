# ADR-007 — Conversão entre eventos locais e online

- **Status:** Aceito como decisão de produto; implementação futura
- **Data:** 2026-11-12
- **Decisores:** usuário e equipe do projeto
- **Relacionados:** `docs/CONTEXTO.md`, `docs/ARQUITETURA.md` (seção 12), `docs/PLANO_IMPLEMENTACAO.md`, ADR-006

## Contexto

O produto terá eventos locais, armazenados no dispositivo, e eventos online, administrados com autenticação e resultados privados no servidor. O usuário confirmou que a passagem entre modos deve seguir a recomendação de copiar o evento e preservar o original.

## Decisão

- A conversão cria uma cópia no modo de destino; não muda nem remove o evento de origem.
- A cópia leva cadastro do evento, participantes, destinatários/contatos e grupos com tipo, membros e estado da restrição, após revisão pelo organizador.
- Cada cópia recebe um novo sorteio no modo de destino. Atribuições existentes nunca são transferidas entre modos.
- Local → online exige confirmação explícita antes de enviar dados pessoais ao serviço; o sorteio online é calculado novamente no servidor.
- Online → local copia somente os dados de configuração disponíveis ao organizador, nunca solicita nem importa em lote os pares armazenados no servidor. O sorteio local é novo.
- Copiar um evento online não revoga seus links nem altera a origem; a revogação continua sendo uma ação explícita e separada.
- Se o rascunho online local não estiver disponível, a conversão online → local não pode presumir que os dados cadastrais possam ser recuperados do servidor.

## Consequências

A operação preserva a origem, e cada modo mantém sua própria persistência e ciclo de sorteio. Os resultados podem diferir entre origem e cópia. A cópia local → online transmite nomes e dados de contato ao servidor e deve pedir confirmação. Links do evento online de origem continuam ativos até o organizador revogá-los explicitamente.

A implementação ainda precisa definir revisão da cópia, tratamento de participantes/responsáveis duplicados, recuperação quando o rascunho online não está no mesmo dispositivo e UX para revisar/revogar links. Esse trabalho pertence a uma fase futura, a ser planejada e autorizada depois da Fase 6.

## Alternativa rejeitada

Transformar o próprio evento e reaproveitar os pares existentes foi rejeitado: misturaria persistências, destruiria o registro de origem e, no sentido local → online, levaria ao servidor atribuições que o organizador já pode conhecer.
