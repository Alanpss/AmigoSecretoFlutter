# ADR-002 — Persistência local com Sembast

- **Status:** Aceito
- **Data:** 2026-11-03
- **Decisores:** projeto Amigo Secreto
- **Relacionados:** `docs/ARQUITETURA.md` (seção 5), `docs/TESTES.md`, `docs/PLANO_IMPLEMENTACAO.md` (Fases 1, 3 e 5)

## Contexto

O MVP é local-first e sem backend. Os dados incluem pessoas, eventos, participantes, grupos, sorteios, atribuições e entregas. O volume é pequeno (centenas de registros), mas há requisitos fortes de consistência:

- o sorteio deve ser gravado atomicamente com atribuições e entregas;
- repetir uma confirmação não pode gerar outro resultado;
- o resultado deve sobreviver a recarregamentos e reaberturas;
- o mesmo código deve funcionar na Web e, futuramente, no Android;
- deve ser possível exportar/importar um backup versionado;
- a solução precisa ser simples de manter, sem servidor.

## Alternativas consideradas

### A. Sembast + sembast_web

- Banco de documentos embarcado, com transações.
- Arquivo no IO e IndexedDB na Web.
- API simples, sem code generation.
- Bom encaixe para dados pequenos e operações transacionais.
- `sembast_web` sincroniza abas e exige transações idempotentes.

### B. `shared_preferences`

- Simples para preferências.
- A documentação oficial alerta que não serve para dados críticos.
- Sem transações, consultas ou integridade referencial.
- Inadequado para sorteio e histórico.

### C. SQLite / `drift`

- Robusto, relacional e amplamente usado.
- Na Web exige configuração de WASM/worker; pode exigir code generation e migrations mais pesadas.
- Seria a escolha se o modelo crescesse muito ou precisasse de consultas complexas.

### D. Hive / key-value

- Rápido e simples.
- Sem transações relacionais e com semântica de consistência menos adequada ao sorteio.
- Exigiria validações e índices manuais.

### E. Backend/Firestore

- Sincronização e multiusuário.
- Contraria o requisito de simplicidade e adiciona custo, autenticação e LGPD.

## Decisão

Usar **Sembast** como banco local, com **`sembast_web`** na Web e arquivo no IO. O banco é aberto antes de `runApp`; falhas mostram uma tela segura, sem apagar dados automaticamente.

Estrutura:

- stores: `meta`, `people`, `events`, `participants`, `groups`, `draws`, `assignments`, `deliveries`, `settings`;
- chaves UUID em string;
- `schemaVersion` começa em `1`;
- migrations explícitas e testadas antes da UI;
- backup JSON versionado, sem criptografia, tratado como sensível.

Regras de transação:

- toda operação que altera mais de um registro usa `db.transaction`;
- o candidato do sorteio é calculado **fora** da transação;
- a transação verifica `event.activeDrawId` e `pairingRevision` e grava o payload pronto;
- a operação é idempotente: repetir a mesma confirmação grava o mesmo conteúdo, sem novo sorteio;
- falha não deixa estado parcial.

## Consequências

### Positivas

- Transações reais e código simples.
- Mesma API conceitual na Web e no Android.
- Sem code generation, servidor ou migrations pesadas.
- Fácil criar banco em memória para testes.
- Backup JSON direto a partir dos stores.

### Negativas e riscos

- Na Web, os dados vivem no IndexedDB, vinculados à origem; limpar o navegador, trocar de porta/domínio ou usar navegação privada pode eliminar o acesso.
- Não há sincronização entre dispositivos.
- Não há criptografia em repouso.
- `sembast_web` pode repetir transações; a idempotência é obrigatória.
- Consultas complexas exigem carregar e filtrar em memória; aceitável no volume previsto.
- O arquivo local no Android/desktop não sobrevive à desinstalação.

### Mitigações

- backup é a única recuperação prática; avisar e recomendar após o sorteio;
- manter a mesma origem no desenvolvimento;
- usar transações idempotentes e revisão de pareamento;
- não usar `localStorage` para dados principais;
- documentar que persistência eterna não é prometida;
- validar schema e referências na importação;
- nunca logar conteúdo de backup.

## Migrations

- `schemaVersion` é gravado no store `meta`.
- Novos stores podem ser adicionados sem migração destrutiva.
- Mudanças de campo exigem migration explícita, testada e executada antes da UI.
- Backup tem versão própria; versão mais nova é rejeitada com mensagem clara.
- Nunca “adivinhar” campos ausentes em produção.

## Quando reconsiderar

Reavaliar esta decisão se:

- o modelo crescer e exigir consultas relacionais complexas;
- o volume deixar de caber confortavelmente em memória;
- a Web precisar de armazenamento mais durável ou criptografado;
- houver sincronização/multiusuário;
- `sembast_web` deixar de atender à idempotência ou à compatibilidade.

Nesses casos, criar um novo ADR (por exemplo, migração para SQLite/drift ou backend).

## Referências

- `docs/ARQUITETURA.md`, seções 5 e 6.
- `docs/REQUISITOS.md`, RN-08 e RN-11.
- `docs/TESTES.md`, seções 6.4 e 10.
