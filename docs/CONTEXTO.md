# Contexto e escopo

## 1. Visão do produto

O Amigo Secreto mantém eventos locais e passa a desenvolver um modo online separado. No modo local, o organizador mantém os dados no próprio dispositivo e pode ver os resultados; no modo online, o sorteio é guardado no servidor e distribuído por links individuais.

O aplicativo deve ser simples para quem não tem conhecimento técnico: formulários curtos, linguagem clara, poucos passos e retomada fácil depois de fechar o navegador ou o celular.

## 2. Público e modelo de uso

- **Organizador local:** uma pessoa que cadastra participantes, realiza o sorteio, pode ver os resultados e confirma os envios.
- **Organizador online:** entra com Google, cria evento online e recebe links para distribuir sem ver os pares na tela.
- **Participante:** pessoa que tira outra. Pode ter telefone próprio, usar o telefone de um responsável ou não ter contato válido para WhatsApp.
- **Responsável:** pessoa que recebe a mensagem no lugar do participante. Pode participar ou não do sorteio. O resultado continua pertencendo ao participante.
- **Convidado sem celular:** participa normalmente do sorteio; a entrega é feita pelo responsável ou manualmente.

No modo local, o organizador pode acessar todos os resultados. No modo online, a interface do organizador não recebe os pares. Os links são bearer: qualquer pessoa que obtenha um link pode abri-lo, inclusive o organizador; administradores técnicos do serviço podem ter acesso à infraestrutura.

## 3. Escopo do MVP

### Incluído

- múltiplos eventos locais;
- cadastro reutilizável de pessoas e participação por evento;
- nome, apelido, telefone e situação ativa/inativa;
- responsável pelo recebimento, inclusive responsável que não participa do sorteio;
- famílias, casais e outros grupos, com restrição ativável por grupo;
- uma pessoa em vários grupos;
- revisão de pendências antes do sorteio;
- sorteio com matching bipartido e validação completa;
- resultado salvo antes do envio e preservado ao reabrir;
- invalidação explícita do sorteio quando participantes ou restrições mudarem;
- fila de envio com abertura do WhatsApp, cópia da mensagem, confirmação manual e filtros;
- modelo de mensagem editável com variáveis controladas;
- backup e importação em JSON;
- interface responsiva em português do Brasil.

### Fora do MVP

- backend, banco em nuvem, login e sincronização no modo local;
- envio automático ou sem interação pelo WhatsApp;
- WhatsApp Business API, automação do WhatsApp Web ou bibliotecas não oficiais;
- confirmação de entrega/leitura pelo aplicativo;
- iOS e publicação em lojas;
- videochamada, chat interno, notificações push;
- proibições específicas entre pares (além de grupos);
- obrigação de formar um único ciclo;
- evitar repetição de pares de eventos anteriores;
- sorteio ponderado por gênero, idade ou outros critérios;
- criptografia do armazenamento local ou backup protegido por senha;
- multiusuário simultâneo, aprovação de participantes ou sorteio auditable por terceiros.

## 4. Decisões consolidadas

| Tema | Decisão | Justificativa resumida |
| --- | --- | --- |
| Plataforma inicial | Flutter Web (PWA), com publicação estática | Menor atrito de instalação; funciona em celular e computador; sem backend. Android fica para depois. |
| Modo local | Sem backend, login ou sincronização | Preserva uso simples, local e offline. |
| Modo online (pós-MVP) | Cloud Run Dart, Firestore, Firebase Authentication Google e Hosting | Permite sortear no servidor e revelar cada resultado por link individual. |
| Persistência | Sembast local: arquivo no Android/desktop e IndexedDB na Web | Transações, simplicidade, suporte a todas as plataformas e backup em JSON. |
| Estado | Riverpod, sem code generation | Testável, explícito e proporcional ao tamanho do app. |
| Navegação | `go_router` | Rotas declarativas, URLs na Web e suporte a deep links. |
| Injeção de dependência | Providers do Riverpod | Evita pacote extra e mantém as dependências explícitas. |
| Modelo de pessoa | `Person` reutilizável + `Participant` por evento | Evita redigitar dados e separa identidade de participação. |
| Responsável | Referência direta a uma `Person`; telefone resolvido nela | Sem cadeias de responsáveis; vínculo não cria restrição. |
| Restrições | União de grupos com restrição ativa | Uma pessoa pode estar em família e casal; qualquer grupo restrito proíbe o par. |
| Sorteio | Matching bipartido exato + amostragem uniforme entre soluções válidas | Garante existência, respeita restrições e não usa tentativas indefinidas. |
| Ciclos | Vários ciclos são permitidos | Atende às regras sem impor uma restrição de produto desnecessária. |
| WhatsApp | Link universal `https://wa.me/<numero>?text=<mensagem>` | Método oficial de click-to-chat; abre o app ou o WhatsApp Web. |
| Confirmação de envio | Manual, pelo organizador | O app não tem como provar envio/entrega pelo número pessoal. |
| Resultados | Ocultos por padrão, revelação individual | Reduz exposição acidental em telas compartilhadas. |
| Backup | JSON versionado, sensível, com exportação/importação | Única forma prática de recuperar dados locais. |

## 5. Premissas adotadas

Estas premissas são reversíveis e devem ser confirmadas antes ou durante a fase indicada:

1. **Plataforma inicial Web.** Se o usuário preferir Android desde o início, a Fase 1 muda para incluir JDK e Android SDK; a arquitetura e o código Dart permanecem os mesmos.
2. **Um organizador por instalação.** Não há contas nem permissões.
3. **Um dispositivo/navegador por evento.** Não há sincronização; usar outro dispositivo cria outra base local.
4. **Brasil como país padrão.** Telefones sem `+` são interpretados como brasileiros; números internacionais são aceitos com `+código do país`.
5. **Até cerca de 200 participantes ativos por evento.** O algoritmo suporta mais, mas o MVP será testado e otimizado nessa faixa.
6. **Data do evento é opcional.** O nome do evento é obrigatório.
7. **Exclusão de evento é definitiva**, com confirmação e recomendação de backup. Arquivamento fica como melhoria futura.
8. **Modelo de mensagem é único por evento.** Não há modelos por participante no MVP.
9. **Backup não é criptografado.** O arquivo é tratado como sensível e não deve ser compartilhado.
10. **Android é uma evolução do mesmo código**, não um aplicativo separado.

## 6. Limitações conhecidas

### Armazenamento local na Web

- Os dados ficam no IndexedDB do navegador, vinculados à origem (esquema + domínio + porta).
- Limpar dados do navegador, usar navegação privada, trocar de navegador/dispositivo ou mudar a origem pode eliminar o acesso.
- O navegador pode despejar dados sob pressão de armazenamento; não há garantia absoluta de persistência.
- Não há criptografia em repouso. Quem tiver acesso ao perfil do navegador pode, em princípio, acessar os dados.
- Não há sincronização entre celular e computador.
- O organizador deve exportar backup antes de limpar o navegador, trocar de dispositivo ou encerrar o evento.

### WhatsApp

- O link abre a conversa com a mensagem pré-preenchida; o organizador ainda precisa tocar em enviar.
- O aplicativo não sabe se a mensagem foi enviada, entregue ou lida.
- No computador, o WhatsApp Web/Desktop precisa estar conectado; se não estiver, o WhatsApp exibirá o QR code.
- Pop-ups podem ser bloqueados pelo navegador; o app deve oferecer copiar mensagem como alternativa.
- Não será usada automação não oficial, o que poderia violar termos do WhatsApp e colocar a conta em risco.

### Produto

- No modo local, o organizador vê todos os resultados; no modo online, não os vê na interface.
- Um responsável pode receber várias mensagens separadas se for contato de várias pessoas.
- O resultado é do participante, não do responsável.
- Não há como garantir que o responsável não compartilhe a mensagem.
- O app não impede que o organizador revele resultados; apenas os oculta por padrão.

### Plataforma

- iOS não está no MVP: exige macOS/Xcode para build e distribuição.
- O Android não será testado enquanto não for incluído em uma fase autorizada.
- A Web não tem a mesma integração nativa com o WhatsApp que um app Android; o link universal é o compromisso.

## 7. Decisões pendentes de confirmação

Estas decisões afetam o início ou o fim do MVP:

1. **Confirmar Web como plataforma inicial** (recomendado) ou iniciar por Android.
2. **Confirmar se o Android entra no MVP** ou fica para uma fase posterior.
3. **Definir onde a versão Web será publicada** (localhost, rede local ou hospedagem estática). Publicação não será feita sem autorização.
4. **Confirmar o limite de participantes** para testes de aceite; a premissa é 200 ativos.
5. **Confirmar se exclusão de evento basta** ou se é necessário arquivamento.
6. **Confirmar se backup sem senha é aceitável** para o primeiro uso.

Nenhuma delas bloqueia a criação desta documentação. A decisão 1 precisa ser confirmada antes da Fase 1; a 3, antes da Fase 5.

## 8. Privacidade e tratamento de dados

- Dados tratados: nome, apelido, telefone, vínculo de responsável, grupos, participação, resultado do sorteio e estado de envio.
- Finalidade: exclusivamente organizar o evento e enviar as mensagens.
- Compartilhamento local: os dados locais não são enviados ao servidor do app.
- Compartilhamento online: o serviço guarda evento, contatos e resultados até exclusão/revogação; cada link permite abrir somente o resultado associado, mas pode ser encaminhado.
- Retenção local: enquanto o organizador mantiver os dados no dispositivo. O app deve oferecer exclusão de evento e backup.
- Dados sensíveis: resultados e telefones. Backups devem ser guardados em local seguro e apagados quando não forem mais necessários.
- Exemplos, testes e documentação usam apenas dados fictícios. Nenhum número real deve ser usado em testes automatizados.

## 9. Relação com os demais documentos

- Regras detalhadas e critérios de aceite: `docs/REQUISITOS.md`.
- Estrutura, modelo de dados e fluxos: `docs/ARQUITETURA.md`.
- Fases e autorização: `docs/PLANO_IMPLEMENTACAO.md`.
- Estado atual: `docs/PROGRESSO.md`.
- Ambiente: `docs/AMBIENTE.md`.
- Testes: `docs/TESTES.md`.
- Justificativas: `docs/decisions/`.
