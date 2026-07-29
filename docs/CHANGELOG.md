# Changelog

Formato: data, o que mudou, impacto. Para o "porquê" narrativo completo
de cada entrada, ver `PROJECT_STATUS.md`. Entradas anteriores a
2026-07-27 são resumidas a partir do histórico de commits e de
`PROJECT_STATUS.md` — não presenciadas por quem escreveu este arquivo.

## 2026-07-28 (continuação 2) — Bug crítico: sessão iniciada perdia a
dose real do plano

Achado testando ao vivo no aparelho: a tela de execução "não estava
conforme a imagem de exemplo" — exercícios mostravam sempre placeholder
(nunca a foto real), "REPETIÇÕES: 0" mesmo em exercícios por tempo,
sempre "1/1" série. Investigado com `flutter analyze`/leitura de código
(não emulável em modo debug neste ambiente — Gradle trava, mesma
limitação já documentada), a causa raiz: `TrainingPlanScreen._startSession`
reconstruía `WorkoutSessionItem` a partir do `PlannedExerciseItem` do
plano copiando só 4 campos (`pattern`/`exerciseSlug`/`namePtBr`/
`setsRepsGuidance`) — `doseType`, `targetSets`, `targetReps`,
`targetSeconds`, `restSeconds` e `mediaSlug` caíam nos valores padrão
(`reps`/1 série/60s/sem imagem), descartando a dose e a imagem reais do
plano gerado. Bug **pré-existente**, não desta sessão — nenhum teste
automatizado exercitava esse caminho real (os testes de
`workout_player_screen_test.dart`/`timed_set_player_flow_test.dart`
constroem `WorkoutSessionItem` diretamente, sem passar por
`_startSession`), então nunca foi pego antes.

- Corrigido: `_startSession` agora repassa todos os campos do
  `PlannedExerciseItem`.
- Teste de regressão novo: inicia uma sessão de verdade a partir do
  plano (não construindo o item à mão) e confere que `doseType`/
  `targetSeconds`/`targetSets`/`mediaSlug` sobrevivem.
- Verificado ao vivo no aparelho: sessão nova mostra "TEMPO" (não
  "REPETIÇÕES") para o aquecimento, alvo de 240s correto, descanso 60s
  correto, status sincronizado em tempo real (Aguardando → Em
  execução). O aquecimento continua sem foto real por não ter
  `mediaSlug` associado (`warmup_joint_mobility`, decisão antiga
  documentada) — não é bug, os demais exercícios do plano (Flexão
  tradicional, Agachamento livre, Prancha completa etc.) já mostravam
  foto real na lista da semana, confirmando que o vínculo de mídia
  continua correto.
- 222 testes automatizados (eram 221); `flutter analyze`/`dart format`
  sem problemas.

## 2026-07-28 (continuação) — Bug real achado no aparelho + 3 itens de
Definição

Depois de instalar a entrega anterior no aparelho físico, o usuário
reportou e pediu três coisas na mesma sessão:

- **Bug real corrigido, pré-existente** (não introduzido pela sessão
  anterior): `ExerciseDetailScreen` ("Como executar", Descobrir →
  exercício) travava o layout inteiro — `_DetailRow` usava `Flexible`
  dentro de `ListTile.trailing`, uso inválido (`ListTile` não é um
  `Flex`), gerando "Incorrect use of ParentDataWidget" e cascata de
  colunas de uma letra por linha. Corrigido trocando por `Row`+`Expanded`
  de verdade. Achado com um teste de regressão reproduzindo a tela
  (`test/features/discover/discover_screen_test.dart`), não só olhando
  o print do erro.
- **Zoom em tela cheia na imagem do exercício** (Descobrir → "Como
  executar"): trocado o `ExerciseMedia` de tamanho fixo (240px) pelo
  `ExerciseImageCard`/`ExerciseFullscreenViewer` já construídos na
  entrega anterior — mesmo componente, reaproveitado, sem código novo.
- **Definição > "X dias por semana" agora é clicável**: abre o mesmo
  diálogo de "Dias de treino na semana" (a quantidade sempre foi
  derivada de quantos dias são escolhidos ali — não criei um segundo
  editor de quantidade que pudesse divergir).
- **Definição > "Refazer avaliação física" reativado**: estava
  `enabled: false` com uma nota de "futura reavaliação dedicada". Agora
  abre uma folha com as duas colocações já existentes no app
  (`AssessmentSkipTestScreen` para empurrar horizontal,
  `OtherPatternsAssessmentScreen` para os outros 4 padrões) —
  reaproveitadas de `PlacementResultScreen`/`EvolutionScreen`, nenhuma
  tela nova. As duas passaram a devolver `pop(true)` quando salvam de
  verdade, para o lembrete de "gerar novamente o plano" só aparecer
  quando algo foi mesmo salvo (não ao simplesmente voltar).
- 220 testes automatizados (eram 214), todos passando; `flutter
  analyze`/`dart format` sem problemas; instalado e verificado sem
  crash no aparelho físico (`7549GMFUDA4DKZW8`) duas vezes nesta
  continuação.

## 2026-07-28 — Nova tela "Treino em andamento" + 195 imagens relinkadas

Fora do fluxo normal de continuidade: entre a sessão anterior e esta, as
195 imagens de `assets/images/exercises/` foram apagadas do disco (fora
do git) e substituídas por 195 arquivos novos, maiores e com muito mais
conteúdo visual (nome, categoria, nível, mapa muscular, instruções já
desenhados na própria arte), soltos e renomeados como `Nivel N -
Nome.png` em `assets/images/exercicios/` — sem estrutura de pastas, sem
vínculo com o catálogo. Isso quebrava o bundle de assets do app
(`pubspec.yaml` referenciava pastas que não existiam mais). Duas
entregas nesta sessão, pedidas juntas pelo usuário:

- **Vínculo das 195 imagens**: novo `tool/link_exercise_media.dart`
  (rodar com `dart run tool/link_exercise_media.dart`) casa cada arquivo
  por **nome normalizado** (nunca pelo número em "Nivel N", que é uma
  numeração global 1-23 do pacote de entrega, diferente da escala 0-7
  por padrão que o catálogo usa) contra `exercise_media_catalog.json` —
  174/195 batem exatamente; os outros 21 (typo/abreviação no nome do
  arquivo) resolvidos por uma tabela fixa de exceções, cada uma conferida
  manualmente contra a única entrada órfã do catálogo, comentada linha a
  linha no script. Copia cada arquivo pro `asset_path` que o catálogo já
  declarava (`assets/images/exercises/<categoria>/<slug>.png`) — nenhuma
  mudança em `pubspec.yaml`/`MediaCatalogIndex`/`ExerciseMedia`, porque
  os caminhos já eram esses. As 195 bateram sem erro; a pasta original
  `assets/images/exercicios/` foi apagada depois da validação (a pedido
  do usuário). **Aviso real**: as imagens novas são ~9× maiores (1024×1536,
  ~1,7 MB cada) — o bundle de assets cresceu de dezenas de MB para
  ~327 MB; o APK release final ficou em 387,7 MB. Ver
  `docs/IMPLEMENTATION_BACKLOG.md`.
- **Tela "Treino em andamento" redesenhada** (tema escuro, verde-neon,
  seguindo `assets/exemplo-molde.png`): `WorkoutPlayerScreen` foi
  quebrada em componentes novos (`ExerciseExecutionHeader`,
  `ExerciseImageCard`/`ExerciseFullscreenViewer` com zoom via
  `InteractiveViewer`+`Hero`, `ExerciseSetMetricsCard`,
  `RestTimerPanel`, `ExercisePrimaryActionButton`,
  `ExerciseBottomNavigation`) reaproveitando toda a arquitetura existente
  (Riverpod, `ActiveTimer` monotônico, `TimedSetPlayer`, XP/idempotência)
  — nenhuma tela paralela. **Funcionalidade nova real**: descanso
  **entre séries do mesmo exercício** (`RestTimerPanel`), que não existia
  antes (só havia descanso entre exercícios, via `RestScreen`, mantido
  sem mudança). "Próximo"/"Finalizar treino" agora fica desabilitado até
  todas as séries do exercício atual serem registradas (antes era
  possível avançar a qualquer momento); "Pular série" (com confirmação) e
  "Anterior" (não apaga histórico) são novos. Botão "Abandonar sessão"
  preservado como ícone no cabeçalho (não estava no protótipo estático,
  mas removê-lo seria uma regressão de funcionalidade já existente). Ver
  `docs/PROJECT_STATUS.md` §"Nova tela de execução + 195 imagens
  relinkadas".
- 8 testes novos/reescritos em `workout_player_screen_test.dart` (rolagem
  necessária nos testes por causa da imagem grande — anotado como
  armadilha em `ARCHITECTURE.md`), 3 novos em `exercise_image_card_test.dart`.
  214 testes automatizados (eram 206), todos passando; `flutter analyze`
  sem problemas; `flutter build apk --release` OK. **Não instalado no
  aparelho físico nesta sessão** (nenhum dispositivo conectado ao
  ambiente) — pendente verificação manual.

## 2026-07-27 — Objetivo de treino, abas do plano, limpeza da mídia
(commit `753d58c`)

Quarto item da mesma sessão de continuidade, depois de peso/altura/IMC
e favoritos. Começou como uma reverificação da integração das 195
imagens (pedido repetido do usuário) e virou quatro entregas:

- **Auditoria da integração das 195 imagens**: já estava completa de
  uma sessão anterior (commit `5b9a84a`); corrigido `README.md` da
  raiz (tinha sido sobrescrito pelo README de um pacote de entrega) e
  removidos 7 arquivos de manifesto/checksum duplicados soltos na
  raiz do repositório (nunca chegaram a ser commitados).
- **Ilustração animada removida**: `PatternIllustration` (bonequinho
  de traços animado, usado como fallback quando não há foto real)
  deletado a pedido do usuário; `ExerciseMediaPlaceholder` agora mostra
  um ícone estático (`Icons.fitness_center`).
- **Plano da semana em duas abas**: "Próximo treino" (só a sessão
  pendente mais próxima, mesma resolução de `nextPendingSession` usada
  no card da Jornada) e "Semana completa" (comportamento antigo,
  todos os dias). Antes, `TrainingPlanScreen` sempre mostrava a semana
  inteira de uma vez.
- **Objetivo de treino** (força muscular/perder gordura/
  condicionamento, um único por vez): novo enum `TrainingObjective` em
  `TrainingPreferences` + coluna aditiva `objective`
  (`training_preference_records`, migração 9→10) + item em Definição >
  Perfil e avaliação. Muda a dose prescrita em
  `WeeklyPlanGenerator._doseFor` (`restSeconds`/`targetSets`;
  `weeklyPlanGeneratorRuleVersion` → `weekly-plan-v2`); aquecimento
  nunca é modificado.
- **2 bugs pré-existentes corrigidos** (achados testando o item
  acima): `_editWeekdays` (Definição) zerava a altura salva ao não
  repassar `heightCm`; `TrainingPreferencesRepository.latest()` não
  desempatava gravações com o mesmo `updatedAt` (sequência rápida de
  edições), agora desempata por `id DESC`.
- Instalado e verificado sem crash no aparelho físico
  (`7549GMFUDA4DKZW8`) via `flutter build apk --release` + `adb
  install -r` — só checagem de abertura, sem navegação manual pelas
  telas novas ainda.
- 206 testes automatizados (eram 197), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Favoritos (Descobrir)

Segundo item escolhido pelo usuário do topo do backlog, logo após
peso/altura/IMC.

- **Banco (schemaVersion 8→9, aditiva):** tabela nova `favorite_records`
  (`itemType` — `workout`/`exercise` —, `itemSlug`, `createdAt`, chave
  única `(itemType, itemSlug)` para evitar duplicata). Testado em
  `test/core/database/migration_v9_test.dart` com um banco montado no
  formato real da v8.
- **Domínio** (`lib/features/discover/domain/favorite.dart`):
  `FavoriteItemType` (workout/exercise) e `favoriteKey` (chave composta
  para checar pertencimento em `Set<String>` sem consulta por item).
- **Repositório** (`FavoriteRepository.toggle`/`allKeys`): sem tabela
  separada por tipo — `workout` e `exercise` com o mesmo slug não
  colidem porque a chave é composta.
- **Descobrir:** botão de estrela (`_FavoriteButton`) em todo card de
  treino/exercício, inclusive na seção "Recentes" (reaproveita
  `_ExerciseCard`); chip "Favoritos" deixou de ficar desabilitado e
  agora filtra a lista de verdade.
- É preferência pessoal, não progresso — `ProgressResetService`
  deliberadamente não toca em `favorite_records`.
- 194 testes automatizados (eram 189), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Peso, altura e IMC

Implementa o item do topo do backlog (`IMPLEMENTATION_BACKLOG.md`, P2):
o card "Peso, altura e IMC — ainda não disponível nesta versão" do
Relatório vira funcionalidade real.

- **Banco (schemaVersion 7→8, aditivo):** coluna nova `heightCm`
  (nullable) em `training_preference_records` — altura é perfil,
  sobrevive ao reset. Tabela nova `body_metric_records` (peso + data,
  editável/excluível, ao contrário dos ledgers append-only do projeto)
  — histórico de progresso, apagado pelo "Reiniciar progresso e
  métricas". Testado em `test/core/database/migration_v8_test.dart` com
  um banco montado no formato real da v7.
- **Domínio** (`lib/features/report/domain/body_metric.dart`): validação
  de faixa plausível (peso 20–300 kg, altura 100–250 cm) e cálculo de
  IMC/categoria — indicador geral, sem diagnóstico médico (texto
  explícito na UI).
- **Definição > Perfil e avaliação:** "Altura" editável (diálogo com
  validação) e "Peso e IMC" abrindo a tela de histórico.
- **Nova tela `BodyMetricScreen`** (`lib/features/report/presentation/`):
  resumo (atual/maior/menor/tendência + IMC), lista de pesagens com
  editar/excluir (excluir pede confirmação), botão flutuante para
  adicionar.
- **Relatório:** card "Peso, altura e IMC" agora mostra peso atual + IMC
  reais quando há registro, ou estado vazio com atalho "Registrar peso"
  quando não há.
- `ProgressResetService` passa a apagar `body_metric_records`; altura
  (preferência) continua preservada.
- 189 testes automatizados (eram 169), todos passando; `flutter
  analyze` sem problemas.

## 2026-07-27 — Continuação: quatro abas completas, correções de bugs reais

Sessão de continuidade a partir de `docs/HANDOFF_CLAUDE.md` (versão
anterior), implementando o que o handoff listava como pendente.

**Correções de bugs reais (não features):**
- `SettingsRepository.save()`: fallback de escrita direta se o
  `rename` do arquivo temporário falhar (defensivo; o comportamento
  padrão foi verificado seguro neste ambiente Windows).
- `test/app/main_shell_test.dart` travava indefinidamente —
  `NativeDatabase`/`Directory.systemTemp.createTemp()` rodavam fora de
  `tester.runAsync()` dentro da zona `FakeAsync` de `testWidgets`.
  Corrigido; mesma causa documentada em `ARCHITECTURE.md` para não ser
  redescoberta.
- `XpEvolutionChart`: `RenderFlex` estourava sempre que havia XP real no
  período (a barra reservava `chartHeight + 28` de altura, insuficiente
  para texto do valor + barra + rótulo do dia). Corrigido para
  `chartHeight + 44`. Nunca tinha sido exercitado com dados não-zero em
  teste automatizado antes desta sessão.
- `test/core/database/migration_v6_test.dart`: não criava
  `training_preference_records` no banco legado simulado, quebrando
  quando a migração v7 (nova nesta sessão) tentou alterar essa tabela.
  Corrigido criando a tabela legada no teste.

**Aba Treino (Jornada) reordenada** conforme
`APP_RPG_CALISTENIA_REDESENHO_NAVEGACAO_E_IMPLEMENTACAO.md` §4.1: nível/
XP → sessão pausada (novo card, com exercício/série atuais, progresso e
horário do último salvamento, tudo derivado de dados reais) → próximo
treino → frequência semanal (agora mostra a meta de dias formalizada) →
próxima habilidade → missões → sequência atual (novo, streak real
derivado de `workout_session_records`) → evolução de XP → botão do
plano completo. Removido o card "Treino em destaque", redundante com a
aba Descobrir.

**Aba Descobrir**: filtros reais de nível, duração (faixas), padrão de
movimento e equipamento completo (antes só um toggle "sem
equipamento"); seção "Recentes" com exercícios de sessões concluídas de
verdade; chip "Favoritos" explicitamente desabilitado.

**Aba Relatório**: `XpLevelBadge`, aderência ao plano (sessões reais vs.
meta semanal), evolução de XP (reaproveitando o componente da Jornada),
recordes pessoais, volume por padrão de movimento, XP por sessão no
histórico, card explícito "Peso/altura/IMC ainda não disponível".

**Aba Definição**:
- Nova coluna `preferredWeekdaysJson` em `training_preference_records`
  (migração aditiva v6→v7) — usuário escolhe dias específicos da semana
  como meta de treino; `daysPerWeek` passa a acompanhar a quantidade
  escolhida.
- "Contagem regressiva" virou editável (diálogo com slider 0–10s) e foi
  **conectada de verdade** ao `TimedSetPlayer` (antes era só um número
  estático que nunca influenciava o cronômetro).
- Novo tile "Uso de armazenamento", somando o tamanho real do banco
  Drift + JSON de preferências.

**Ícone do app**: `pubspec.yaml` (`flutter_launcher_icons`) passou a
usar `assets/images/icone.png`; ícones Android/iOS regenerados.

**Validação visual/responsiva**: `test/app/responsive_visual_test.dart`
novo — 5 cenários (celular pequeno em 1.0×/1.4×/2.0× de escala de
fonte, tablet grande, alto contraste), navegando pelas quatro abas e
rolando, sem overflow em nenhum. Screenshot manual não foi possível
neste ambiente (sem Web/Windows desktop configurados, sem toolchain
MSVC nem ferramenta de automação de browser) — decisão registrada com o
usuário de manter só a validação automatizada.

**Testes:** 91 → 169 testes automatizados (todos passando),
`flutter analyze` sem problemas em cada etapa.

## Antes de 2026-07-27 — redesenho de navegação em quatro abas

Implementação anterior (fora desta sessão de continuidade, herdada via
commit `4e974a3` e handoff): shell raiz com `IndexedStack` de quatro
abas (Treino/Descobrir/Relatório/Definição) substituindo a `JourneyScreen`
como tela única; tema central recebeu tokens para a barra de navegação,
alto contraste e escala de texto; abas Descobrir/Relatório/Definição
criadas pela primeira vez; serviço de reinício de progresso
(`ProgressResetService`) implementado com fluxo de confirmação em três
etapas. Detalhe completo (arquivos, decisões, o que ficou incompleto) em
`docs/HANDOFF_CLAUDE.md` (histórico, antes de ser reescrito por esta
sessão) e `docs/PROJECT_STATUS.md`.

## 2026-07-26 e anteriores

Ver `docs/PROJECT_STATUS.md` para o histórico completo pré-redesenho:
motor de treino determinístico, player de sessão offline (repetições e
duração), progressão/domínio, RPG/XP, missões diárias/semanais, tela
"Evolução", integração do catálogo de 195 imagens de exercício,
catálogo em camadas para 5 padrões de movimento, tema escuro/"game".
