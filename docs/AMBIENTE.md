# Ambiente e dependências

Este documento é a fonte de verdade para **ferramentas, versões, instalação e diagnóstico do ambiente**. A Fase 1 foi autorizada e executada em 2026-11-03; os comandos abaixo ficam registrados para reprodução e auditoria.

## 1. Resumo

| Item | Situação em 2026-11-03 |
| --- | --- |
| Plataforma de desenvolvimento | Windows 11 Home Single Language 10.0.26300, 64 bits |
| Conta | Perfil de usuário sem sessão administrativa |
| Flutter SDK | **3.47.9 stable instalado** em `%USERPROFILE%\development\flutter` |
| Dart | **3.13.7** (incluído no Flutter) |
| DevTools | 2.60.0 |
| Java/JDK | Não instalado (desnecessário para Web) |
| Android SDK/Studio | Não instalado (fora do MVP desta fase) |
| Git | 2.49.0.windows.1 |
| Chrome | 156.0.8078.80 |
| Edge | 156.0.4314.58 |
| VS Code | 1.144.1 |
| Espaço livre em `C:` | 156,1 GB no início da instalação |
| Backend | Não será usado no MVP |

**Resultado da instalação:** ZIP oficial de 1.849,6 MB, SHA-256 conferido (`d8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e`), extração em `%USERPROFILE%\development\flutter` e inclusão de `...\flutter\bin` no `PATH` do usuário.

A plataforma inicial recomendada é **Flutter Web**. Isso permite começar sem JDK, Android SDK, emulador ou assinatura de APK. O Android fica para uma fase posterior, se autorizado.

## 2. Dependências obrigatórias e opcionais

### 2.1 Obrigatórias para o MVP Web

| Dependência | Versão de referência | Para que serve | Como será obtida |
| --- | --- | --- | --- |
| Flutter SDK | 3.47.9 stable (Dart 3.13.7) | Compilar e executar o app | ZIP oficial, escopo do usuário |
| Git | 2.49.0 ou superior | Versionamento e dependências | Já instalado |
| Chrome ou Edge | Versões atuais | Executar e depurar a Web | Já instalados |
| PowerShell | 5.1 ou superior | Comandos de instalação e verificação | Já incluído no Windows |
| Internet | — | Baixar SDK e pacotes | Rede local |
| Espaço em disco | 6–8 GB livres | SDK, cache e builds | 156,9 GB disponíveis |

### 2.2 Opcionais ou de fases posteriores

| Dependência | Quando | Observação |
| --- | --- | --- |
| Extensão Flutter/Dart no VS Code | Recomendada na Fase 1 | Não é obrigatória para compilar; melhora edição e depuração |
| Android SDK + JDK | Somente se Android for autorizado | Não instalar agora |
| Android Studio | Somente se Android for autorizado | Não é necessário para Web |
| Visual Studio com C++ | Somente para build Windows desktop | Fora do escopo |
| Chromedriver | Testes de integração na Web | Necessário apenas quando esses testes forem executados |
| Leitor de tela (NVDA/Narrator) | Verificação de acessibilidade | O Narrator já acompanha o Windows |

### 2.3 Não instalar sem necessidade demonstrada

- `get_it`, `freezed`, `json_serializable`, `drift`, `shared_preferences`;
- Firebase, serviços de nuvem, analytics ou backend;
- automação não oficial do WhatsApp;
- Android SDK, emulador ou Android Studio antes da fase correspondente.

## 3. Versões de referência dos pacotes

Versões consultadas em 2026-11-03. A Fase 1 deve registrar as versões efetivamente resolvidas em `pubspec.lock`; se houver divergência compatível, vale o lock.

| Pacote | Versão de referência | Fase | Uso |
| --- | --- | --- | --- |
| `flutter_riverpod` | ^3.4.3 | 1 | Estado e injeção de dependência |
| `go_router` | ^18.1.2 | 1 | Navegação |
| `sembast` | ^3.10.0 | 1 | Banco local |
| `sembast_web` | ^2.4.6+1 | 1 | Banco no IndexedDB |
| `path_provider` | ^2.1.6 | 1 | Diretório do banco no IO |
| `intl` | ^0.20.3 | 1 | Datas e números em pt-BR |
| `flutter_localizations` | SDK | 1 | Textos Material em pt-BR |
| `url_launcher` | ^6.3.3 | 4 | Abrir o link do WhatsApp |
| `phone_numbers_parser` | ^9.0.29 | 4 | Validar/normalizar telefones |
| `uuid` | ^4.6.0 | 2 | IDs estáveis |
| `file_picker` | ^13.3.2 | 5 | Exportar/importar backup |
| `flutter_lints` | ^6.0.0 | 1 | Lint (desenvolvimento) |
| `integration_test` | SDK | 2+ | Testes de integração (desenvolvimento) |

Observações:

- `phone_numbers_parser` é Dart puro e funciona na Web; é mantido por terceiros e deve ficar isolado atrás de um value object.
- `file_picker` v13 usa `FilePicker.pickFile()`, `FilePicker.saveFile()` e `PlatformFile.readAsBytes()`; a API é diferente de versões antigas.
- `pubspec.lock` deve ser commitado por ser um aplicativo.

**Fase 4, 2026-11-03:** `url_launcher: ^6.3.3` foi adicionado ao `pubspec.yaml`; `flutter pub get` resolveu `url_launcher 6.3.3` e seus implementadores de plataforma. O launcher usa `LaunchMode.externalApplication`; widgets e testes injetam um fake e não abrem o WhatsApp real.

**Fase 5, 2026-11-03:** `file_picker: ^13.3.2` foi adicionado e resolvido (`file_picker 13.3.2`, `file_picker_web 4.2.0` e implementações das plataformas disponíveis). A API v13 usa `FilePicker.pickFile()`/`PlatformFile.readAsBytes()` para importar e `FilePicker.saveFile(fileName:, bytes:, mimeType:)` para exportar. Confira o changelog oficial antes de atualizar a versão principal.

## 4. Instalação do Flutter no escopo do usuário

**Pré-requisito:** autorização explícita para a Fase 1.

### 4.1 Por que no escopo do usuário

- A sessão não é administrativa.
- Não exige alterar `C:\Program Files` nem variáveis de sistema.
- Facilita remover ou atualizar o SDK sem afetar outros usuários.
- O `PATH` de usuário é suficiente para o terminal e o VS Code.

**Destino usado:** `%USERPROFILE%\development\flutter`
**Evitar:** caminhos com espaços, OneDrive, `Program Files` ou pastas sincronizadas.

> **Estado:** instalação concluída em 2026-11-03. Os comandos desta seção servem para reprodução ou reinstalação.

### 4.2 Download e verificação

Release oficial confirmado em 2026-11-03:

| Campo | Valor |
| --- | --- |
| Versão | 3.47.9 stable |
| Dart | 3.13.7 |
| Arquivo | `flutter_windows_3.47.9-stable.zip` |
| URL | `https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.47.9-stable.zip` |
| SHA-256 | `d8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e` |

Comandos (executar somente na Fase 1 autorizada):

```powershell
$version  = '3.47.9'
$tempRoot = Join-Path $env:LOCALAPPDATA 'Temp\opencode'
$zip      = Join-Path $tempRoot "flutter_windows_$version-stable.zip"
$dest     = Join-Path $env:USERPROFILE 'development'
$url      = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_$version-stable.zip"
$expected = 'd8e2b5977e09082c6440f89dc1aa887b94c8fbcc3b39222797046295a3f68a9e'

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Invoke-WebRequest -Uri $url -OutFile $zip

$actual = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) {
    throw "SHA-256 divergente. Download interrompido. Esperado: $expected; obtido: $actual"
}

Expand-Archive -Path $zip -DestinationPath $dest -Force
```

Se `Expand-Archive` for muito lento, uma alternativa nativa é:

```powershell
tar -xf $zip -C $dest
```

**Nunca** ignore a divergência de hash nem baixe o SDK de espelhos não oficiais. Se o hash oficial mudar, consulte o JSON oficial de releases e registre a atualização neste documento.

### 4.3 PATH do usuário

```powershell
$flutterBin = Join-Path $env:USERPROFILE 'development\flutter\bin'
$userPath   = [Environment]::GetEnvironmentVariable('Path', 'User')

if (($userPath -split ';') -notcontains $flutterBin) {
    [Environment]::SetEnvironmentVariable('Path', "$flutterBin;$userPath", 'User')
}

# Para o terminal atual:
$env:Path = "$flutterBin;$env:Path"
```

Depois, **fechar e abrir um terminal novo** e confirmar:

```powershell
Get-Command flutter
flutter --version
```

Resultado esperado:

```text
Flutter 3.47.9 • channel stable • ...
Dart 3.13.7 • ...
```

### 4.4 Configuração inicial

```powershell
flutter config --enable-web
flutter devices
flutter doctor -v
```

- `flutter devices` deve listar Chrome e/ou Edge.
- Se o Chrome não for detectado, definir `CHROME_EXECUTABLE` para o caminho do executável.
- Não executar `flutter doctor --android-licenses` enquanto Android estiver fora do escopo.

### 4.5 Criação do projeto sem sobrescrever a documentação

O diretório raiz deste repositório já contém `README.md`, `AGENTS.md` e `docs/`. Para evitar sobrescrita, gerar o projeto em uma pasta temporária e copiar apenas os arquivos de aplicativo:

```powershell
$tempRoot  = Join-Path $env:LOCALAPPDATA 'Temp\opencode'
$bootstrap = Join-Path $tempRoot ('amigo_secreto_bootstrap_' + [guid]::NewGuid().ToString('N'))

flutter create --platforms=web --project-name amigo_secreto --org br.com.amigosecreto $bootstrap

$target = (Get-Location).Path
Copy-Item "$bootstrap\pubspec.yaml"          $target -Force
Copy-Item "$bootstrap\analysis_options.yaml" $target -Force
Copy-Item "$bootstrap\.gitignore"            $target -Force
Copy-Item "$bootstrap\.metadata"             $target -Force
Copy-Item "$bootstrap\lib"                   $target -Recurse -Force
Copy-Item "$bootstrap\web"                   $target -Recurse -Force
Copy-Item "$bootstrap\test"                  $target -Recurse -Force

Set-Location $target
flutter pub get
```

**Não copiar** o `README.md` gerado pelo Flutter, para preservar o README do projeto.

### 4.6 Dependências da Fase 1

```powershell
flutter pub add flutter_riverpod go_router sembast sembast_web path_provider intl
flutter pub add flutter_localizations --sdk=flutter
flutter pub add --dev flutter_lints
```

As demais dependências entram nas fases indicadas na seção 3. Não adicionar pacote sem justificativa em `docs/ARQUITETURA.md` ou ADR.

## 5. Resultado do `flutter doctor`

Executado em 2026-11-03:

```text
[√] Flutter (Channel stable, 3.47.9, on Microsoft Windows [versão 10.0.26300.9711], locale pt-BR)
    • Dart version 3.13.7
    • DevTools version 2.60.0
[√] Windows Version (Windows 11 or higher, 26H2, 2009)
[X] Android toolchain - develop for Android devices
    X Unable to locate Android SDK.
[X] Visual Studio - develop Windows apps
```

Avisos aceitos nesta fase:

| Aviso | Situação | Ação |
| --- | --- | --- |
| `Android toolchain` ausente | Esperado; Android fora do MVP | Não instalar agora |
| `Visual Studio` ausente | Esperado; desktop Windows fora do escopo | Não instalar agora |
| Extensão Flutter do VS Code ausente | Opcional | Instalar se o usuário quiser |
| Developer Mode desabilitado | Pode afetar plugins/symlinks | Habilitar manualmente se o Flutter solicitar |
| `Unable to find bundled Java version` | Decorrente da ausência do Android | Ignorar enquanto Android estiver fora |

**Não é aceitável** ignorar erro de versão do Flutter, falha de download, hash divergente, erro de `pub get` ou ausência de navegador.

## 6. Ações manuais previstas

1. **Habilitar o Modo de Desenvolvedor** se o Flutter solicitar:
   - Configurações → Sistema → Para desenvolvedores → Modo de desenvolvedor.
   - Essa ação pode exigir confirmação com privilégios administrativos; se não for possível, registrar o aviso e verificar se o fluxo Web funciona sem ela.
2. **Instalar a extensão Flutter/Dart no VS Code** (opcional, recomendada).
3. **Permitir acesso de rede** a `storage.googleapis.com` e `pub.dev` no firewall/proxy, se houver bloqueio.
4. **Manter a porta 8080** para o desenvolvimento Web, para preservar a origem do IndexedDB.
5. **Não usar navegação privada** para testar persistência.
6. **Não limpar dados do navegador** durante os testes sem exportar backup.

## 7. Estimativa de disco

| Item | Espaço aproximado |
| --- | --- |
| ZIP do SDK | 1,1–1,5 GB |
| SDK extraído | 3,0–3,8 GB |
| Cache do Pub | 0,5–1,0 GB |
| Artefatos de build Web | 0,3–0,8 GB |
| **Total estimado** | **5–8 GB** |

Há 156,9 GB livres, portanto o espaço não é um bloqueio. O ZIP temporário pode ser apagado depois da instalação verificada.

## 8. Comandos de verificação da Fase 1

```powershell
flutter --version
flutter doctor -v
flutter devices
flutter config --enable-web
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build web --release
flutter run -d chrome --web-port 8080
```

Resultados reais de 2026-11-03:

| Comando | Resultado |
| --- | --- |
| `flutter --version` | Flutter 3.47.9 stable; Dart 3.13.7; DevTools 2.60.0 |
| `flutter doctor -v` | Flutter e Windows OK; Android e Visual Studio ausentes |
| `flutter devices` | Windows, Chrome 156.0.8078.80 e Edge 156.0.4314.58 |
| `flutter config --enable-web` | `enable-web` = `true` |
| `flutter pub get` | Dependências resolvidas; `pubspec.lock` gerado |
| `dart format .` | 21 arquivos formatados; 0 alterações na última execução |
| `flutter analyze` | `No issues found!` |
| `flutter test` | 6 testes passando |
| `flutter build web --release` | Concluído; saída em `build/web` |
| `flutter run -d chrome --web-port 8081` | Serviço de depuração e app iniciados (porta 8080 estava em uso) |
| `flutter run -d web-server --web-port 8080` | App servido e banco criado no IndexedDB |

Registrado em `docs/PROGRESSO.md`: versões exatas, avisos aceitos, resultados e limitações de automação do navegador.

## 9. Problemas comuns e conduta

| Sintoma | Causa provável | Conduta |
| --- | --- | --- |
| `flutter` não reconhecido | PATH não atualizado | Abrir terminal novo; conferir `Get-Command flutter` |
| `pub get` falha por rede/proxy | Firewall ou proxy | Configurar proxy no ambiente; não desabilitar TLS |
| Chrome não aparece | Executável fora do caminho padrão | Definir `CHROME_EXECUTABLE` |
| Dados somem ao reiniciar | Porta/origem diferente ou navegador diferente | Usar sempre `localhost:8080` no mesmo navegador |
| Aviso de Android | Toolchain ausente | Aceitar como opcional; não instalar sem autorização |
| Aviso de Visual Studio | Toolchain desktop ausente | Aceitar; Web não depende disso |
| Build lento | Primeiro build/antivírus | Repetir e medir; não desativar segurança global |
| Erro de caminho longo | Limite do Windows | O caminho curto escolhido reduz o risco; não usar caminhos profundos |
| `flutter doctor` sugere `flutter upgrade` | Atualização disponível | Não atualizar no meio de uma fase sem autorização e registro |
| Aba automatizada do navegador não pinta o app | Janela do desktop não visível; `requestAnimationFrame` não dispara | Validar com Chrome headless + CDP ou com a janela visível |
| Rota profunda devolve 404 em servidor estático | Servidor sem fallback de SPA | Configurar rewrite para `index.html` na hospedagem (Fase 5) |

## 10. Atualizações e manutenção

- Canal: **stable**.
- Não atualizar o SDK no meio de uma fase sem autorização; uma atualização pode exigir ajustes de dependências.
- Antes de atualizar: registrar versão atual, garantir que os testes passam e que há backup dos dados de teste.
- Depois de atualizar: executar `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build web --release`; atualizar este documento e `docs/PROGRESSO.md`.
- Não usar `flutter channel master` ou versões beta no MVP.
- Não executar `flutter clean` como primeira tentativa de resolver problemas; entender a causa e preservar dados.

## 11. O que não fazer

- Não instalar Android SDK, JDK ou Android Studio nesta fase.
- Não usar `C:\Program Files` nem exigir administrador para o SDK.
- Não baixar Flutter de sites não oficiais.
- Não ignorar falha de checksum.
- Não commitar `.dart_tool/`, `build/`, bancos locais, backups ou arquivos com dados reais.
- Não publicar, fazer deploy ou enviar mensagens reais sem autorização.
- Não alterar o `README.md` removido, `.vs/` ou `EstudoEntityFramework/` na raiz do repositório.

## 12. Serviço Dart (Fase 6)

O pacote compartilhado `packages/draw_engine` é Dart puro, sem dependência Flutter. `server/` é um pacote Dart separado e usa `crypto` para armazenar hashes de tokens bearer e `test` para a suíte. Configure com `dart pub get` a partir de `server/` e execute com `dart test`. Firebase Authentication/Firestore Emulator e Cloud Run ainda não foram adicionados à configuração local; serão registrados quando essa integração for implementada. Não é necessário criar projeto Google/Firebase nesta etapa.
