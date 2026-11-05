# Decisões arquiteturais (ADRs)

Registros das decisões técnicas relevantes. Um ADR explica **contexto, alternativas, decisão e consequências**; não substitui `docs/ARQUITETURA.md`, que descreve a estrutura vigente.

## Índice

| ADR | Título | Status | Data | Resumo |
| --- | --- | --- | --- | --- |
| [ADR-001](ADR-001-plataforma-inicial.md) | Plataforma inicial: Flutter Web | Aceito | 2026-11-03 | Web/PWA primeiro; Android depois, com o mesmo código |
| [ADR-002](ADR-002-persistencia-local.md) | Persistência local com Sembast | Aceito | 2026-11-03 | Sembast/Sembast Web, transações e backup JSON |
| [ADR-003](ADR-003-algoritmo-sorteio.md) | Algoritmo de sorteio | Aceito | 2026-11-03 | Matching máximo + amostragem uniforme por caminhos alternados |
| [ADR-004](ADR-004-envio-whatsapp.md) | Envio pelo WhatsApp | Aceito | 2026-11-03 | Link universal `wa.me`, confirmação manual, sem automação |
| [ADR-005](ADR-005-pessoa-e-participante.md) | Pessoa e participante | Aceito | 2026-11-03 | Pessoa reutilizável + participação por evento |
| [ADR-006](ADR-006-sorteio-online.md) | Sorteio online com links individuais | Aceito | 2026-11-05 | Modo online separado, serviço Dart e links bearer por participante |

## Convenções

- **Status:** `Proposto`, `Aceito`, `Substituído` ou `Rejeitado`.
- **Substituição:** um ADR aceito não é reescrito para mudar a decisão; cria-se um novo ADR que o substitui, com referência explícita.
- **Numeração:** sequencial, com nome em minúsculas e hífens.
- **Relação com o código:** mudanças que contrariem um ADR aceito exigem novo ADR antes da implementação.
- **Privacidade:** exemplos usam apenas dados fictícios.

## Quando criar um ADR

- troca de plataforma, banco, estado, navegação ou biblioteca central;
- mudança no modelo de dados ou nas invariantes do sorteio;
- mudança na forma de envio ou no significado dos estados de entrega;
- decisão que afete segurança, privacidade, backup ou persistência;
- qualquer escolha que um futuro mantenedor possa questionar.
