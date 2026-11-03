# AGENTS.md — Instruções para agentes de IA

Este arquivo se aplica à raiz deste repositório, em qualquer diretório de clone.

## 1. Leitura obrigatória antes de alterar qualquer arquivo

Na ordem:

1. `README.md` — visão geral e mapa da documentação.
2. `docs/CONTEXTO.md` — escopo, premissas e decisões consolidadas.
3. `docs/PROGRESSO.md` — fase autorizada, estado real e ponto exato de retomada.
4. Documento específico da tarefa:
   - comportamento: `docs/REQUISITOS.md`;
   - estrutura/dados: `docs/ARQUITETURA.md`;
   - sequência/escopo da fase: `docs/PLANO_IMPLEMENTACAO.md`;
   - ambiente/dependências: `docs/AMBIENTE.md`;
   - testes: `docs/TESTES.md`;
   - justificativa de decisão: `docs/decisions/`.

Não comece a codificar antes de identificar a fase autorizada e o critério de aceite correspondente.

## 2. Regra de fase

- Trabalhe **somente** na fase explicitamente autorizada pelo usuário em `docs/PROGRESSO.md`.
- Não avance para a fase seguinte por conta própria, mesmo que a anterior pareça concluída.
- Se a tarefa pedida pertencer a outra fase, registre o impedimento e peça autorização.
- Uma fase só termina quando todos os critérios de aceite observáveis e os testes obrigatórios forem atendidos; caso contrário, registre como pendente.

## 3. Mudanças pequenas e revisáveis

- Faça a menor mudança possível para completar a tarefa.
- Evite refatorações amplas, renomeações em massa ou troca de bibliotecas sem necessidade comprovada.
- Preserve alterações existentes do usuário. Se encontrar trabalho não relacionado, não o apague nem o reverta.
- Não adicione dependência sem justificar em `docs/ARQUITETURA.md` ou em um ADR, e sem atualizar `docs/AMBIENTE.md` quando afetar o ambiente.
- Não implemente funcionalidades fora do MVP sem autorização.

## 4. Documentação e verificação

Toda mudança de comportamento deve atualizar, na mesma entrega:

- `docs/PROGRESSO.md`: o que foi feito, comandos executados, resultados, falhas e próximo passo;
- `docs/REQUISITOS.md`, se alguma regra ou critério de aceite mudou;
- `docs/ARQUITETURA.md` ou ADR, se a estrutura, o modelo de dados ou uma decisão técnica mudou;
- `docs/TESTES.md`, se novos cenários forem adicionados;
- `docs/AMBIENTE.md`, se versões, dependências ou instalação mudarem.

Registre comandos e resultados reais. Não declare “testes passando” sem executá-los. Se um teste falhar, registre a falha e o impacto; não a esconda.

## 5. Qualidade e comandos previstos

Comandos de referência (executar somente depois que o projeto Flutter existir):

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter build web --release
```

Critérios mínimos:

- `flutter analyze` sem erros;
- testes unitários e de widget da fase passando;
- formatação verificada;
- nenhum dado pessoal real, segredo ou backup no repositório;
- documentação afetada atualizada;
- sem aviso de “concluído” quando houver pendência conhecida.

## 6. Segurança e privacidade

- Nunca registre nomes, telefones, resultados, backups ou tokens em logs, prints, issues, commits ou mensagens de erro.
- Use somente dados fictícios em exemplos, testes, seeds e documentação.
- Não faça commit de arquivos de backup, bancos locais ou exports. O `.gitignore` deve cobrir esses arquivos quando o projeto for criado.
- Não publique, faça deploy, envie mensagens reais pelo WhatsApp ou compartilhe o projeto sem autorização explícita.
- Não execute comandos destrutivos (`git reset --hard`, `git clean -fd`, remoção de diretórios do usuário, exclusão de dados) sem autorização explícita.
- `flutter clean` só deve ser usado quando necessário e com explicação; não apague bancos locais para “resolver” problemas sem antes exportar backup.

## 7. Comportamento esperado da interface

- Idioma da interface: português do Brasil.
- Código, nomes de classes e APIs internas: inglês, salvo termos de domínio consagrados.
- Textos claros, sem jargão técnico; erros explicam o que aconteceu e o que fazer.
- Resultados ocultos por padrão, com revelação individual.
- Confirmação explícita para exclusões, invalidação de sorteio e importação de backup.
- Acessibilidade: contraste, foco, rótulos semânticos, áreas de toque de pelo menos 48×48 e suporte a escala de texto.
- Layout responsivo para celular e computador.

## 8. Regras de domínio que não podem ser violadas

- Ninguém tira a si mesmo.
- Cada participante ativo tira exatamente uma pessoa e é sorteado exatamente uma vez.
- Restrições de grupos ativos são obrigatórias; nenhuma é relaxada silenciosamente.
- O vínculo com responsável não cria restrição de sorteio.
- O responsável é apenas destinatário; o resultado pertence ao participante.
- O telefone do responsável é resolvido diretamente, sem cadeia de responsáveis.
- O sorteio confirmado é salvo antes de qualquer envio e não muda ao reabrir o aplicativo.
- Abrir o WhatsApp não comprova envio; somente o organizador pode confirmar.
- Não usar automação não oficial do WhatsApp.

## 9. Mecanismos do OpenCode

- O mecanismo de instrução suportado e usado neste projeto é o `AGENTS.md` na raiz do projeto.
- Skills são suportadas em `.opencode/skills/<nome>/SKILL.md` (ou caminhos compatíveis), com frontmatter `name` e `description`, nome em minúsculas com hífens e igual ao nome da pasta. **Não crie skills fictícias.**
- Não há skill personalizada neste momento; `AGENTS.md` cobre o fluxo. Se uma habilidade repetível justificar uma skill no futuro, crie-a apenas com instruções reais e validadas, e registre a decisão.
- Não invente comandos, arquivos de configuração ou recursos que o OpenCode não reconheça. Consulte a documentação oficial antes de configurar `opencode.json`, comandos, agentes ou permissões.
- Execute os comandos a partir da raiz do repositório para que este `AGENTS.md` seja carregado como instrução do projeto.

## 10. Estrutura de código esperada

- `lib/app/`: composição do aplicativo, tema, rotas e providers globais.
- `lib/core/`: banco, erros, relógio, IDs, telefone e utilitários compartilhados.
- `lib/features/`: funcionalidades em pastas próprias (`events`, `participants`, `groups`, `draw`, `delivery`, `backup`, `settings`), com `data/`, `domain/` e `presentation/` apenas quando fizer sentido.
- `lib/shared/`: widgets reutilizáveis e componentes de layout.
- `test/`: testes unitários e de widget espelhando `lib/`.
- `integration_test/`: fluxos de ponta a ponta.
- `docs/`: documentação e ADRs.

A lógica de sorteio deve ser Dart puro, sem dependência de widgets, banco ou WhatsApp. A renderização de mensagens e a geração de links também devem ser testáveis sem abrir o WhatsApp.

## 11. Critério de conclusão de uma entrega

Uma entrega está concluída quando:

1. o escopo da fase foi cumprido e o que ficou de fora está registrado;
2. os critérios de aceite observáveis foram demonstrados;
3. os testes obrigatórios foram executados e passaram, ou as falhas estão documentadas com impacto;
4. `flutter analyze` e a formatação estão limpos;
5. a documentação afetada foi atualizada;
6. `docs/PROGRESSO.md` contém o ponto exato de retomada e a próxima ação;
7. não há segredos, dados pessoais reais ou backups no repositório.

Se qualquer item não puder ser atendido, a entrega é **parcial** e deve ser declarada assim.
