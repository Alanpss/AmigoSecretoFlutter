# ADR-007 — Conversão entre eventos locais e online

- **Status:** Aceito; implementação da Fase 7 em andamento
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
- Cada conversão local → online cria um evento online independente; ela não substitui rascunhos nem links de outros eventos online.
- Online → local copia somente os dados de configuração disponíveis ao organizador, nunca solicita nem importa em lote os pares armazenados no servidor. O sorteio local é novo.
- Copiar um evento online não revoga seus links nem altera a origem; a revogação continua sendo uma ação explícita e separada.
- Se o rascunho online local não estiver disponível, a conversão online → local não pode presumir que os dados cadastrais possam ser recuperados do servidor.

## Consequências

A operação preserva a origem, e cada modo mantém sua própria persistência e ciclo de sorteio. Os resultados podem diferir entre origem e cópia. A cópia local → online transmite nomes e dados de contato ao servidor e deve pedir confirmação. Links do evento online de origem continuam ativos até o organizador revogá-los explicitamente.

As conversões têm prévia e confirmação. O evento local de destino recebe novas identidades; registros já existentes não são mesclados. Destinatários idênticos dentro da própria cópia podem compartilhar uma identidade. O modo online atual não armazena data de evento ou apelido separado, então esses campos não podem ser preservados na direção local → online; o nome apresentado é usado. O organizador pode manter múltiplos rascunhos/links online, mas só no mesmo navegador/origem; a conversão online → local só funciona quando o rascunho está disponível ali.

## Alternativa rejeitada

Transformar o próprio evento e reaproveitar os pares existentes foi rejeitado: misturaria persistências, destruiria o registro de origem e, no sentido local → online, levaria ao servidor atribuições que o organizador já pode conhecer.
