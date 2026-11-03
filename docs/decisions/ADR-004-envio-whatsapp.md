# ADR-004 — Envio pelo WhatsApp

- **Status:** Aceito
- **Data:** 2026-11-03
- **Decisores:** projeto Amigo Secreto
- **Relacionados:** `docs/ARQUITETURA.md` (seção 8.4), `docs/REQUISITOS.md` (RN-09 e seção 2.6), `docs/TESTES.md` (seções 7 e 8), `docs/PLANO_IMPLEMENTACAO.md` (Fase 4)

## Contexto

O organizador precisa entregar o resultado individual a cada participante ou responsável. O aplicativo não tem backend nem conta oficial do WhatsApp. Requisitos:

- abrir a conversa individual correta;
- levar a mensagem pronta;
- usar a conta já conectada no dispositivo;
- não solicitar credenciais;
- não enviar automaticamente;
- não usar automação não oficial;
- não afirmar entrega ou leitura;
- permitir acompanhamento manual;
- funcionar no celular e no computador;
- tratar números internacionais e mensagens com acentos/emojis.

## Alternativas consideradas

### A. Link universal `https://wa.me/<numero>?text=<mensagem>`

- Método oficial de click-to-chat.
- Abre o aplicativo no celular e o WhatsApp Web/Desktop no computador.
- Não exige API, backend, token ou conta business.
- O usuário revisa e confirma o envio dentro do WhatsApp.
- Funciona bem para mensagens individuais.

### B. WhatsApp Business API

- Permite envio automatizado e confirmação de entrega.
- Exige conta business, provedor, custo, templates aprovados e backend.
- Desproporcional para um organizador individual e contrário ao MVP sem backend.

### C. Automação não oficial do WhatsApp Web

- Poderia automatizar cliques e envios.
- Viola potencialmente os termos do WhatsApp e coloca a conta em risco.
- É frágil, insegura e não confiável.
- Rejeitada explicitamente.

### D. Compartilhamento genérico do sistema

- Funciona em alguns cenários, mas não garante a conversa individual correta.
- Menos previsível para o público não técnico.

### E. SMS/e-mail

- Não é o canal pedido; exigiria custo/infra e não teria a mesma adoção.

## Decisão

Usar o **link universal `https://wa.me/<numero>?text=<mensagem>`**, com:

- número em formato internacional, sem `+` e sem caracteres não numéricos;
- mensagem codificada com `Uri.encodeComponent` (acentos, emojis, quebras de linha, `&`, `?`, `#`);
- abertura pelo `url_launcher`;
- confirmação do envio **pelo organizador** dentro do WhatsApp;
- estados explícitos: `Pendente`, `Conversa aberta`, `Envio confirmado pelo organizador`;
- método de confirmação `whatsapp` ou `manual`;
- fallback de copiar a mensagem quando a abertura falhar ou o pop-up for bloqueado.

O app **não** usa API oficial, automação do WhatsApp Web, tokens ou credenciais. Abrir a conversa não é tratado como envio, entrega ou leitura.

## Estados

| Estado | Significado | Como entra |
| --- | --- | --- |
| `Pendente` | Ainda não aberta nem confirmada | Criação da entrega |
| `Conversa aberta` | O link foi aberto com sucesso; não prova envio | Ação “Abrir WhatsApp” bem-sucedida |
| `Envio confirmado pelo organizador` | O organizador declarou que enviou | Confirmação manual com método |

Regras:

- abrir não muda para confirmado;
- copiar não muda o estado;
- reabrir preserva uma confirmação existente;
- falha mantém `Pendente` e oferece copiar;
- o app nunca exibe “entregue” ou “lido”;
- mensagens de um mesmo responsável permanecem separadas por participante.

## Consequências

### Positivas

- Sem backend, custo de API ou credenciais.
- Funciona no celular e no computador.
- Respeita os termos do WhatsApp.
- O organizador mantém controle e revisão.
- Implementação simples e testável com launcher fake.

### Negativas e limitações

- O app não sabe se a mensagem foi enviada, entregue ou lida.
- No computador, o WhatsApp Web/Desktop precisa estar conectado; se não estiver, aparece o QR code.
- Pop-ups podem ser bloqueados; é preciso oferecer copiar.
- O usuário precisa tocar em enviar dentro do WhatsApp.
- Um número válido pode não ter WhatsApp; a confirmação é manual.
- O link expõe o número e o texto ao sistema operacional/navegador; não deve ser logado.
- Mensagens muito longas podem ser limitadas pelo WhatsApp ou pelo navegador.

### Mitigações

- mostrar dono, destinatário e número antes de abrir;
- manter estados honestos;
- oferecer copiar e marcar manualmente;
- testar codificação e normalização;
- não logar URLs ou mensagens;
- avisar sobre a sessão do WhatsApp Web;
- usar apenas dados fictícios em testes.

## Privacidade

- Nenhum dado é enviado a servidores do app.
- O link é montado localmente e entregue ao sistema.
- URLs, mensagens e números não devem aparecer em logs, erros, analytics ou arquivos.
- Backups continuam sensíveis e não devem ser enviados pelo WhatsApp.

## Quando reconsiderar

Reavaliar esta decisão se:

- for necessário envio automático ou confirmação de entrega;
- houver orçamento e requisito para a API oficial do WhatsApp;
- o volume de mensagens justificar um provedor;
- o WhatsApp alterar o formato do link universal;
- houver necessidade de modelos aprovados ou multiusuário.

Nesses casos, criar um novo ADR e revisar arquitetura, custos, privacidade e requisitos.

## Referências

- `docs/ARQUITETURA.md`, seção 8.4.
- `docs/REQUISITOS.md`, seção 2.6 e RN-09.
- `docs/TESTES.md`, seções 7 e 8.
- WhatsApp click-to-chat: `https://faq.whatsapp.com/5913398998672934`.
