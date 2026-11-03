# ADR-001 — Plataforma inicial: Flutter Web

- **Status:** Aceito
- **Data:** 2026-11-03
- **Decisores:** projeto Amigo Secreto
- **Relacionados:** `docs/ARQUITETURA.md` (seção 2), `docs/AMBIENTE.md`, `docs/PLANO_IMPLEMENTACAO.md` (Fase 1)

## Contexto

O aplicativo será usado por uma única pessoa, o organizador, para montar um evento de amigo secreto, realizar o sorteio e enviar resultados individuais pelo WhatsApp. O público não é técnico e precisa de instalação, uso e manutenção simples.

Restrições e forças em jogo:

- funcionar em celular e computador;
- não exigir backend no MVP;
- abrir a conversa correta do WhatsApp com mensagem pronta;
- permitir desenvolvimento e teste sem uma cadeia pesada de ferramentas;
- preservar a possibilidade de gerar um app Android depois;
- evitar custo e complexidade de publicação em lojas nesta etapa.

O ambiente inicial tem Windows 11, sem JDK, Android SDK ou Android Studio. Há Chrome, Edge, Git e VS Code.

## Alternativas consideradas

### A. Flutter Web (PWA) primeiro

- Build estático, executável em navegador.
- Pode ser instalado como PWA em alguns navegadores.
- Usa `wa.me`, que abre o WhatsApp no celular e o WhatsApp Web/Desktop no computador.
- Não exige toolchain Android para começar.
- O mesmo código Dart pode gerar Android depois.

### B. Flutter Android primeiro

- Melhor integração com o aplicativo do WhatsApp e armazenamento mais durável.
- Exige JDK, Android SDK, Gradle, emulador/aparelho e assinatura de APK.
- Distribuição por sideload ou loja; atualização mais trabalhosa para o organizador.
- Aumenta o tempo até o primeiro uso e a superfície de manutenção.

### C. Aplicativo web nativo (sem Flutter)

- Poderia ser mais leve em alguns cenários.
- Duplicaria esforço para Android e não aproveitaria o mesmo código.
- Exigiria decisões próprias de UI, estado, persistência e testes.

### D. Backend + aplicativo

- Permitiria sincronização, multiusuário e envio por API oficial.
- Adicionaria autenticação, custo, LGPD, disponibilidade, deploy e superfície de ataque.
- Não há necessidade comprovada para um organizador individual.

## Decisão

Adotar **Flutter Web (PWA) como plataforma inicial**, com publicação estática e armazenamento local no navegador. Android será uma evolução do mesmo código, em fase posterior e somente se autorizado.

Decisões decorrentes:

- sem backend no MVP;
- persistência local (ver ADR-002);
- link universal do WhatsApp (ver ADR-004);
- estratégia de URL padrão (hash) para funcionar em hospedagem estática sem rewrite;
- porta fixa `8080` no desenvolvimento para preservar a origem do IndexedDB;
- navegadores-alvo: Chrome e Edge atuais; Safari/iOS fora do aceite do MVP.

## Consequências

### Positivas

- Começa sem JDK, Android SDK, emulador ou assinatura.
- Um único código para desktop e celular via navegador.
- Deploy estático simples e barato.
- Atualização imediata ao recarregar a página.
- `wa.me` atende ao envio individual sem API oficial.
- Menor tempo até o primeiro fluxo completo.

### Negativas e riscos

- IndexedDB pode ser limpo, evictado ou perdido ao trocar navegador/dispositivo/origem.
- Não há sincronização entre dispositivos.
- Armazenamento sem criptografia.
- No computador, o WhatsApp Web/Desktop precisa de sessão conectada.
- Pop-ups e restrições do navegador podem afetar a abertura do link; é preciso oferecer copiar a mensagem.
- A experiência de instalação como PWA varia por navegador.
- A Web não tem a mesma integração nativa que um app Android.

### Mitigações

- backup JSON versionado e aviso de sensibilidade;
- recomendação de backup após o sorteio;
- uso de uma única porta/origem no desenvolvimento;
- fallback de copiar mensagem;
- documentação explícita das limitações;
- arquitetura que mantém o domínio independente da plataforma.

## Quando reconsiderar

Reavaliar esta decisão se:

- o uso principal for em celular sem depender de navegador;
- a perda potencial do IndexedDB for inaceitável;
- a integração nativa com o WhatsApp for requisito;
- houver necessidade de sincronização, multiusuário ou envio por API oficial;
- o custo de manter um backend passar a ser justificado.

Nesses casos, criar um novo ADR. Se Android for escolhido, a Fase 1 deve incluir o toolchain Android e a estimativa de ambiente deve ser refeita.

## Referências

- `docs/ARQUITETURA.md`, seção 2.
- `docs/AMBIENTE.md`.
- `docs/CONTEXTO.md`, seções 4 e 7.
- WhatsApp click-to-chat: `https://faq.whatsapp.com/5913398998672934`.
