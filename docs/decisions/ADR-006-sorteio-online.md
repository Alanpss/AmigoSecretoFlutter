# ADR-006 — Sorteio online com links individuais

- **Status:** Aceito
- **Data:** 2026-11-05
- **Decisores:** usuário e equipe do projeto
- **Relacionados:** `docs/CONTEXTO.md`, `docs/REQUISITOS.md` (RF-ONL), `docs/ARQUITETURA.md` (seção 12), `docs/PLANO_IMPLEMENTACAO.md` (Fase 6)

## Contexto

O organizador quer distribuir os resultados sem vê-los durante o fluxo. No modo local, o banco do navegador contém todos os pares e não é possível ocultá-los tecnicamente do proprietário daquele navegador. A solução exige sortear e guardar os pares fora do cliente.

## Decisão

- manter os eventos e sorteios locais existentes;
- adicionar modo de evento online separado;
- executar o mesmo motor de sorteio Dart no serviço online;
- usar Firebase Authentication Google, Firestore privado, serviço Dart no Cloud Run e Firebase Hosting;
- retornar ao organizador nomes, destinatários e links, nunca os pares;
- criar um token aleatório por participante, guardar somente seu hash no servidor e revelar somente o resultado associado;
- usar links bearer reabríveis/revogáveis; qualquer pessoa que obtenha o link pode abrir o resultado;
- continuar usando `wa.me` com mensagem contendo somente o link; sem envio automático;
- manter resultados e links online fora do backup local.

## Consequências

O pacote `draw_engine` é compartilhado pelo Flutter e serviço, reduzindo risco de divergência do algoritmo. O modo online exige autenticação, banco, validação de acesso, operação e possível custo de nuvem. O organizador não vê os pares na UI, mas o bearer pode ser aberto por quem o recebe e administradores técnicos do serviço podem ter acesso aos dados. Deploy e criação de projeto Firebase exigem autorização específica.

## Alternativas rejeitadas

- links produzidos somente no cliente: o pareamento permaneceria no navegador do organizador;
- aplicação 100% local: não fornece uma barreira contra acesso intencional do organizador aos pares;
- envio automático pelo WhatsApp: fora do escopo e contrário ao envio manual definido no ADR-004.
