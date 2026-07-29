# Prompt de continuidade para Claude Code

Você está continuando a implementação do projeto Flutter **App RPG
Calistenia**. Leia primeiro `docs/PROJECT_STATUS.md` (histórico
narrativo completo, seções mais recentes no final) e
`docs/IMPLEMENTATION_BACKLOG.md` (lista priorizada do que falta, sem
prosa). Depois, se for mexer nas telas de quatro abas ou na tela de
execução, também `APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md`,
`docs/ARCHITECTURE.md` e `docs/UI_UX.md`.

Este handoff substitui a versão anterior.

**Estado do Git:** o trabalho desta sessão **não foi commitado ainda**
— rode `git status --short` antes de qualquer coisa. Além dos arquivos
novos/alterados de código e documentação, há 195 imagens modificadas em
`assets/images/exercises/` (conteúdo novo, mesmos caminhos de sempre) e
a remoção de `assets/images/exercicios/` (pasta de staging, nunca
chegou a ser commitada). Confira `git status --short` mesmo assim —
não presuma que a árvore está limpa nem que o próximo usuário vai
commitar sozinho (foi exatamente por não presumir isso que o achado
crítico desta sessão foi pego a tempo, ver abaixo).

## O que aconteceu nesta sessão (2026-07-28)

### 1. Achado crítico antes de qualquer código: imagens apagadas fora do git

Ao rodar `git status` no início da sessão, encontrei 195 deleções:
`assets/images/exercises/` (estrutura por categoria que `pubspec.yaml`/
`MediaCatalogIndex` esperavam) tinha sumido do disco entre a sessão
anterior e esta, fora do git. No lugar, uma pasta nova sem
versionamento (`assets/images/exercicios/`, 327 MB) continha 195
arquivos maiores e mais detalhados, renomeados `Nivel N - Nome.png`.
Isso quebrava o bundle de assets (`flutter build bundle` falhava).
Avisei o usuário antes de tocar em qualquer arquivo; a resposta foi
"farei isso depois" — segui para o próximo item do backlog sem mexer
nas imagens, até o usuário voltar na mesma sessão com o pedido descrito
abaixo, que incluía resolver esse vínculo explicitamente.

### 2. Vínculo das 195 imagens

Novo `tool/link_exercise_media.dart` (rodar com `dart run
tool/link_exercise_media.dart` sempre que o pacote de imagens for
substituído de novo): casa cada arquivo por **nome normalizado** (nunca
pelo número em "Nivel N", que é uma numeração global 1-23 do pacote de
entrega, diferente da escala 0-7 por categoria do campo `level` do
catálogo) contra `assets/data/exercise_media_catalog.json` — 174/195
exatos, 21 por uma tabela fixa de exceções (typo/abreviação, cada uma
conferida manualmente e comentada no script). Copia pro `asset_path`
que o catálogo já declarava — **zero mudança em `pubspec.yaml`/
`MediaCatalogIndex`/`ExerciseMedia`**, porque os caminhos já eram esses.
Depois de validar as 195 sem erro, apagou `assets/images/exercicios/`
(confirmado com o usuário antes). Ver `docs/PROJECT_STATUS.md` §"Nova
tela de execução + 195 imagens relinkadas" pro racional completo
(inclusive por que não criei um manifesto paralelo, como o pedido
original sugeria).

**Aviso real, não resolvido**: as imagens novas são ~9× maiores
(1024×1536px, ~1,7 MB cada) — o bundle de assets cresceu pra ~327 MB, o
APK release final ficou em 387,7 MB. Decisão pendente (aceitar,
comprimir, converter pra WebP) registrada em
`docs/IMPLEMENTATION_BACKLOG.md` — não é decisão que tomei sozinho.

### 3. Tela "Treino em andamento" redesenhada

`WorkoutPlayerScreen` reestilizada (tema escuro/verde-neon, seguindo
`assets/exemplo-molde.png`) e quebrada em componentes novos —
reaproveitando toda a arquitetura existente (Riverpod, `ActiveTimer`
monotônico, `TimedSetPlayer`, XP/idempotência), sem tela paralela:
`ExerciseExecutionHeader`, `ExerciseImageCard`/`ExerciseFullscreenViewer`
(zoom com `InteractiveViewer`+`Hero`, em `lib/shared/presentation/`),
`ExerciseSetMetricsCard`, `RestTimerPanel`, `ExercisePrimaryActionButton`,
`ExerciseBottomNavigation`. Ver `docs/ARCHITECTURE.md` pros nomes reais
e onde cada um vive.

**Mudanças de comportamento**, não só visuais:

- **Descanso entre séries do mesmo exercício** é funcionalidade nova
  (`RestTimerPanel`) — antes só existia descanso entre exercícios
  diferentes (`RestScreen`, preservado sem mudança).
- "Próximo"/"Finalizar treino" agora fica desabilitado até todas as
  séries do exercício atual estarem registradas (antes dava pra avançar
  a qualquer momento).
- "Anterior" (novo) e "Pular série" (novo, com confirmação) na
  navegação inferior.
- Botão "Abandonar sessão" preservado como ícone no cabeçalho (não
  estava na imagem de exemplo, mas removê-lo seria regressão de
  funcionalidade já existente).

## Arquivos principais criados/modificados nesta sessão

- `tool/link_exercise_media.dart` (novo).
- `lib/shared/presentation/exercise_media.dart` (`resolveExerciseAssetPath()`
  extraído), `exercise_image_card.dart` (novo),
  `exercise_fullscreen_viewer.dart` (novo).
- `lib/features/workout_session/presentation/`: `workout_player_screen.dart`
  (reestruturado), `timed_set_player.dart` (visual + `onStatusChanged` +
  `onFinalized` agora passa `TimedSetCompletionReason`),
  `exercise_execution_header.dart`, `exercise_set_metrics_card.dart`,
  `rest_timer_panel.dart`, `exercise_primary_action_button.dart`,
  `exercise_bottom_navigation.dart` (todos novos).
- Testes novos/reescritos: `test/features/workout_session/
  workout_player_screen_test.dart` (8 casos),
  `test/shared/presentation/exercise_image_card_test.dart` (3 casos,
  novo). `timed_set_player_flow_test.dart` ajustado (rolagem antes de
  interagir — ver armadilha abaixo).
- Documentação: `docs/CHANGELOG.md`, `docs/PROJECT_STATUS.md`,
  `docs/IMPLEMENTATION_BACKLOG.md`, `docs/ARCHITECTURE.md`,
  `docs/UI_UX.md` (todos atualizados), este `HANDOFF_CLAUDE.md`.
- `assets/images/exercises/**` (195 arquivos com conteúdo novo, mesmos
  caminhos), `assets/images/exercicios/` (apagada).

## Validações executadas

- `flutter analyze`: sem problemas.
- `dart format --set-exit-if-changed .`: sem mudanças pendentes.
- `flutter test`: **214 passed, 0 failed** (eram 206 no início desta
  sessão).
- `dart run build_runner build`: OK, sem alteração de schema (nenhuma
  migração Drift nesta sessão).
- `flutter build apk --release`: OK, 387,7 MB.
- **Não instalado no aparelho físico** — nenhum dispositivo conectado
  ao ambiente (`adb devices` vazio). Verificação manual real da tela
  nova (zoom por gesto, descanso entre séries, fotos novas em tamanho
  real) fica pendente — ver `IMPLEMENTATION_BACKLOG.md` P0.

## Armadilha de teste nova (documentada em `ARCHITECTURE.md`)

A tela de execução usa uma `ListView` com cabeçalho + imagem grande
(~60% do viewport) antes dos controles. Em tamanho de tela de teste
padrão, isso empurra o card de métricas/timer/botões para fora do
alcance de pré-construção da sliver list (`cacheExtent`) — `find.text`/
`tap` não encontram esses widgets sem antes rolar:
`await tester.drag(find.byType(ListView), const Offset(0, -600)); await
tester.pumpAndSettle();`. Isso é comportamento normal de lista
preguiçosa (não é bug), só precisa ser considerado em qualquer teste
novo desta tela. Ver os testes atualizados para o padrão exato.

## Decisões arquiteturais tomadas

- **Catálogo de mídia existente continua sendo a única fonte de
  verdade** — não criei um manifesto JSON/Dart paralelo para o vínculo
  das imagens, mesmo o pedido original sugerindo isso. Reaproveitar
  `exercise_media_catalog.json`/`MediaCatalogIndex` (já testados, já
  usados em produção) é consistente com o princípio geral do projeto de
  não duplicar fonte de verdade.
- **Vínculo de imagem por nome normalizado, nunca pelo número "Nivel
  N"** — esse número é uma numeração global do pacote de entrega,
  diferente da escala por categoria que o catálogo usa para `level`.
  Qualquer pacote de imagens futuro que repita esse padrão de nome deve
  seguir a mesma regra.
- **Descanso entre séries não acontece após uma série finalizada por
  dor** — o usuário já está saindo do exercício nesse caso (mesma
  semântica que o diálogo de dor já prometia: "vamos seguir para o
  próximo exercício"), não faz sentido descansar pra continuar nele.
- **Texto do pedido prevalece sobre a imagem de exemplo estática**
  quando os dois se contradizem — a imagem mostra "CONCLUÍDO" com o
  timer ainda rodando, mas o texto do pedido pede explicitamente para
  nunca usar esse rótulo antes da ação acontecer de verdade. Segui o
  texto.
- **`TimedSetPlayer` continua sendo o dono da máquina de estados da
  série por tempo** — a tela de execução não duplica essa lógica, só
  reporta um status coarse pra fora via `onStatusChanged` (novo
  callback) para o card de métricas conseguir mostrar "Pausado"
  corretamente.

## Lacunas reais restantes

1. **Verificação manual no aparelho da tela nova** — maior prioridade
   imediata, só falta um dispositivo conectado. Ver checklist acima.
2. **Tamanho do bundle de imagens (~327 MB / APK 387,7 MB)** — decisão
   de produto pendente (aceitar/comprimir/WebP), não tomada nesta
   sessão.
3. **Catálogo de treinos maior** — continua o item de maior efeito
   cascata do backlog, ainda não escolhido pelo usuário.
4. **Nova curva de XP progressiva a 5%/nível** — ainda pendente de
   esclarecimento do usuário sobre o arredondamento (ver
   `IMPLEMENTATION_BACKLOG.md` P1, não mudou nesta sessão).
5. Lacunas anteriores continuam registradas em
   `docs/IMPLEMENTATION_BACKLOG.md` (teste físico periódico, campanha/
   atributos RPG, missões incompletas, progressão sem regressão/platô/
   deload, etc.) — não foram tocadas nesta sessão.

## Sequência recomendada para continuar

1. `git status --short` (não presuma limpo), ler `docs/PROJECT_STATUS.md`
   (seções finais) e `docs/IMPLEMENTATION_BACKLOG.md`.
2. Se possível, conectar um aparelho físico e fazer a verificação manual
   pendente da tela nova antes de qualquer coisa (item 1 das lacunas).
3. Escolher o próximo item com o usuário — tamanho do bundle de imagens
   e catálogo de treinos maior são os de maior alavancagem em aberto.
4. Implementar em etapas pequenas e testáveis: domínio puro →
   repositório/provider → tela → teste de cada camada → `flutter
   analyze` + `flutter test` completos antes de seguir para a próxima
   etapa.
5. Atualizar `docs/CHANGELOG.md` (nova entrada datada),
   `docs/PROJECT_STATUS.md` (seção narrativa) e este
   `HANDOFF_CLAUDE.md` ao final.

Preserve o tema escuro, verde-menta como ação principal, roxo só para
XP, e todas as funcionalidades já existentes (Jornada, missões, plano
em duas abas, sessão pausada, progressão, peso/altura/IMC, favoritos,
objetivo de treino, a tela de execução redesenhada desta sessão).
