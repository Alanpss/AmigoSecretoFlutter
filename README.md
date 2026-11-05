# AmigoSecretoFlutter

Aplicativo Flutter para organizar eventos de amigo secreto, gerenciar participantes e grupos e realizar sorteios que respeitam todas as restrições configuradas.

> **Estado:** Fases 1–5 aceitas pelo usuário; a Fase 6, sorteio online com links individuais, está em andamento. O app local segue disponível; começou a extração do motor de sorteio para uso compartilhado com um futuro serviço Dart. Ainda não há autenticação, Firestore ou publicação. Consulte [`docs/PROGRESSO.md`](docs/PROGRESSO.md) para o estado atualizado.

## Descrição para o GitHub

> Aplicativo Flutter local-first para organizar amigo secreto, aplicar restrições de grupos e salvar sorteios com resultados ocultos e revelação individual.

## Sobre o projeto

O AmigoSecretoFlutter é um projeto de portfólio e estudo de desenvolvimento de aplicativos com Flutter. A experiência é voltada a um organizador, em português do Brasil. O modo local não usa backend; um modo online separado está em desenvolvimento.

O projeto dá atenção especial à integridade do sorteio: restrições de grupos não são removidas silenciosamente, os resultados são persistidos antes de qualquer etapa de envio e ficam ocultos até a revelação individual.

### Implementado

- Aplicativo Web responsivo, com interface em português do Brasil.
- Cadastro de eventos, pessoas, participantes, responsáveis e grupos.
- Busca, filtros e revisão das condições do evento.
- Motor Dart puro com matching bipartido, diagnóstico e amostragem uniforme entre sorteios válidos.
- Persistência local transacional, proteção por revisão, bloqueio de edição após o sorteio e invalidação com histórico preservado.
- Resultados ocultos por padrão, com revelação individual.
- Editor de modelo com variáveis validadas e prévia com dados fictícios.
- Fila de entregas com cópia, link `wa.me`, confirmação manual e filtro de pendências; a abertura é testada com launcher simulado.
- Exportação e importação de backup JSON versionado, com prévia, validação de referências e substituição transacional.
- Aviso para exportar após o sorteio e atalho para backup; a tela de falha do banco também oferece restauração de um arquivo validado.

### Em desenvolvimento

- Modo de evento online com sorteio no servidor e um link de resultado por participante (Fase 6).
- Investigar emojis exibidos como caracteres de substituição após o redirecionamento do link `wa.me`; nenhum envio real foi feito.

O plano completo e os critérios de aceite estão em [`docs/PLANO_IMPLEMENTACAO.md`](docs/PLANO_IMPLEMENTACAO.md).

## Requisitos para desenvolvimento

- Flutter **3.47.9 stable** ou compatível com o SDK Dart declarado em `pubspec.yaml`.
- Git.
- Chrome ou Edge para executar e conferir o aplicativo Web.

> A versão de Flutter usada na verificação atual está registrada em [`docs/AMBIENTE.md`](docs/AMBIENTE.md). O projeto não exige Android Studio nem Android SDK para o fluxo Web.

## Configuração local

Clone o repositório e entre na pasta do projeto:

```bash
git clone https://github.com/Alanpss/AmigoSecretoFlutter.git
cd AmigoSecretoFlutter
```

Instale as dependências:

```bash
flutter pub get
```

Execute no Chrome:

```bash
flutter run -d chrome --web-port 8080
```

Se o Chrome não estiver configurado como dispositivo Flutter, use o servidor Web:

```bash
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080
```

Abra o endereço informado pelo Flutter. Use a mesma origem e porta ao retomar o desenvolvimento: no Web, os dados locais ficam no IndexedDB associado à origem do navegador.

## Verificações antes de enviar alterações

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
```

O teste de integração cobre o fluxo de evento, participante, grupo e persistência no Web. Para executá-lo no Chrome:

```bash
flutter drive -d chrome --driver=test_driver/integration_test.dart --target=integration_test/app_flow_test.dart
```

Não registre no Git dados reais de participantes, resultados de sorteios, telefones, bancos locais, backups ou segredos. O `.gitignore` cobre artefatos comuns de build, bancos locais e backups.

## Arquitetura

O código separa a interface, o domínio e a persistência por funcionalidade. A lógica do sorteio não depende de widgets ou de serviços externos.

```text
lib/
  app/             composição, tema, rotas e providers
  core/            banco, migrações e erros compartilhados
  features/
    events/        eventos e revisão
    participants/  pessoas, participantes e responsáveis
    groups/        grupos e restrições
    draw/          matching compartilhado, persistência e apresentação do sorteio
    delivery/      modelos, links e acompanhamento manual das entregas
    settings/      configurações
    backup/        serialização, validação, arquivos e restauração
  shared/          layout e widgets reutilizáveis
test/              testes de domínio, dados e interface
docs/                 contexto, requisitos, arquitetura, plano e progresso
packages/draw_engine/ motor de sorteio Dart puro compartilhado
server/               domínio inicial do serviço online em Dart
```

**Tecnologias principais:** Flutter/Dart, Riverpod, `go_router` e Sembast; IndexedDB é usado para persistência local no Web. O pacote Dart puro do sorteio é compartilhado com `server/`. Autenticação e persistência online ainda não estão implementadas. As versões resolvidas estão nos arquivos `pubspec.lock` correspondentes.

## Desenvolvimento assistido por IA

O aplicativo **não usa IA durante a execução**. Ferramentas de IA são usadas como apoio ao desenvolvimento e devem seguir as mesmas regras de revisão e qualidade do restante do código.

- [`AGENTS.md`](AGENTS.md) define o fluxo obrigatório para agentes: leitura da documentação, respeito à fase autorizada, mudanças pequenas, testes e atualização do progresso.
- Regras de sorteio e persistência devem permanecer em Dart testável, independente da interface.
- Sugestões geradas por IA precisam ser verificadas contra os requisitos e testes; uma resposta do modelo não substitui validação.
- Exemplos, testes e demonstrações usam dados fictícios. Não inserir dados pessoais, tokens ou backups em prompts, logs ou commits.
- Decisões de produto e arquitetura devem ser registradas nos documentos ou ADRs correspondentes.

## Documentação do projeto

| Documento | Conteúdo |
| --- | --- |
| [`docs/CONTEXTO.md`](docs/CONTEXTO.md) | Objetivo, escopo, premissas e privacidade |
| [`docs/REQUISITOS.md`](docs/REQUISITOS.md) | Regras do domínio e critérios de aceite |
| [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md) | Camadas, dados, algoritmos e fluxos |
| [`docs/PLANO_IMPLEMENTACAO.md`](docs/PLANO_IMPLEMENTACAO.md) | Fases, escopo e portões de aceite |
| [`docs/PROGRESSO.md`](docs/PROGRESSO.md) | Estado real, verificações e próximo passo |
| [`docs/DEPLOY.md`](docs/DEPLOY.md) | Preparação do artefato Web e requisitos de hospedagem estática; não publicado |
| [`docs/AMBIENTE.md`](docs/AMBIENTE.md) | Ferramentas e configuração de desenvolvimento |
| [`docs/TESTES.md`](docs/TESTES.md) | Estratégia, cenários e comandos |
| [`docs/decisions/`](docs/decisions/) | Registros das decisões arquiteturais (ADRs) |

## Privacidade e limitações

- Eventos locais ficam no navegador. O modo online ainda está em desenvolvimento e tratará os dados em servidor.
- O armazenamento Web não é criptografado. Limpar os dados do navegador ou mudar de origem pode remover o acesso aos eventos.
- Telefones, responsáveis e resultados são dados pessoais. Use dados fictícios em desenvolvimento e guarde backups não criptografados em locais seguros.
- Abrir o WhatsApp não comprova envio, entrega ou leitura. O projeto não automatiza o WhatsApp.

## Licença

Ainda não foi definida uma licença para reutilização ou distribuição. A ausência de arquivo `LICENSE` não concede permissões adicionais de uso.
